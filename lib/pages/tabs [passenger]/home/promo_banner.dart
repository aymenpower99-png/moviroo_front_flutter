import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';

class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Container(
      // Removed fixed height: 160 — caused overflow when translated text
      // (e.g. French) wraps to more lines than the English original.
      constraints: const BoxConstraints(minHeight: 160),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── LEFT: text content ───────────────────────────────────
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // pill label
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryPurple),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        t.translate('promo_membership_label'),
                        style: AppTextStyles.sectionLabel(context).copyWith(
                          color: AppColors.primaryPurple,
                          fontSize: 9,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // headline
                    Text(
                      t.translate('promo_headline'),
                      style: AppTextStyles.pageTitle(context).copyWith(
                        color: AppColors.text(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // CTA button
                    SizedBox(
                      height: 34,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        // Was `const Text(...)` — const prevents runtime
                        // string substitution, so the key was rendered as-is.
                        child: Text(
                          t.translate('promo_cta'),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── RIGHT: car image ─────────────────────────────────────
            Expanded(
              flex: 4,
              child: Transform.translate(
                offset: const Offset(-10, 0),
                child: Image.asset(
                  'images/car.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}