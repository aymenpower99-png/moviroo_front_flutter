import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../../l10n/app_localizations.dart';

// ─── FORM FIELD ────────────────────────────────────────────────────────────────

class TicketFormField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLines;

  const TicketFormField({
    super.key,
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: AppTextStyles.bodyMedium(context),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.bodyMedium(context)
            .copyWith(color: AppColors.subtext(context)),
        filled: true,
        fillColor: AppColors.surface(context),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primaryPurple, width: 1.5),
        ),
      ),
    );
  }
}

// ─── CATEGORY SELECTOR ─────────────────────────────────────────────────────────
// Styled like the Pill widgets on the Plan Your Ride screen.
// Tapping opens a bottom sheet instead of a native dropdown.

class TicketCategorySelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final List<String> items;
  final String Function(String key) labelBuilder;

  const TicketCategorySelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.items,
    required this.labelBuilder,
  });

  void _openSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _CategorySelectorSheet(
        items: items,
        selectedKey: value,
        labelBuilder: labelBuilder,
        onSelect: (key) {
          Navigator.pop(ctx);
          onChanged(key);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openSelector(context),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.border(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                labelBuilder(value),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: AppColors.primaryPurple,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySelectorSheet extends StatelessWidget {
  final List<String> items;
  final String selectedKey;
  final String Function(String key) labelBuilder;
  final ValueChanged<String> onSelect;

  const _CategorySelectorSheet({
    required this.items,
    required this.selectedKey,
    required this.labelBuilder,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select Category',
              style: AppTextStyles.bodyLarge(context).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ...items.map((key) {
              final isSelected = key == selectedKey;
              return GestureDetector(
                onTap: () => onSelect(key),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryPurple.withValues(alpha: 0.08)
                        : AppColors.bg(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryPurple
                          : AppColors.border(context),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          labelBuilder(key),
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? AppColors.primaryPurple
                                : AppColors.text(context),
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primaryPurple,
                          size: 22,
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─── ATTACH FILES ──────────────────────────────────────────────────────────────

class TicketAttachFiles extends StatelessWidget {
  const TicketAttachFiles({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryPurple,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.photo_camera_outlined,
                    color: AppColors.primaryPurple, size: 26),
                SizedBox(width: 12),
                Icon(Icons.image_outlined,
                    color: AppColors.primaryPurple, size: 26),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              t.translate('attach_files_hint'),
              style: AppTextStyles.bodySmall(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SUBMIT BUTTON ─────────────────────────────────────────────────────────────

class TicketSubmitButton extends StatelessWidget {
  final VoidCallback onPressed;

  const TicketSubmitButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        icon: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
        label: Text(
          t.translate('submit_ticket_btn'),
          style: AppTextStyles.bodyMedium(context).copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}