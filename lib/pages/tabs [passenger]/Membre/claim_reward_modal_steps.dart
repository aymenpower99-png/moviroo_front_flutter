import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import 'membership_tier.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STEP 1: CONFIRM VIEW
// ─────────────────────────────────────────────────────────────────────────────

class ClaimConfirmView extends StatelessWidget {
  final MembershipTier tier;
  final bool isDark;
  final VoidCallback onCancel;
  final VoidCallback onClaim;

  const ClaimConfirmView({
    super.key,
    required this.tier,
    required this.isDark,
    required this.onCancel,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final discountLabel = tier.discount.split(' ').first;
    final discountRest  = tier.discount.replaceFirst('$discountLabel ', '');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Icon bubble ──────────────────────────────────────
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: tier.accentColor.withValues(alpha: isDark ? 0.18 : 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.card_giftcard_rounded,
              color: tier.accentColor, size: 32),
        ),
        const SizedBox(height: 16),

        Text(
          'Unlock Your Reward!',
          style: AppTextStyles.bodyLarge(context)
              .copyWith(fontSize: 18, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          "You've reached ${tier.name}",
          style: AppTextStyles.bodySmall(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // ── Discount card ────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: tier.accentColor.withValues(alpha: isDark ? 0.14 : 0.09),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(
                discountLabel,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: tier.accentColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(discountRest,
                  style: AppTextStyles.bodySmall(context)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Buttons row ──────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  side: BorderSide(color: AppColors.border(context)),
                ),
                child: Text('Cancel',
                    style: AppTextStyles.bodySmall(context)
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: onClaim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: tier.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text(
                  'Claim Now',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADING VIEW
// ─────────────────────────────────────────────────────────────────────────────

class ClaimLoadingView extends StatelessWidget {
  final MembershipTier tier;
  const ClaimLoadingView({super.key, required this.tier});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: tier.accentColor,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text('Processing…', style: AppTextStyles.bodySmall(context)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 2: REVEALED VIEW
// ─────────────────────────────────────────────────────────────────────────────

class ClaimRevealedView extends StatelessWidget {
  final MembershipTier tier;
  final String promoCode;
  final bool copied;
  final bool isDark;
  final VoidCallback onCopy;
  final VoidCallback onDone;

  const ClaimRevealedView({
    super.key,
    required this.tier,
    required this.promoCode,
    required this.copied,
    required this.isDark,
    required this.onCopy,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: tier.accentColor.withValues(alpha: isDark ? 0.18 : 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_circle_rounded,
              color: tier.accentColor, size: 34),
        ),
        const SizedBox(height: 16),
        Text(
          'Reward Claimed!',
          style: AppTextStyles.bodyLarge(context)
              .copyWith(fontSize: 18, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(tier.discount,
            style: AppTextStyles.bodySmall(context),
            textAlign: TextAlign.center),
        const SizedBox(height: 20),

        Text('Your Code', style: AppTextStyles.bodySmall(context)),
        const SizedBox(height: 8),

        // ── Promo code tile ──────────────────────────────────
        GestureDetector(
          onTap: onCopy,
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: tier.accentColor
                  .withValues(alpha: isDark ? 0.14 : 0.09),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: tier.accentColor.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  promoCode,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: tier.accentColor,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  copied ? Icons.check_rounded : Icons.copy_rounded,
                  color: tier.accentColor,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onCopy,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  tier.accentColor.withValues(alpha: 0.15),
              foregroundColor: tier.accentColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(
              copied ? 'Copied!' : 'Copy Code',
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: tier.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text(
              'Done',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}