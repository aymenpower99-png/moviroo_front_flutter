import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Phone Field Tile (with flag + +216 prefix)
// ─────────────────────────────────────────────────────────────────────────────

class PhoneFieldTile extends StatefulWidget {
  final String label;
  final TextEditingController controller;

  const PhoneFieldTile({
    super.key,
    required this.label,
    required this.controller,
  });

  @override
  State<PhoneFieldTile> createState() => _PhoneFieldTileState();
}

class _PhoneFieldTileState extends State<PhoneFieldTile> {
  late final FocusNode _focus;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()
      ..addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border(context), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: AppTextStyles.settingsItemValue(context).copyWith(
              color: _focused
                  ? AppColors.primaryPurple
                  : AppColors.subtext(context),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Image.asset(
                'images/flags/tunisia.png',
                width: 24,
                height: 16,
                fit: BoxFit.cover,
              ),
              const SizedBox(width: 8),
              Text(
                '+216',
                style: AppTextStyles.settingsItem(
                  context,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focus,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  cursorColor: AppColors.primaryPurple,
                  style: AppTextStyles.settingsItem(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    hintText: '12345678',
                    hintStyle: AppTextStyles.settingsItem(context).copyWith(
                      color: AppColors.subtext(context).withValues(alpha: 0.4),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              if (_focused)
                const Icon(
                  Icons.edit_rounded,
                  color: AppColors.primaryPurple,
                  size: 14,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Bar
// ─────────────────────────────────────────────────────────────────────────────

class PersonalDataTopBar extends StatelessWidget {
  final VoidCallback onBack;

  const PersonalDataTopBar({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Icon(
              Icons.chevron_left_rounded,
              color: AppColors.text(context),
              size: 22,
            ),
          ),
        ),
        Expanded(
          child: Text(
            t('personal_data_title'),
            textAlign: TextAlign.center,
            style: AppTextStyles.pageTitle(context),
          ),
        ),
        const SizedBox(width: 36),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar Section
// ─────────────────────────────────────────────────────────────────────────────

class AvatarSection extends StatelessWidget {
  final String letter;

  const AvatarSection({super.key, required this.letter});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryPurple, width: 2.5),
      ),
      child: ClipOval(
        child: Container(
          color: isDark ? const Color(0xFF2A1A3E) : const Color(0xFFEDE7F6),
          child: Center(
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryPurple,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Field Card + Section Label
// ─────────────────────────────────────────────────────────────────────────────

class FieldCard extends StatelessWidget {
  final List<Widget> children;

  const FieldCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(children: children),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.sectionLabel(context));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Field Tile
// ─────────────────────────────────────────────────────────────────────────────

class FieldTile extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const FieldTile({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
  });

  @override
  State<FieldTile> createState() => _FieldTileState();
}

class _FieldTileState extends State<FieldTile> {
  late final FocusNode _focus;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()
      ..addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border(context), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: AppTextStyles.settingsItemValue(context).copyWith(
              color: _focused
                  ? AppColors.primaryPurple
                  : AppColors.subtext(context),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focus,
                  keyboardType: widget.keyboardType,
                  inputFormatters: widget.inputFormatters,
                  validator: widget.validator,
                  cursorColor: AppColors.primaryPurple,
                  style: AppTextStyles.settingsItem(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    hintText:
                        '${t('add_prefix')} ${widget.label.toLowerCase()}',
                    hintStyle: AppTextStyles.settingsItem(context).copyWith(
                      color: AppColors.subtext(context).withValues(alpha: 0.4),
                      fontWeight: FontWeight.w400,
                    ),
                    errorStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
              if (_focused)
                const Icon(
                  Icons.edit_rounded,
                  color: AppColors.primaryPurple,
                  size: 14,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
