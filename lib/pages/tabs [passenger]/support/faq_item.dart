import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import 'support_models.dart';
import 'faq_widgets.dart';

/// The category header card that expands to show its Q&A entries.
class FaqItem extends StatefulWidget {
  final FaqCategory category;
  final IconData icon;

  const FaqItem({super.key, required this.category, required this.icon});

  @override
  State<FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<FaqItem>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _animController;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _expandAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _animController.forward() : _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _expanded
              ? AppColors.primaryPurple.withValues(alpha: 0.4)
              : AppColors.border(context),
        ),
      ),
      child: Column(
        children: [
          // ── Category header ──────────────────────────────────
          GestureDetector(
            onTap: _toggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.iconBg(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon,
                        color: AppColors.primaryPurple, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.category.title,
                          style: AppTextStyles.vehicleClassName(context),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.category.entries.length} questions',
                          style: AppTextStyles.bodySmall(context)
                              .copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.subtext(context),
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Expanded Q&A list ─────────────────────────────────
          SizeTransition(
            sizeFactor: _expandAnim,
            child: Column(
              children: [
                Divider(height: 1, color: AppColors.border(context)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    children: widget.category.entries
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: FaqEntryTile(entry: e),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}