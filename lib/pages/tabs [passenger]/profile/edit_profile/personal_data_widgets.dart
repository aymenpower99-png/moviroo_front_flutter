import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';

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
            child: Icon(Icons.chevron_left_rounded,
                color: AppColors.text(context), size: 22),
          ),
        ),
        Expanded(
          child: Text(
            t('personal_data'),
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
  const AvatarSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFBB6BD9), AppColors.primaryPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2.5),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.iconBg(context),
                  ),
                  child: ClipOval(
                    child: Icon(
                      Icons.person,
                      color: AppColors.primaryPurple,
                      size: 52,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.bg(context), width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  color: Colors.white, size: 14),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(t('profile_photo'), style: AppTextStyles.profileName(context)),
        const SizedBox(height: 4),
        Text(t('tap_to_change_photo'),
            style: AppTextStyles.bodySmall(context)),
      ],
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
  final String translationKey;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const FieldTile({
    super.key,
    required this.label,
    required this.translationKey,
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
    final label = t(widget.translationKey);

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
            label,
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
                  style: AppTextStyles.settingsItem(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    hintText: t('add_field')
                        .replaceAll('{field}', label.toLowerCase()),
                    hintStyle: AppTextStyles.settingsItem(context).copyWith(
                      color:
                          AppColors.subtext(context).withValues(alpha: 0.4),
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
                const Icon(Icons.edit_rounded,
                    color: AppColors.primaryPurple, size: 14),
            ],
          ),
        ],
      ),
    );
  }
}