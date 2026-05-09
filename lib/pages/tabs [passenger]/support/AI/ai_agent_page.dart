import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../../l10n/app_localizations.dart';
import 'ai_widgets.dart';
import 'moviroo_api_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MESSAGE MODEL
// ═══════════════════════════════════════════════════════════════════════════

enum MessageSender { user, bot }

class ChatMessage {
  final String text;
  final MessageSender sender;
  final double? confidence;
  final bool suggestTicket;
  final String? ticketId;
  final String source;

  const ChatMessage({
    required this.text,
    required this.sender,
    this.confidence,
    this.suggestTicket = false,
    this.ticketId,
    this.source = '',
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// AI AGENT PAGE
// ═══════════════════════════════════════════════════════════════════════════

class AiAgentPage extends StatefulWidget {
  const AiAgentPage({super.key});

  @override
  State<AiAgentPage> createState() => _AiAgentPageState();
}

class _AiAgentPageState extends State<AiAgentPage>
    with TickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final MovirooApi _api = MovirooApi();

  // ── State ────────────────────────────────────────────────────
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _showChat = false; // false = home screen, true = chat screen
  String? _lastTicketId;

  // ── Animation ────────────────────────────────────────────────
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  // ── Lifecycle ────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ── Handlers ─────────────────────────────────────────────────

  void _handleCardTap(String query) {
    _controller.text = query;
    _focusNode.requestFocus();
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isTyping) return;

    _controller.clear();
    _focusNode.unfocus();

    // Switch to chat view on first message
    if (!_showChat) {
      setState(() => _showChat = true);
    }

    setState(() {
      _messages.add(ChatMessage(text: text, sender: MessageSender.user));
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final res = await _api.chat(text);
      if (!mounted) return;

      if (res.ticketId != null) _lastTicketId = res.ticketId;

      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: res.answer,
          sender: MessageSender.bot,
          confidence: res.confidence,
          suggestTicket: res.suggestTicket,
          ticketId: res.ticketId,
          source: res.source,
        ));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(const ChatMessage(
          text: 'Connection error. Please check your network and try again.',
          sender: MessageSender.bot,
          source: 'error',
        ));
      });
    }
    _scrollToBottom();
  }

  Future<void> _handleCreateTicket(String question) async {
    try {
      final ticket = await _api.createTicket(question: question);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ticket created: ${ticket.ticketId}'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Failed to create ticket. Try again.'),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  Future<void> _handleFeedback(int rating) async {
    try {
      await _api.submitFeedback(
        rating: rating,
        ticketId: _lastTicketId,
        helpful: rating >= 4,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Thank you for your feedback! ⭐'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showFeedbackDialog() {
    int selected = 0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppColors.surface(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Rate this conversation',
            style: AppTextStyles.bodyLarge(context)
                .copyWith(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How helpful was the support?',
                  style: AppTextStyles.bodySmall(context)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => GestureDetector(
                    onTap: () => setS(() => selected = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < selected ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 38,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: AppTextStyles.bodySmall(context)
                      .copyWith(color: AppColors.subtext(context))),
            ),
            ElevatedButton(
              onPressed: selected > 0
                  ? () {
                      Navigator.pop(ctx);
                      _handleFeedback(selected);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              // Header — with feedback button when in chat
              _buildHeader(context),

              // Body — home or chat
              Expanded(
                child: _showChat
                    ? _buildChatView(context)
                    : _buildHomeView(context),
              ),

              // Input always visible
              AiInputSection(
                controller: _controller,
                focusNode: _focusNode,
                onSend: _handleSend,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_showChat) {
                setState(() => _showChat = false);
              } else {
                Navigator.maybePop(context);
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Icon(Icons.chevron_left_rounded,
                  size: 22, color: AppColors.text(context)),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.purpleGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.smart_toy_outlined,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).translate('ai_page_title'),
                  style: AppTextStyles.bodyLarge(context)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: AppColors.success, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context).translate('ai_online'),
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.success,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Feedback button — only in chat mode
          if (_showChat)
            GestureDetector(
              onTap: _showFeedbackDialog,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Icon(Icons.star_outline_rounded,
                    size: 20, color: AppColors.text(context)),
              ),
            ),
        ],
      ),
    );
  }

  // ── Home view (hero + cards) ──────────────────────────────────

  Widget _buildHomeView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const AiHeroSection(),
          const SizedBox(height: 24),
          Expanded(
            child: AiActionCards(onCardTap: _handleCardTap),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── Chat view (messages) ──────────────────────────────────────

  Widget _buildChatView(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == _messages.length) return _buildTypingBubble();
        return _buildMessageItem(_messages[i]);
      },
    );
  }

  Widget _buildMessageItem(ChatMessage msg) {
    final isUser = msg.sender == MessageSender.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[_buildBotAvatar(), const SizedBox(width: 8)],
              Flexible(child: _buildBubble(msg)),
            ],
          ),

          // Confidence bar — bot only
          if (!isUser && msg.confidence != null)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 5),
              child: _buildConfidenceBar(msg.confidence!),
            ),

          // Contact support button
          if (!isUser && msg.suggestTicket)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 8),
              child: _buildContactButton(msg.text),
            ),
        ],
      ),
    );
  }

  Widget _buildBotAvatar() => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: AppColors.purpleGradient,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.smart_toy_outlined,
            color: Colors.white, size: 18),
      );

  Widget _buildBubble(ChatMessage msg) {
    final isUser = msg.sender == MessageSender.user;
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        gradient: isUser ? AppColors.purpleGradient : null,
        color: isUser ? null : AppColors.surface(context),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isUser ? 16 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 16),
        ),
        border: isUser
            ? null
            : Border.all(color: AppColors.border(context), width: 1),
      ),
      child: Text(
        msg.text,
        style: AppTextStyles.bodyMedium(context).copyWith(
          color: isUser ? Colors.white : AppColors.text(context),
          height: 1.45,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildConfidenceBar(double confidence) {
    final Color color;
    final String label;
    if (confidence >= 0.82) {
      color = AppColors.success;
      label = 'High confidence';
    } else if (confidence >= 0.55) {
      color = Colors.orange;
      label = 'Medium';
    } else {
      color = Colors.red.shade400;
      label = 'Low confidence';
    }
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            width: 72,
            height: 3,
            child: LinearProgressIndicator(
              value: confidence.clamp(0.0, 1.0),
              backgroundColor: AppColors.border(context),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: AppTextStyles.bodySmall(context).copyWith(
                fontSize: 10, color: AppColors.subtext(context))),
      ],
    );
  }

  Widget _buildContactButton(String question) => GestureDetector(
        onTap: () => _handleCreateTicket(question),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.iconBg(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.headset_mic_outlined,
                  size: 15, color: AppColors.primaryPurple),
              const SizedBox(width: 6),
              Text(
                'Contact a support agent',
                style: AppTextStyles.bodySmall(context).copyWith(
                  fontSize: 12,
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildTypingBubble() => Padding(
        padding: const EdgeInsets.only(bottom: 14, left: 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildBotAvatar(),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                ),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (i) => _AnimatedDot(delay: Duration(milliseconds: i * 180)),
                ),
              ),
            ),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATED TYPING DOT
// ═══════════════════════════════════════════════════════════════════════════

class _AnimatedDot extends StatefulWidget {
  final Duration delay;
  const _AnimatedDot({required this.delay});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: Color.lerp(
              AppColors.border(context),
              AppColors.primaryPurple,
              _anim.value,
            ),
            shape: BoxShape.circle,
          ),
        ),
      );
}
