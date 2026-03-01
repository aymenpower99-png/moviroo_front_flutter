import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import 'membership_tier.dart';

/// User's current points — replace with your state management value.
const int kUserPoints = 2450;

/// Fixed collapsed height — uniform across all tiers.
const double kTierCardHeight = 72.0;

class TierCard extends StatefulWidget {
  final MembershipTier tier;

  const TierCard({super.key, required this.tier});

  @override
  State<TierCard> createState() => _TierCardState();
}

class _TierCardState extends State<TierCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

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
    _expandAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _fadeAnim   = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final tier     = widget.tier;
    final isLocked = tier.status == TierStatus.locked;

    final borderColor = _expanded
        ? tier.accentColor.withOpacity(0.6)
        : AppColors.border(context);

    final bgColor = _expanded
        ? tier.accentColor.withOpacity(isDark ? 0.07 : 0.04)
        : AppColors.surface(context);

    final shadows = _expanded && isDark
        ? [
            BoxShadow(
              color: tier.accentColor.withOpacity(0.14),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ]
        : null;

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: _expanded ? 1.5 : 1,
          ),
          boxShadow: shadows,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Collapsed row — fixed height ─────────────────────
            SizedBox(
              height: kTierCardHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    // Icon circle
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: tier.accentColor
                            .withOpacity(isDark ? 0.15 : 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          _tierIcon(tier.status),
                          color: isLocked
                              ? AppColors.subtext(context)
                              : tier.accentColor,
                          size: 20,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Name + pts
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tier.name,
                            style: AppTextStyles.bodyLarge(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${tier.pointsRequired} pts',
                            style: AppTextStyles.bodySmall(context),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Chevron
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _expanded
                            ? tier.accentColor
                            : AppColors.subtext(context),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Expanded panel ───────────────────────────────────
            SizeTransition(
              sizeFactor: _expandAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: _ExpandedPanel(tier: tier, isDark: isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _tierIcon(TierStatus s) {
    switch (s) {
      case TierStatus.locked:   return Icons.lock_outline_rounded;
      case TierStatus.unlocked: return Icons.lock_open_rounded;
      case TierStatus.current:  return Icons.stars_rounded;
      case TierStatus.used:     return Icons.check_circle_outline_rounded;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXPANDED PANEL
// ─────────────────────────────────────────────────────────────────────────────

class _ExpandedPanel extends StatelessWidget {
  final MembershipTier tier;
  final bool isDark;

  const _ExpandedPanel({required this.tier, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final t          = AppLocalizations.of(context).translate;
    final isLocked   = tier.status == TierStatus.locked;
    final isUnlocked = tier.status == TierStatus.unlocked;
    final isCurrent  = tier.status == TierStatus.current;
    final int missingPts =
        isLocked ? (tier.pointsRequired - kUserPoints).clamp(0, 99999) : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: tier.accentColor.withOpacity(0.25), height: 1),
          const SizedBox(height: 14),

          // Discount pill
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isLocked
                  ? AppColors.border(context).withOpacity(0.5)
                  : tier.accentColor.withOpacity(isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_offer_rounded,
                  color: isLocked
                      ? AppColors.subtext(context)
                      : tier.accentColor,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  tier.discount,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isLocked
                        ? AppColors.subtext(context)
                        : tier.accentColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Action button
          SizedBox(
            width: double.infinity,
            child: _ActionButton(
              tier: tier,
              isLocked: isLocked,
              isUnlocked: isUnlocked,
              isCurrent: isCurrent,
              missingPts: missingPts,
              isDark: isDark,
              t: t,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTION BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final MembershipTier tier;
  final bool isLocked;
  final bool isUnlocked;
  final bool isCurrent;
  final int missingPts;
  final bool isDark;
  final String Function(String) t;

  const _ActionButton({
    required this.tier,
    required this.isLocked,
    required this.isUnlocked,
    required this.isCurrent,
    required this.missingPts,
    required this.isDark,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    // Locked — disabled, shows missing points
    if (isLocked) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1A1A20)
              : const Color(0xFFF0F0F4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded,
                size: 15, color: AppColors.subtext(context)),
            const SizedBox(width: 8),
            Text(
              t('tier_need_pts').replaceAll('{pts}', '$missingPts'),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.subtext(context),
              ),
            ),
          ],
        ),
      );
    }

    // Unlocked
    if (isUnlocked) {
      return ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: tier.accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: Text(
          t('tier_claim_reward'),
          style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600),
        ),
      );
    }

    // Current
    if (isCurrent) {
      return ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: tier.accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: Text(
          t('tier_active'),
          style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600),
        ),
      );
    }

    // Used
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1A20)
            : const Color(0xFFF0F0F4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 15, color: AppColors.subtext(context)),
          const SizedBox(width: 8),
          Text(
            t('tier_reward_used'),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.subtext(context),
            ),
          ),
        ],
      ),
    );
  }
}