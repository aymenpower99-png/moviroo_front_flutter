import 'package:flutter/material.dart';
import '../../widgets/tab_bar.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import 'support_data.dart';
import 'faq_widgets.dart';
import 'Sumbit Ticket/support_page.dart' as ticket;
import 'AI/ai_agent_page.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  int _tabIndex = 3;

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
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.iconBg(context),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryPurple
                                  .withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: AppColors.primaryPurple,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── Quick Actions ──────────────────────────────
                    Text(t('quick_actions'),
                        style: AppTextStyles.sectionLabel(context)),
                    const SizedBox(height: 14),

                    _AiBanner(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AiAgentPage()),
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
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Frequently Asked ───────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Text(t('frequently_asked'),
                              style: AppTextStyles.sectionLabel(context)),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Text(
                            t('view_all'),
                            style:
                                AppTextStyles.bodyMedium(context).copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    ...List.generate(
                      kFaqCategories.length,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FaqItem(
                          category: kFaqCategories[i],
                          icon: kFaqIcons[i],
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
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: const Color(0xFFDDB8FF),
                    ),
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
              child:
                  Icon(icon, color: AppColors.primaryPurple, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge(context).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionLabel(context).copyWith(
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}