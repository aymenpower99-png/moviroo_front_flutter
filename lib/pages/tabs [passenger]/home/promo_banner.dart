import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/membership/membership_service.dart';
import '../../../../routing/router.dart';

class PromoBanner extends StatefulWidget {
  const PromoBanner({super.key});

  @override
  State<PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<PromoBanner> {
  MembershipInfo? _membershipInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembership();
  }

  Future<void> _loadMembership() async {
    try {
      final info = await MembershipService.getMembershipInfo();
      if (!mounted) return;
      setState(() {
        _membershipInfo = info;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Returns the first/lowest tier's required points, or a fallback.
  int get _firstTierPoints {
    final levels = _membershipInfo?.levels ?? [];
    if (levels.isEmpty) return 500; // fallback if API fails
    // Sort by level ascending and take the first
    final sorted = List<MembershipLevelData>.from(levels)
      ..sort((a, b) => a.level.compareTo(b.level));
    return sorted.first.requiredPoints;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    // If still loading, show a shimmer-like placeholder with static text
    // so the layout doesn't jump when data arrives.
    if (_isLoading) {
      return _buildCard(
        context,
        t: t,
        headline: t.translate('promo_headline'),
        cta: t.translate('promo_cta'),
        onTap: () {},
      );
    }

    // Dynamic headline using the first tier's threshold
    final points = _firstTierPoints;
    final dynamicHeadline = t
        .translate('promo_headline_dynamic')
        .replaceFirst('{points}', '$points');

    return _buildCard(
      context,
      t: t,
      headline: dynamicHeadline,
      cta: t.translate('promo_cta'),
      onTap: () => AppRouter.push(context, AppRouter.membre),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required AppLocalizations t,
    required String headline,
    required String cta,
    required VoidCallback onTap,
  }) {
    return Container(
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
                      headline,
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
                        onPressed: onTap,
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
                        child: Text(
                          cta,
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
