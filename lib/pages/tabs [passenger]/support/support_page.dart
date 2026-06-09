import 'package:flutter/material.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/tab_bar.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/support_service.dart';
import '../../../../services/help_center_service.dart';
import '../../../../routing/router.dart';
import '../../../../main.dart';
import 'help_center_models.dart';
import 'help_center_widgets.dart';
import 'help_category_page.dart';
import 'help_all_articles_page.dart';
import 'Sumbit Ticket/support_page.dart' as ticket;
import 'AI/ai_agent_page.dart';
import 'messages_modal.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  int _tabIndex = 3;
  final SupportService _supportService = SupportService();
  late HelpCenterService _helpCenterService;
  List<SupportTicket> _tickets = [];
  bool _isLoadingTickets = false;
  bool _hasLoadedTickets = false;
  Timer? _pollTimer;

  // ── Help Center categories ─────────────────────────────────────────────────
  List<HelpCategory>? _categories;
  bool _loadingCategories = false;

  int get _unreadCount => _tickets.where((t) => t.hasUnread).length;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _supportService.dispose();
    super.dispose();
  }

  void _showMessagesModal() {
    // Mark all tickets as read on backend — badge clears immediately
    _supportService.markAllAsRead();
    setState(() {
      for (final t in _tickets) {
        if (t.hasUnread) {
          // Optimistic local update so badge clears instantly
          t.hasUnread = false;
        }
      }
    });
    _loadTickets();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MessagesModal(
        initialTickets: _tickets,
        onTicketTap: (ticket) {
          Navigator.pop(context);
          AppRouter.push(
            context,
            AppRouter.supportChat,
            args: {'ticketId': ticket.id, 'subject': ticket.subject},
          );
        },
      ),
    );
  }

  Future<void> _loadTickets() async {
    final cached = SupportService.cachedTickets;
    if (cached != null && cached.isNotEmpty && _tickets.isEmpty) {
      setState(() {
        _tickets = cached;
      });
    }

    try {
      final tickets = await _supportService.listTickets();
      if (mounted) {
        setState(() {
          _tickets = tickets;
          _isLoadingTickets = false;
          _hasLoadedTickets = true;
        });
        // Debug: log ticket data for badge troubleshooting
        for (final t in tickets) {
          print(
            '[SupportPage] ticket=${t.id} status=${t.status} '
            'hasUnread=${t.hasUnread} '
            'updatedAt=${t.updatedAt.toIso8601String()} '
            'unreadCount=$_unreadCount',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTickets = false;
          _hasLoadedTickets = true;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _helpCenterService = HelpCenterService(
      lang: localeProvider.locale.languageCode,
    );

    final cached = HelpCenterService.cachedCategories;
    if (cached != null) {
      _categories = cached;
      _refreshCategories();
    } else {
      _loadingCategories = true;
      _fetchCategories();
    }

    // Load tickets immediately so badge shows on first visit
    _loadTickets();

    // Poll tickets every 15s to detect new admin replies (replaces WebSocket)
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _loadTickets();
    });
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await _helpCenterService.fetchCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _loadingCategories = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _refreshCategories() async {
    try {
      final categories = await _helpCenterService.fetchCategories();
      if (mounted) setState(() => _categories = categories);
    } catch (_) {}
  }

  Future<void> _callSupport() async {
    final Uri telUri = Uri(scheme: 'tel', path: '+21694338510');
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot make phone calls on this device'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // ── Top bar with title ─────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            t('help_support'),
                            style: AppTextStyles.pageTitle(context).copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _showMessagesModal,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.iconBg(context),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primaryPurple.withValues(
                                      alpha: 0.35,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.message_rounded,
                                  color: AppColors.primaryPurple,
                                  size: 20,
                                ),
                              ),
                              if (_unreadCount > 0)
                                Positioned(
                                  right: -4,
                                  top: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Text(
                                      '${_unreadCount > 9 ? '9+' : _unreadCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Inter',
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── Quick Actions ──────────────────────────────
                    Text(
                      t('quick_actions'),
                      style: AppTextStyles.sectionLabel(context),
                    ),
                    const SizedBox(height: 14),

                    _AiBanner(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AiAgentPage()),
                      ),
                    ),
                    const SizedBox(height: 14),

                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _ActionCard(
                              icon: Icons.confirmation_number_outlined,
                              title: t('submit_ticket'),
                              sub: t('submit_ticket_sub'),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ticket.SubmitTicketPage(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionCard(
                              icon: Icons.phone_outlined,
                              title: t('call_support'),
                              sub: t('call_support_sub'),
                              onTap: _callSupport,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Help Center ────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            t('help_center'),
                            style: AppTextStyles.sectionLabel(context),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HelpAllArticlesPage(),
                            ),
                          ),
                          child: Text(
                            t('view_all'),
                            style: AppTextStyles.bodyMedium(context).copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Help Center grid ───────────────────────────────────
                    if (_loadingCategories)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: CircularProgressIndicator(
                            color: AppColors.primaryPurple,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    else if (_categories != null && _categories!.isNotEmpty)
                      HelpCenterGrid(
                        categories: _categories!,
                        onCategoryTap: (category) => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                HelpCategoryPage(category: category),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            AppTabBar(
              currentIndex: _tabIndex,
              onTap: (i) => setState(() => _tabIndex = i),
            ),
          ],
        ),
      ),
    );
  }
}

// ── AI Assistant banner ───────────────────────────────────────────────────────

class _AiBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _AiBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          gradient: AppColors.purpleGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('ai_assistant'),
                    style: AppTextStyles.pageTitle(context).copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t('ai_assistant_sub'),
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: const Color(0xFFDDB8FF)),
                  ),
                ],
              ),
            ),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick action card ─────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // ✅ FIX: replaced fixed height: 160 with minHeight constraint
        // so cards grow with content and always match each other's height
        constraints: const BoxConstraints(minHeight: 160),
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.iconBg(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primaryPurple, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge(
                context,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionLabel(
                context,
              ).copyWith(fontSize: 10, letterSpacing: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}
