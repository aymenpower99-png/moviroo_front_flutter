import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import 'saved_places_model.dart';

class AddPlacePage extends StatefulWidget {
  final SavedPlace? existing;

  const AddPlacePage({super.key, this.existing});

  @override
  State<AddPlacePage> createState() => _AddPlacePageState();
}

class _AddPlacePageState extends State<AddPlacePage> {
  late final TextEditingController _labelCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _provinceCtrl;
  late final TextEditingController _zipCtrl;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _labelCtrl    = TextEditingController(text: e?.label ?? '');
    _addressCtrl  = TextEditingController(text: e?.address ?? '');
    _cityCtrl     = TextEditingController(text: e?.city ?? '');
    _provinceCtrl = TextEditingController(text: e?.province ?? '');
    _zipCtrl      = TextEditingController(text: e?.zipCode ?? '');
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _provinceCtrl.dispose();
    _zipCtrl.dispose();
    super.dispose();
  }

  bool get _canSave => _addressCtrl.text.trim().isNotEmpty;

  void _save() {
    if (!_canSave) return;
    final place = SavedPlace(
      id: widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      label: _labelCtrl.text.trim().isEmpty
          ? SavedPlaceType.favorite.defaultLabel
          : _labelCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      province: _provinceCtrl.text.trim(),
      zipCode: _zipCtrl.text.trim(),
      type: widget.existing?.type ?? SavedPlaceType.favorite,
    );
    Navigator.pop(context, place);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top bar ────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
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
                      _isEdit ? 'Edit address' : 'New address',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.pageTitle(context),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),

            // ── Form ───────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Label ──────────────────────────────────────
                    _SectionLabel('Label (optional)'),
                    const SizedBox(height: 8),
                    _InputField(
                      controller: _labelCtrl,
                      hint: 'e.g. Gym, Parents…',
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: 20),

                    // ── Address ────────────────────────────────────
                    _SectionLabel('Address'),
                    const SizedBox(height: 8),
                    _InputField(
                      controller: _addressCtrl,
                      hint: 'Street address',
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: 20),

                    // ── City + Province ────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionLabel('City'),
                              const SizedBox(height: 8),
                              _InputField(
                                controller: _cityCtrl,
                                hint: 'City',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionLabel('Province / State'),
                              const SizedBox(height: 8),
                              _InputField(
                                controller: _provinceCtrl,
                                hint: 'Province',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── ZIP ────────────────────────────────────────
                    _SectionLabel('ZIP / Postal code'),
                    const SizedBox(height: 8),
                    _InputField(
                      controller: _zipCtrl,
                      hint: 'Postal code',
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 36),

                    // ── Save button ────────────────────────────────
                    GestureDetector(
                      onTap: _canSave ? _save : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                        
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                
                            SizedBox(width: 8),
                            Text(
                              'Save',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // bottom safe area padding
                    SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.sectionLabel(context));
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: AppTextStyles.settingsItem(context),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodySmall(context),
        filled: true,
        fillColor: AppColors.surface(context),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primaryPurple, width: 1.5),
        ),
      ),
    );
  }
}