import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '_SummaryCard.dart';
import '../../tabs [passenger]/profile/saved_places/saved_places_model.dart';

class BillingAddressSection extends StatefulWidget {
  const BillingAddressSection({super.key});

  @override
  State<BillingAddressSection> createState() => BillingAddressSectionState();
}

class BillingAddressSectionState extends State<BillingAddressSection> {
  final List<SavedPlace> _savedPlaces = [
    SavedPlace(
      id: '1',
      label: 'Home',
      address: '12 Rue de la Liberté',
      city: 'Tunis',
      province: 'Tunis',
      zipCode: '1001',
      type: SavedPlaceType.home,
    ),
  ];

  String? _selectedId   = '1';
  bool    _newSelected  = false;
  bool    _saveToProfile = false;

  final _lastNameCtrl = TextEditingController();
  final _addressCtrl  = TextEditingController();
  final _cityCtrl     = TextEditingController();
  final _provinceCtrl = TextEditingController();
  final _zipCtrl      = TextEditingController();
  final _taxIdCtrl    = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  bool validateAndProceed() {
    if (!_newSelected && _selectedId != null) return true;
    if (_newSelected) {
      final valid = _formKey.currentState?.validate() ?? false;
      if (!valid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please fill in all required address fields.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primaryPurple,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return valid;
    }
    return false;
  }

  @override
  void dispose() {
    _lastNameCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _provinceCtrl.dispose();
    _zipCtrl.dispose();
    _taxIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ──────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.location_city_outlined,
                  color: AppColors.primaryPurple, size: 18),
              const SizedBox(width: 8),
              Text(
                'Billing address',
                style: AppTextStyles.bodyMedium(context)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              children: [

                // ── Saved places ────────────────────────────────
                ..._savedPlaces.asMap().entries.map((entry) {
                  final index      = entry.key;
                  final place      = entry.value;
                  final isSelected = !_newSelected && _selectedId == place.id;

                  return _RadioTile(
                    isSelected: isSelected,
                    isFirst: index == 0,
                    isLast: false,
                    onTap: () => setState(() {
                      _selectedId  = place.id;
                      _newSelected = false;
                    }),
                    title: place.label,
                    subtitle: place.subtitle,
                  );
                }),

                Divider(height: 1, color: AppColors.border(context)),

                // ── New billing address row ──────────────────────
                _RadioTile(
                  isSelected: _newSelected,
                  isFirst: false,
                  isLast: !_newSelected,
                  onTap: () => setState(() {
                    _newSelected = true;
                    _selectedId  = null;
                  }),
                  title: 'New billing address',
                ),

                // ── Inline form ──────────────────────────────────
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 220),
                  crossFadeState: _newSelected
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Container(
                    decoration: BoxDecoration(
                      color: AppColors.bg(context),
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16)),
                      border: Border(
                        top: BorderSide(color: AppColors.border(context)),
                      ),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Field(
                            controller: _lastNameCtrl,
                            hint: 'Last name',
                            icon: Icons.person_outline_rounded,
                            required: true,
                          ),
                          const SizedBox(height: 10),
                          _Field(
                            controller: _addressCtrl,
                            hint: 'Address',
                            icon: Icons.signpost_outlined,
                            required: true,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _Field(
                                  controller: _cityCtrl,
                                  hint: 'City',
                                  icon: Icons.location_city_outlined,
                                  required: true,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _Field(
                                  controller: _provinceCtrl,
                                  hint: 'Province/State',
                                  icon: Icons.map_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _Field(
                            controller: _zipCtrl,
                            hint: 'ZIP/Postal code',
                            icon: Icons.markunread_mailbox_outlined,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 10),
                          _Field(
                            controller: _taxIdCtrl,
                            hint: 'Tax ID (if required)',
                            icon: Icons.badge_outlined,
                          ),
                          const SizedBox(height: 14),

                          // ── Save to profile ────────────────────
                          GestureDetector(
                            onTap: () => setState(
                                () => _saveToProfile = !_saveToProfile),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: _saveToProfile
                                          ? AppColors.primaryPurple
                                          : AppColors.border(context),
                                      width: 1.5,
                                    ),
                                    color: _saveToProfile
                                        ? AppColors.primaryPurple
                                        : Colors.transparent,
                                  ),
                                  child: _saveToProfile
                                      ? const Icon(Icons.check_rounded,
                                          size: 14, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Save this address to profile',
                                  style: AppTextStyles.bodyMedium(context),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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

// ── Radio tile ─────────────────────────────────────────────────────────────────

class _RadioTile extends StatelessWidget {
  final bool isSelected;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;
  final String title;
  final String? subtitle;

  const _RadioTile({
    required this.isSelected,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryPurple.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.vertical(
            top:    isFirst ? const Radius.circular(16) : Radius.zero,
            bottom: isLast  ? const Radius.circular(16) : Radius.zero,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryPurple
                      : AppColors.border(context),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primaryPurple : null,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: AppTextStyles.bodySmall(context)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Text field ─────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool required;
  final TextInputType keyboardType;

  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.required = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMedium(context)
            .copyWith(color: AppColors.subtext(context)),
        prefixIcon: Icon(icon, size: 18, color: AppColors.subtext(context)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AppColors.primaryPurple, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.surface(context),
      ),
    );
  }
}