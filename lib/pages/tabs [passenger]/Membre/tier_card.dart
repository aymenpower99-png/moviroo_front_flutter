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

  const TierCard({
    super.key,
    required this.tier,
    required this.isExpanded,
    required this.onTap,
    required this.claimState,
    required this.onUnlockTap,
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
        ? tier.accentColor.withValues(alpha: 0.6)
        : AppColors.border(context);

    final bgColor = widget.isExpanded
        ? tier.accentColor.withValues(alpha: isDark ? 0.07 : 0.04)
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
                    color: tier.accentColor.withValues(alpha: 0.14),
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
                    _TierIconBubble(tier: tier, isDark: isDark),
                    const SizedBox(width: 12),
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
                          Text('${tier.pointsRequired} pts',
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
                            ? tier.accentColor
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ICON BUBBLE
// ─────────────────────────────────────────────────────────────────────────────

class _TierIconBubble extends StatelessWidget {
  final MembershipTier tier;
  final bool isDark;

  const _TierIconBubble({required this.tier, required this.isDark});

  IconData _icon(TierStatus s) {
    switch (s) {
      case TierStatus.locked:   return Icons.lock_outline_rounded;
      case TierStatus.unlocked: return Icons.lock_open_rounded;
      case TierStatus.current:  return Icons.stars_rounded;
      case TierStatus.used:     return Icons.check_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = tier.status == TierStatus.locked;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: tier.accentColor.withValues(alpha: isDark ? 0.15 : 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          _icon(tier.status),
          color:
              isLocked ? AppColors.subtext(context) : tier.accentColor,
          size: 20,
        ),
      ),
    );
  }
}