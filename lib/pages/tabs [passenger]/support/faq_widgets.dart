import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import 'support_models.dart';

// ── Individual Q&A tile ───────────────────────────────────────────────────────

class FaqEntryTile extends StatefulWidget {
  final FaqEntryData entry;
  const FaqEntryTile({super.key, required this.entry});

  @override
  State<FaqEntryTile> createState() => _FaqEntryTileState();
}

class _FaqEntryTileState extends State<FaqEntryTile>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return GestureDetector(
      onTap: _toggle,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _open
                ? AppColors.primaryPurple.withValues(alpha: 0.4)
                : AppColors.border(context),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      t(widget.entry.questionKey),
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _open
                            ? AppColors.text(context)
                            : AppColors.subtext(context),
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primaryPurple, size: 18),
                  ),
                ],
              ),
            ),
            SizeTransition(
              sizeFactor: _anim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(height: 1, color: AppColors.border(context)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    child: Text(
                      t(widget.entry.answerKey),
                      style: AppTextStyles.bodySmall(context).copyWith(
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── FAQ category accordion ────────────────────────────────────────────────────

class FaqItem extends StatefulWidget {
  final FaqCategoryData category;
  final IconData icon;
  const FaqItem({super.key, required this.category, required this.icon});

  @override
  State<FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<FaqItem>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
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
    final t = AppLocalizations.of(context).translate;

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
                          t(widget.category.titleKey),
                          style: AppTextStyles.vehicleClassName(context),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t('questions_count').replaceAll(
                              '{count}',
                              widget.category.entries.length.toString()),
                          style: AppTextStyles.bodySmall(context)
                              .copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.subtext(context), size: 22),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _anim,
            child: Column(
              children: [
                Divider(height: 1, color: AppColors.border(context)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    children: widget.category.entries
                        .map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: FaqEntryTile(entry: e),
                            ))
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