import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../services/chat_service.dart';
import '../../../../providers/chat_provider.dart';
import '_ChatMessage.dart';
import '_ChatInput.dart';
import '_TranslationBanner.dart';
import '../../../../services/ride_api/booking_api_service.dart';
import '../../../../core/config/app_config.dart';
import '../../../../services/driver_profile_cache.dart';
import '../../../../widgets/driver_avatar.dart';

class ChatPage extends StatefulWidget {
  final String rideId;
  final String? driverName;
  final String? driverId;
  final String? vehicleName;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleColor;
  final String? plateNumber;
  final String? driverPhotoUrl;

  const ChatPage({
    super.key,
    required this.rideId,
    this.driverName,
    this.driverId,
    this.vehicleName,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleColor,
    this.plateNumber,
    this.driverPhotoUrl,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _input = TextEditingController();
  bool _autoTranslate = true;
  final ChatService _chatService = ChatService();
  String? _currentUserId;
  String? _driverPhotoUrl; // resolved photo URL
  String? _vehicleLabel; // formatted vehicle label

  static final Set<String> _hydratedOnce = <String>{};
  bool _hydrating = false;
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    // Resolve photo synchronously from widget args OR cache so first frame is correct.
    final fromArgs = widget.driverPhotoUrl;
    final fromCache = DriverProfileCache.instance.getLogoUrl(
      widget.driverId ?? '',
    );
    final chosen = (fromArgs != null && fromArgs.isNotEmpty)
        ? fromArgs
        : (fromCache ?? '');
    _driverPhotoUrl = chosen.isNotEmpty ? _absoluteUrl(chosen) : '';
    _vehicleLabel = _formatVehicleLabel(
      widget.vehicleName,
      make: widget.vehicleMake,
      model: widget.vehicleModel,
    );
    if (_hydratedOnce.contains(widget.rideId)) {
      _hydrated = true;
    } else {
      _startHydrationGate();
    }
    _initChat();
    // Only hit the API if we still have nothing (silent background refresh).
    if (_driverPhotoUrl == null || _driverPhotoUrl!.isEmpty) {
      _ensureDriverPhoto();
    }
    _ensureVehicleLabel();
  }

  String _absoluteUrl(String raw) {
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    final base = AppConfig.wsBaseUrl; // without /api
    if (raw.startsWith('/')) return '$base$raw';
    return '$base/$raw';
  }

  Future<void> _initChat() async {
    debugPrint(
      '🔵 [PassengerChat] Initializing chat with rideId: ${widget.rideId}',
    );

    // Capture provider before any await (BuildContext rule)
    final chatProvider = context.read<ChatProvider>();

    // Get current user ID from token storage
    _currentUserId = await TokenStorage.getUserId();
    debugPrint('🔵 [PassengerChat] User ID: $_currentUserId');

    // Wire socket callbacks
    _chatService.onMessage = _onNewMessage;
    _chatService.onEdited = _onMessageEdited;
    _chatService.onDeleted = _onMessageDeleted;

    // Connect WebSocket
    try {
      await _chatService.connect(widget.rideId);
      debugPrint('✅ [PassengerChat] WebSocket connected');
    } catch (e) {
      debugPrint('❌ [PassengerChat] WebSocket connection failed: $e');
    }

    // Load history from provider (uses cache if available)
    final locale = Localizations.localeOf(context).languageCode;
    await chatProvider.fetchMessages(
      widget.rideId,
      currentUserId: _currentUserId,
      translate: _autoTranslate,
      targetLang: locale,
    );

    if (mounted) {
      _scrollToBottom();
    }
  }

  void _startHydrationGate() {
    _hydrating = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Future<void> precacheTask = Future.value();
      final url = _driverPhotoUrl;
      if (url != null && url.isNotEmpty) {
        try {
          final provider = CachedNetworkImageProvider(url);
          await precacheImage(
            provider,
            context,
          ).timeout(const Duration(seconds: 2), onTimeout: () {});
        } catch (_) {}
      }
      await Future.any([
        precacheTask,
        Future.delayed(const Duration(milliseconds: 1300)),
      ]);
      if (!mounted) return;
      setState(() {
        _hydrated = true;
        _hydrating = false;
        _hydratedOnce.add(widget.rideId);
      });
    });
  }

  Future<void> _ensureVehicleLabel() async {
    try {
      final api = BookingApiService();
      final details = await api.getRideDetails(widget.rideId);
      if (details == null || !mounted) return;
      final make =
          (details['vehicleMake'] as String?) ??
          (details['vehicle_make'] as String?);
      final model =
          (details['vehicleModel'] as String?) ??
          (details['vehicle_model'] as String?);
      final improved = _formatVehicleLabel(
        widget.vehicleName,
        make: make,
        model: model,
      );
      if (improved != null &&
          improved.isNotEmpty &&
          improved != _vehicleLabel) {
        setState(() => _vehicleLabel = improved);
      }
    } catch (_) {}
  }

  String? _formatVehicleLabel(
    String? vehicleName, {
    String? make,
    String? model,
  }) {
    String? mke = make?.trim();
    String? mdl = model?.trim();
    if (mke != null && mke.isNotEmpty && mdl != null && mdl.isNotEmpty) {
      return _titleCase(mke) + ' ' + _normalizeModel(mdl);
    }
    if (vehicleName == null || vehicleName.trim().isEmpty) return null;
    return vehicleName.trim();
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s.substring(0, 1).toUpperCase() + s.substring(1).toLowerCase();
  }

  String _normalizeModel(String s) => s.trim();

  Future<void> _ensureDriverPhoto() async {
    // Silent background refresh only.
    // The photo URL is already resolved synchronously in initState from cache/widget.
    // We only call setState if the API returns a *different* URL than what we already show.
    try {
      final api = BookingApiService();
      final details = await api.getRideDetails(widget.rideId);
      if (details == null) return;

      final rootUrl =
          (details['driverLogoUrl'] as String?) ??
          (details['driverPhotoUrl'] as String?) ??
          (details['driver_logo_url'] as String?) ??
          (details['driverPhoto'] as String?);
      String? nestedUrl;
      final drv = details['driver'] as Map<String, dynamic>?;
      if (drv != null) {
        nestedUrl =
            (drv['logoUrl'] as String?) ??
            (drv['logo_url'] as String?) ??
            (drv['photoUrl'] as String?) ??
            (drv['photo'] as String?) ??
            (drv['avatarUrl'] as String?);
      }

      final resolved = rootUrl ?? nestedUrl;
      if (resolved != null && resolved.isNotEmpty) {
        final abs = _absoluteUrl(resolved);
        // Only update if we actually got something new.
        // If the same URL is already showing, calling setState would force
        // CachedNetworkImage to rebuild and potentially re-fade.
        if (abs != _driverPhotoUrl && mounted) {
          setState(() => _driverPhotoUrl = abs);
        }
      }
    } catch (e) {
      // Non-fatal — keep whatever we already have
    }
  }

  ChatMessage _chatMsgToUI(ChatMsg m) {
    final locale = Localizations.localeOf(context).languageCode;
    final bool hasTranslation =
        m.originalText != null && m.originalText!.isNotEmpty;

    if (hasTranslation) {
      return ChatMessage(
        id: m.id,
        text: m.originalText!,
        translatedText: m.text,
        isMe: m.senderId == _currentUserId,
        time: _formatTime(m.createdAt),
        isEdited: m.isEdited,
      );
    }

    if (m.translations != null && m.translations!.containsKey(locale)) {
      return ChatMessage(
        id: m.id,
        text: m.text,
        translatedText: m.translations![locale],
        isMe: m.senderId == _currentUserId,
        time: _formatTime(m.createdAt),
        isEdited: m.isEdited,
      );
    }

    return ChatMessage(
      id: m.id,
      text: m.text,
      isMe: m.senderId == _currentUserId,
      time: _formatTime(m.createdAt),
      isEdited: m.isEdited,
    );
  }

  void _onNewMessage(ChatMsg msg) {
    final chatProvider = context.read<ChatProvider>();
    // Avoid duplicates (we already added optimistic local messages)
    if (chatProvider.getMessages(widget.rideId).any((m) => m.id == msg.id)) {
      return;
    }

    // Remove optimistic placeholder safely if this is our own message
    if (msg.senderId == _currentUserId) {
      final localPlaceholders = chatProvider
          .getMessages(widget.rideId)
          .where((m) => m.id.startsWith('local_') && m.text == msg.text)
          .toList();
      if (localPlaceholders.isNotEmpty) {
        chatProvider.deleteMessage(widget.rideId, localPlaceholders.first.id);
      }
    }

    if (mounted) {
      chatProvider.addMessage(widget.rideId, _chatMsgToUI(msg));
      _scrollToBottom();
    }
  }

  void _onMessageEdited(String messageId, String text) {
    if (!mounted) return;
    final chatProvider = context.read<ChatProvider>();
    chatProvider.updateMessage(widget.rideId, messageId, text);
  }

  void _onMessageDeleted(String messageId) {
    if (!mounted) return;
    final chatProvider = context.read<ChatProvider>();
    chatProvider.deleteMessage(widget.rideId, messageId);
  }

  // ── Delete ──────────────────────────────────────────────
  void _deleteMessage(String id) {
    _chatService.deleteMessage(rideId: widget.rideId, messageId: id);
    final chatProvider = context.read<ChatProvider>();
    chatProvider.deleteMessage(widget.rideId, id);
  }

  // ── Edit ────────────────────────────────────────────────
  void _editMessage(String id, String newText) {
    _chatService.editMessage(
      rideId: widget.rideId,
      messageId: id,
      text: newText,
    );
    final chatProvider = context.read<ChatProvider>();
    chatProvider.updateMessage(widget.rideId, id, newText);
  }

  // ── Send text ───────────────────────────────────────────
  void _sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || widget.rideId.isEmpty || _currentUserId == null) {
      return;
    }

    // 1. Optimistic UI — add message immediately before WebSocket round-trip
    final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMsg = ChatMessage(
      id: localId,
      text: trimmed,
      isMe: true,
      time: _formatTime(DateTime.now()),
      senderId: _currentUserId,
      senderRole: 'passenger',
      createdAt: DateTime.now(),
    );
    context.read<ChatProvider>().addMessage(widget.rideId, optimisticMsg);
    _scrollToBottom();

    // 2. Emit via WebSocket
    _chatService.sendMessage(
      rideId: widget.rideId,
      senderId: _currentUserId!,
      senderRole: 'passenger',
      text: trimmed,
    );

    _input.clear();
  }

  // ── Refetch messages when translation toggle changes ─────────
  Future<void> _refetchMessages() async {
    final chatProvider = context.read<ChatProvider>();
    final locale = Localizations.localeOf(context).languageCode;
    await chatProvider.fetchMessages(
      widget.rideId,
      currentUserId: _currentUserId,
      translate: _autoTranslate,
      targetLang: locale,
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m $period';
  }

  String _formatDateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dt.year, dt.month, dt.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      // Format as "May 6, 2026"
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _input.dispose();
    _chatService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _ChatTopBar(
                  driverName: widget.driverName,
                  vehicleName: _vehicleLabel ?? widget.vehicleName,
                  vehicleColor: widget.vehicleColor,
                  plateNumber: widget.plateNumber,
                  driverPhotoUrl: _driverPhotoUrl ?? widget.driverPhotoUrl,
                  driverId: widget.driverId,
                ),
                TranslationBanner(
                  enabled: _autoTranslate,
                  onToggle: (v) async {
                    setState(() => _autoTranslate = v);
                    await _refetchMessages();
                  },
                ),
                Expanded(
                  child: Consumer<ChatProvider>(
                    builder: (context, chatProvider, child) {
                      final isLoading = chatProvider.isLoading(widget.rideId);
                      final messages = chatProvider.getMessages(widget.rideId);
                      final error = chatProvider.getError(widget.rideId);

                      if (isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (error != null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Error loading messages',
                                style: AppTextStyles.bodyMedium(context),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                error,
                                style: AppTextStyles.bodySmall(
                                  context,
                                ).copyWith(color: AppColors.subtext(context)),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () =>
                                    chatProvider.fetchMessages(widget.rideId),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      if (messages.isEmpty) {
                        return Center(
                          child: Text(
                            'No messages',
                            style: AppTextStyles.bodySmall(
                              context,
                            ).copyWith(color: AppColors.subtext(context)),
                          ),
                        );
                      }

                      final firstDateLabel = messages.first.createdAt != null
                          ? _formatDateLabel(messages.first.createdAt!)
                          : '';

                      return Column(
                        children: [
                          // Date chip right below the banner (always visible)
                          if (firstDateLabel.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface(context),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.border(context),
                                    ),
                                  ),
                                  child: Text(
                                    firstDateLabel,
                                    style: AppTextStyles.bodySmall(context)
                                        .copyWith(
                                          color: AppColors.subtext(context),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: ListView.builder(
                              controller: _scroll,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: messages.length,
                              itemBuilder: (context, i) {
                                final msg = messages[i];

                                // Inline date separators when day changes
                                bool showDateSep = false;
                                String dateLabel = '';
                                if (i > 0) {
                                  final prevMsg = messages[i - 1];
                                  if (msg.createdAt != null &&
                                      prevMsg.createdAt != null) {
                                    final currDate = DateTime(
                                      msg.createdAt!.year,
                                      msg.createdAt!.month,
                                      msg.createdAt!.day,
                                    );
                                    final prevDate = DateTime(
                                      prevMsg.createdAt!.year,
                                      prevMsg.createdAt!.month,
                                      prevMsg.createdAt!.day,
                                    );
                                    if (currDate != prevDate) {
                                      showDateSep = true;
                                      dateLabel = _formatDateLabel(
                                        msg.createdAt!,
                                      );
                                    }
                                  }
                                }

                                return Column(
                                  children: [
                                    if (showDateSep && dateLabel.isNotEmpty)
                                      _DateSeparator(label: dateLabel),
                                    ChatBubble(
                                      message: msg,
                                      showTranslation: _autoTranslate,
                                      onDelete: () => _deleteMessage(msg.id),
                                      onEdit: (newText) =>
                                          _editMessage(msg.id, newText),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                ChatInputBar(controller: _input, onSend: _sendMessage),
              ],
            ),
            if (!_hydrated)
              Positioned.fill(
                child: Container(
                  color: AppColors.bg(context),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Date separator (divider style: line — label — line) ─────────────────────
class _DateSeparator extends StatelessWidget {
  final String label;
  const _DateSeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          // Left line
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.border(context),
            ),
          ),
          const SizedBox(width: 8),
          // Label
          Text(
            label,
            style: AppTextStyles.bodySmall(context).copyWith(
              fontSize: 12,
              color: AppColors.subtext(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          // Right line
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.border(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatTopBar extends StatelessWidget {
  final String? driverName;
  final String? vehicleName;
  final String? vehicleColor;
  final String? plateNumber;
  final String? driverPhotoUrl;
  final String? driverId;

  const _ChatTopBar({
    this.driverName,
    this.vehicleName,
    this.vehicleColor,
    this.plateNumber,
    this.driverPhotoUrl,
    this.driverId,
  });

  String get _vehicleInfo {
    return vehicleName?.isNotEmpty == true ? vehicleName! : 'Vehicle info';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          DriverAvatar(
            name: driverName ?? 'Driver',
            photoUrl: driverPhotoUrl,
            driverId: driverId,
            size: 36,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName ?? 'Driver',
                  style: AppTextStyles.bodyMedium(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  _vehicleInfo,
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(color: AppColors.subtext(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
