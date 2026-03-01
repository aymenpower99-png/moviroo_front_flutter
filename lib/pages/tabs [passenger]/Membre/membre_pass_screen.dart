import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../widgets/tab_bar.dart';
import 'membership_tier.dart';
import 'pass_header_card.dart';
import 'tier_card.dart';

class MembrePassScreen extends StatelessWidget {
  const MembrePassScreen({super.key});

  static const int _userPoints   = 2450;
  static const int _nextLevel    = 3000;
  static const int _pointsToNext = 550;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      bottomNavigationBar: const AppTabBar(currentIndex: 2),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // ── Title ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Text(
                  t('membership_title'),
                  style: AppTextStyles.pageTitle(context).copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

            // ── Body ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PassHeaderCard(
                      userPoints: _userPoints,
                      nextLevel: _nextLevel,
                      pointsToNext: _pointsToNext,
                    ),

                    const SizedBox(height: 28),

                    Text(
                      t('membership_levels'),
                      style: AppTextStyles.sectionLabel(context),
                    ),

                    const SizedBox(height: 12),

                    ...List.generate(kMembershipTiers.length, (i) {
                      final isLast = i == kMembershipTiers.length - 1;
                      return Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                        child: TierCard(tier: kMembershipTiers[i]),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}