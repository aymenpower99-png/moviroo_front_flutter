import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import 'membership_tier.dart';
import 'tier_card_panel.dart';

export 'membership_tier.dart' show TierClaimState;

const double kTierCardHeight = 72.0;

class TierCard extends StatefulWidget {
  final MembershipTier tier;
  final bool isExpanded;
  final VoidCallback onTap;
  final TierClaimState claimState;
  final VoidCallback onUnlockTap;
  final int userPoints;

  const TierCard({
    super.key,
    required this.tier,
    required this.isExpanded,
    required this.onTap,
    required this.claimState,
    required this.onUnlockTap,
    required this.userPoints,
  });

  @override
  State<TierCard> createState() => _TierCardState();
}

class _TierCardState extends State<TierCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _expandAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _expandAnim =
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
  }

  @override
  void didUpdateWidget(TierCard old) {
    super.didUpdateWidget(old);
    if (widget.isExpanded != old.isExpanded) {
      widget.isExpanded ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final tier    = widget.tier;

    final borderColor = widget.isExpanded
        ? AppColors.primaryPurple.withValues(alpha: 0.6)
        : AppColors.border(context);

    final bgColor = widget.isExpanded
        ? AppColors.primaryPurple.withValues(alpha: isDark ? 0.07 : 0.04)
        : AppColors.surface(context);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: widget.isExpanded ? 1.5 : 1,
          ),
          boxShadow: widget.isExpanded && isDark
              ? [
                  BoxShadow(
                    color: AppColors.primaryPurple.withValues(alpha: 0.14),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Collapsed row ──────────────────────────────
            SizedBox(
              height: kTierCardHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tier.name,
                              style: AppTextStyles.bodyLarge(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 3),
                          Text('${tier.pointsRequired}',
                              style: AppTextStyles.bodySmall(context)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: widget.isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: widget.isExpanded
                            ? AppColors.primaryPurple
                            : AppColors.subtext(context),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Expanded panel ─────────────────────────────
            SizeTransition(
              sizeFactor: _expandAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: TierExpandedPanel(
                  tier: tier,
                  isDark: isDark,
                  claimState: widget.claimState,
                  onUnlockTap: widget.onUnlockTap,
                  userPoints: widget.userPoints,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}