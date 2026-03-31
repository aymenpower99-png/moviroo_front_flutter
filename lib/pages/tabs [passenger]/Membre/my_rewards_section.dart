import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import 'membership_tier.dart';

/// A reward entry displayed in "My Rewards".
class ClaimedReward {
  final MembershipTier tier;
  final String promoCode;

  const ClaimedReward({required this.tier, required this.promoCode});
}

/// Horizontal scrollable "My Rewards" section.
/// Pass an empty list to hide the section entirely.
class MyRewardsSection extends StatefulWidget {
  final List<ClaimedReward> rewards;

  const MyRewardsSection({super.key, required this.rewards});

  @override
  State<MyRewardsSection> createState() => _MyRewardsSectionState();
}

class _MyRewardsSectionState extends State<MyRewardsSection> {
  final Set<int> _copiedIndices = {};

  void _copy(int index) {
    Clipboard.setData(ClipboardData(text: widget.rewards[index].promoCode));
    setState(() => _copiedIndices.add(index));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedIndices.remove(index));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rewards.isEmpty) return const SizedBox.shrink();

    final t    = AppLocalizations.of(context).translate;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('my_rewards_title'),
          style: AppTextStyles.sectionLabel(context),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.rewards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final reward  = widget.rewards[i];
              final copied  = _copiedIndices.contains(i);
              final accent  = reward.tier.accentColor;
              final discount = reward.tier.discount.split(' ').first;

              return GestureDetector(
                onTap: () => _copy(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 160,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: accent.withValues(alpha: copied ? 0.7 : 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            discount,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                          ),
                          Icon(
                            copied
                                ? Icons.check_circle_rounded
                                : Icons.copy_rounded,
                            color: accent,
                            size: 16,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reward.promoCode,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: accent,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            copied ? 'Copied!' : 'Tap to copy',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              color: AppColors.subtext(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}