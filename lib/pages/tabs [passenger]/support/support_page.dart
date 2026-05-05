import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/tab_bar.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/support_service.dart';
import '../../../../services/support_websocket_service.dart';
import '../../../../services/help_center_service.dart';
import '../../../../routing/router.dart';
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
  final SupportWebSocketService _wsService = SupportWebSocketService();
  final HelpCenterService _helpCenterService = HelpCenterService();
  List<SupportTicket> _tickets = [];
  bool _isLoadingTickets = false;
  int _unreadCount = 0;
  late Future<List<HelpCategory>> _categoriesFuture;

  @override
  void dispose() {
    _supportService.dispose();
    super.dispose();
  }

  void _showMessagesModal() {
    setState(() => _unreadCount = 0);
    print(
      '[SupportPage] Opening messages modal with ${_tickets.length} tickets',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MessagesModal(
        tickets: _tickets,
        isLoading: _isLoadingTickets,
        onRefresh: _loadTickets,
        onTicketTap: (ticket) {
          print(
            '[SupportPage] Ticket tapped, navigating to chat - ticketId: ${ticket.id}',
          );
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
    setState(() => _isLoadingTickets = true);
    try {
      print('[SupportPage] Loading tickets...');
      final tickets = await _supportService.listTickets();
      print('[SupportPage] Loaded ${tickets.length} tickets');
      if (mounted) {
        setState(() {
          _tickets = tickets;
          _isLoadingTickets = false;
        });
      }
    } catch (e) {
      print('[SupportPage] Error loading tickets: $e');
      if (mounted) {
        setState(() => _isLoadingTickets = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTickets();
    _connectWebSocket();
    _categoriesFuture = _helpCenterService.fetchCategories();
  }

  Future<void> _connectWebSocket() async {
    await _wsService.connect();
    _wsService.onUnreadCountChanged = (count) {
      if (mounted) {
        setState(() => _unreadCount += count);
      }
    };
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
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      _unreadCount > 9 ? '9+' : '$_unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
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

                    FutureBuilder<List<HelpCategory>>(
                      future: _categoriesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: CircularProgressIndicator(
                                color: AppColors.primaryPurple,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return HelpCenterGrid(
                          categories: snapshot.data!,
                          onCategoryTap: (category) => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  HelpCategoryPage(category: category),
                            ),
                          ),
                        );
                      },
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
