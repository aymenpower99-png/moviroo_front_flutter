import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../widgets/tab_bar.dart';
import 'membership_tier.dart';
import 'pass_header_card.dart';
import 'tier_card.dart';
import 'my_rewards_section.dart';
import 'claim_reward_modal.dart';

class MembrePassScreen extends StatefulWidget {
  const MembrePassScreen({super.key});

  @override
  State<MembrePassScreen> createState() => _MembrePassScreenState();
}

class _MembrePassScreenState extends State<MembrePassScreen> {
  // ── Constants ────────────────────────────────────────────
  static const int _userPoints   = 2450;
  static const int _nextLevel    = 3000;
  static const int _pointsToNext = 550;

  // ── Expanded accordion index (null = all collapsed) ──────
  int? _expandedIndex;

  // ── Per-tier claim state (indexed parallel to kMembershipTiers) ─
  late final List<TierClaimState> _claimStates;

  // ── Rewards shown in "My Rewards" strip ──────────────────
  final List<ClaimedReward> _myRewards = [];

  @override
  void initState() {
    super.initState();
    _claimStates = List.generate(
      kMembershipTiers.length,
      (_) => const TierClaimState(),
    );
  }

  // ── Accordion ─────────────────────────────────────────────
  void _onTierTap(int index) {
    setState(() {
      _expandedIndex = (_expandedIndex == index) ? null : index;
    });
  }

  // ── Unlock → modal flow ───────────────────────────────────
  Future<void> _onUnlockTap(int index) async {
    final tier = kMembershipTiers[index];

    final promoCode = await showClaimRewardModal(context, tier);

    if (promoCode == null || !mounted) return;

    setState(() {
      _claimStates[index] = TierClaimState(claimed: true, promoCode: promoCode);
      _myRewards.insert(
        0,
        ClaimedReward(tier: tier, promoCode: promoCode),
      );
    });
  }

  // ── Derive current level number from tiers ────────────────
  int get _currentLevelNumber {
    for (int i = 0; i < kMembershipTiers.length; i++) {
      if (kMembershipTiers[i].status == TierStatus.current) return i + 1;
    }
    return 1;
  }

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
            // ── Page title ───────────────────────────────────
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

            // ── Body ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header card ──────────────────────────
                    PassHeaderCard(
                      userPoints: _userPoints,
                      nextLevel: _nextLevel,
                      pointsToNext: _pointsToNext,
                      currentLevelNumber: _currentLevelNumber,
                    ),

                    const SizedBox(height: 28),

                    // ── My Rewards strip (hidden when empty) ─
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      child: MyRewardsSection(rewards: _myRewards),
                    ),

                    // ── Section label ────────────────────────
                    Text(
                      t('membership_levels'),
                      style: AppTextStyles.sectionLabel(context),
                    ),

                    const SizedBox(height: 12),

                    // ── Tier cards ───────────────────────────
                    ...List.generate(kMembershipTiers.length, (i) {
                      final isLast = i == kMembershipTiers.length - 1;
                      return Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                        child: TierCard(
                          tier: kMembershipTiers[i],
                          isExpanded: _expandedIndex == i,
                          onTap: () => _onTierTap(i),
                          claimState: _claimStates[i],
                          onUnlockTap: () => _onUnlockTap(i),
                        ),
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