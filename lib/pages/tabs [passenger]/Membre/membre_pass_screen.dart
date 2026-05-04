import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/membership/membership_service.dart';
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
  // ── API state ─────────────────────────────────────────────
  MembershipInfo? _membershipInfo;
  bool _loading = true;
  String? _error;

  // ── Derived tier list (built from API) ───────────────────
  List<MembershipTier> _tiers = [];

  // ── Expanded accordion index (null = all collapsed) ──────
  int? _expandedIndex;

  // ── Per-tier claim state (indexed parallel to _tiers) ────
  List<TierClaimState> _claimStates = [];

  // ── Rewards shown in "My Rewards" strip ──────────────────
  final List<ClaimedReward> _myRewards = [];

  @override
  void initState() {
    super.initState();
    _fetchMembership();
  }

  Future<void> _fetchMembership() async {
    try {
      final info = await MembershipService.getMembershipInfo();
      if (!mounted) return;
      setState(() {
        _membershipInfo = info;
        _tiers = List.generate(
          info.levels.length,
          (i) => MembershipTier.fromLevel(
            info.levels[i],
            i,
            info.userPoints,
            info.currentLevel,
          ),
        );
        _claimStates = List.generate(_tiers.length, (_) => const TierClaimState());
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ── Accordion ─────────────────────────────────────────────
  void _onTierTap(int index) {
    setState(() {
      _expandedIndex = (_expandedIndex == index) ? null : index;
    });
  }

  // ── Unlock → modal flow ───────────────────────────────────
  Future<void> _onUnlockTap(int index) async {
    final tier = _tiers[index];

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
                child: _loading
                    ? const SizedBox(
                        height: 300,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFA855F7),
                          ),
                        ),
                      )
                    : _error != null
                        ? SizedBox(
                            height: 300,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.cloud_off_rounded,
                                      size: 48,
                                      color: AppColors.subtext(context)),
                                  const SizedBox(height: 12),
                                   Text(
                                    _error!,
                                    style: AppTextStyles.bodySmall(context),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _loading = true;
                                        _error = null;
                                      });
                                      _fetchMembership();
                                    },
                                    child: Text(
                                      t('retry'),
                                      style: const TextStyle(
                                          color: Color(0xFFA855F7)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _buildContent(t),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(String Function(String) t) {
    final info = _membershipInfo!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header card ──────────────────────────
        PassHeaderCard(
          userPoints: info.userPoints,
          progressPercent: info.progressPercent,
          pointsToNext: info.pointsToNext,
          currentLevelName: info.currentLevelName,
          currentLevelNumber: info.currentLevel?.order ?? 0,
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

        // ── Tier cards (empty state when no levels) ─
        if (_tiers.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                t('membership_no_levels'),
                style: AppTextStyles.bodySmall(context),
              ),
            ),
          )
        else
          ...List.generate(_tiers.length, (i) {
            final isLast = i == _tiers.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
              child: TierCard(
                tier: _tiers[i],
                isExpanded: _expandedIndex == i,
                onTap: () => _onTierTap(i),
                claimState: _claimStates[i],
                onUnlockTap: () => _onUnlockTap(i),
                userPoints: info.userPoints,
              ),
            );
          }),
      ],
    );
  }
}