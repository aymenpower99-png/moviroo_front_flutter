import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/membership/membership_service.dart';
import '../../../../providers/membership_provider.dart';
import '../../../../routing/router.dart';
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

class _MembrePassScreenState extends State<MembrePassScreen>
    with RouteAware {
  // ── API state ─────────────────────────────────────────────
  MembershipInfo? _membershipInfo;
  bool _loading = false; // ← never default to true
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

    // Pre-populate from provider cache synchronously — avoids first-frame spinner
    final provider = context.read<MembershipProvider>();
    if (provider.hasLoaded && provider.info != null) {
      _populateFromInfo(provider.info!); // sets fields + _loading = false
    }

    // Always schedule a background load/refresh (force API call every time)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFromProvider(force: true, silent: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  // Called when this page becomes visible again (e.g. switching tabs)
  @override
  void didPopNext() {
    _loadFromProvider(force: true, silent: true);
  }

  /// Sets state fields directly — safe to call from initState (no setState).
  void _populateFromInfo(MembershipInfo info) {
    _membershipInfo = info;
    _tiers = List.generate(
      info.levels.length,
      (i) => MembershipTier.fromLevel(
        info.levels[i],
        info.userPoints,
        info.currentLevel,
      ),
    );
    _claimStates = List.generate(_tiers.length, (i) {
      final levelId = info.levels[i].id;
      return TierClaimState(
        claimed: info.claimedLevelIds.contains(levelId),
        promoCode: info.activeCouponCodes[levelId],
      );
    });
    // Restore "My Rewards" from active coupon codes so they survive page refresh
    _myRewards.clear();
    for (final entry in info.activeCouponCodes.entries) {
      final levelId = entry.key;
      final promoCode = entry.value;
      final tierIndex = _tiers.indexWhere((t) => t.id == levelId);
      if (tierIndex != -1) {
        _myRewards.add(ClaimedReward(tier: _tiers[tierIndex], promoCode: promoCode));
      }
    }
    _loading = false;
  }

  Future<void> _loadFromProvider({bool force = false, bool silent = false}) async {
    final provider = context.read<MembershipProvider>();

    // Use cached data immediately if available and not forcing refresh
    if (!force && provider.hasLoaded && provider.info != null) {
      _applyInfo(provider.info!);
      return;
    }

    // Silent mode: show cached data immediately, refresh in background
    if (silent && provider.hasLoaded && provider.info != null) {
      _applyInfo(provider.info!); // show cached immediately
    } else if (silent) {
      // No cached data but silent mode — show spinner on first load
      setState(() {
        _loading = true;
        _error = null;
      });
    } else if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    await provider.loadMembership(force: true);

    if (!mounted) return;

    final info = provider.info;
    if (info == null) {
      if (silent) return; // don't show error on silent refresh
      setState(() {
        _error = provider.error ?? 'Unknown error';
        _loading = false;
      });
      return;
    }

    _applyInfo(info);
  }

  void _applyInfo(MembershipInfo info) {
    setState(() => _populateFromInfo(info));
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

    // Update local state immediately; provider refresh will restore code from activeCouponCodes
    setState(() {
      _claimStates[index] = TierClaimState(claimed: true, promoCode: promoCode);
      _myRewards.insert(0, ClaimedReward(tier: tier, promoCode: promoCode));
    });
    // Silent refresh so points/level in header update without blocking
    await _loadFromProvider(force: true, silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      bottomNavigationBar: const AppTabBar(currentIndex: 2),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _loadFromProvider(force: true),
          color: const Color(0xFFA855F7),
          backgroundColor: AppColors.surface(context),
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
                                      onPressed: () => _loadFromProvider(force: true),
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
                          : _membershipInfo != null
                              ? _buildContent(t)
                              : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
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
          currentLevelNumber: info.currentLevel?.level ?? 0,
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