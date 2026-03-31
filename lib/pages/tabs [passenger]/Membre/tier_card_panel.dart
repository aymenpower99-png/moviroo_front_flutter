import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import 'membership_tier.dart';

const int kUserPoints = 2450;

// ─────────────────────────────────────────────────────────────────────────────
// EXPANDED PANEL  (mounted inside TierCard via SizeTransition)
// ─────────────────────────────────────────────────────────────────────────────

class TierExpandedPanel extends StatelessWidget {
  final MembershipTier tier;
  final bool isDark;
  final TierClaimState claimState;
  final VoidCallback onUnlockTap;

  const TierExpandedPanel({
    super.key,
    required this.tier,
    required this.isDark,
    required this.claimState,
    required this.onUnlockTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked  = tier.status == TierStatus.locked;
    final hasEnough = kUserPoints >= tier.pointsRequired;
    final claimed   = claimState.claimed;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
              color: tier.accentColor.withValues(alpha: 0.25), height: 1),
          const SizedBox(height: 14),

          // ── Discount pill ──────────────────────────────────
          _DiscountPill(
            tier: tier,
            isDark: isDark,
            dim: isLocked && !hasEnough,
          ),

          const SizedBox(height: 14),

          // ── Content: claimed code | progress | unlock btn ──
          if (claimed && claimState.promoCode != null)
            TierClaimedCodeBlock(
                tier: tier,
                promoCode: claimState.promoCode!,
                isDark: isDark)
          else if (!hasEnough)
            TierProgressBlock(tier: tier, isDark: isDark)
          else
            TierUnlockButton(tier: tier, onTap: onUnlockTap),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DISCOUNT PILL
// ─────────────────────────────────────────────────────────────────────────────

class _DiscountPill extends StatelessWidget {
  final MembershipTier tier;
  final bool isDark;
  final bool dim;

  const _DiscountPill(
      {required this.tier, required this.isDark, required this.dim});

  @override
  Widget build(BuildContext context) {
    final color =
        dim ? AppColors.subtext(context) : tier.accentColor;
    final bg = dim
        ? AppColors.border(context).withValues(alpha: 0.5)
        : tier.accentColor.withValues(alpha: isDark ? 0.18 : 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_offer_rounded, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            tier.discount,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANIMATED PROGRESS BLOCK
// ─────────────────────────────────────────────────────────────────────────────

class TierProgressBlock extends StatefulWidget {
  final MembershipTier tier;
  final bool isDark;

  const TierProgressBlock(
      {super.key, required this.tier, required this.isDark});

  @override
  State<TierProgressBlock> createState() => _TierProgressBlockState();
}

class _TierProgressBlockState extends State<TierProgressBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _prog;

  @override
  void initState() {
    super.initState();
    final target =
        (kUserPoints / widget.tier.pointsRequired).clamp(0.0, 1.0);
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _prog = Tween<double>(begin: 0, end: target).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final missing =
        (widget.tier.pointsRequired - kUserPoints).clamp(0, 99999);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$kUserPoints pts',
                style: AppTextStyles.bodySmall(context)
                    .copyWith(fontWeight: FontWeight.w600)),
            Text('${widget.tier.pointsRequired} pts',
                style: AppTextStyles.bodySmall(context)),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _prog,
          builder: (_, __) => ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _prog.value,
              minHeight: 8,
              backgroundColor: widget.isDark
                  ? const Color(0xFF222228)
                  : const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(
                  widget.tier.accentColor),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.lock_outline_rounded,
                size: 13, color: AppColors.subtext(context)),
            const SizedBox(width: 5),
            Text('$missing pts needed',
                style: AppTextStyles.bodySmall(context)),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UNLOCK BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class TierUnlockButton extends StatelessWidget {
  final MembershipTier tier;
  final VoidCallback onTap;

  const TierUnlockButton(
      {super.key, required this.tier, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.lock_open_rounded, size: 16),
        label: const Text(
          'Unlock Reward',
          style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: tier.accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CLAIMED CODE BLOCK
// ─────────────────────────────────────────────────────────────────────────────

class TierClaimedCodeBlock extends StatefulWidget {
  final MembershipTier tier;
  final String promoCode;
  final bool isDark;

  const TierClaimedCodeBlock({
    super.key,
    required this.tier,
    required this.promoCode,
    required this.isDark,
  });

  @override
  State<TierClaimedCodeBlock> createState() => _TierClaimedCodeBlockState();
}

class _TierClaimedCodeBlockState extends State<TierClaimedCodeBlock> {
  bool _copied = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.promoCode));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.tier.accentColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Code', style: AppTextStyles.bodySmall(context)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _copy,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: accent
                  .withValues(alpha: widget.isDark ? 0.14 : 0.09),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color:
                      accent.withValues(alpha: _copied ? 0.7 : 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.promoCode,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: 1.2,
                  ),
                ),
                Icon(
                  _copied
                      ? Icons.check_rounded
                      : Icons.copy_rounded,
                  color: accent,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}