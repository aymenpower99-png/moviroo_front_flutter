import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../theme/app_colors.dart';

class _Country {
  final String flag;
  final String code;
  final String dialCode;
  final int maxDigits;

  const _Country({
    required this.flag,
    required this.code,
    required this.dialCode,
    required this.maxDigits,
  });
}

const List<_Country> _kCountries = [
  _Country(flag: '🇹🇳', code: 'TN', dialCode: '+216', maxDigits: 8),
  _Country(flag: '🇩🇿', code: 'DZ', dialCode: '+213', maxDigits: 9),
  _Country(flag: '🇲🇦', code: 'MA', dialCode: '+212', maxDigits: 9),
  _Country(flag: '🇱🇾', code: 'LY', dialCode: '+218', maxDigits: 9),
  _Country(flag: '🇪🇬', code: 'EG', dialCode: '+20',  maxDigits: 10),
  _Country(flag: '🇫🇷', code: 'FR', dialCode: '+33',  maxDigits: 9),
  _Country(flag: '🇩🇪', code: 'DE', dialCode: '+49',  maxDigits: 11),
  _Country(flag: '🇬🇧', code: 'GB', dialCode: '+44',  maxDigits: 10),
  _Country(flag: '🇺🇸', code: 'US', dialCode: '+1',   maxDigits: 10),
  _Country(flag: '🇸🇦', code: 'SA', dialCode: '+966', maxDigits: 9),
  _Country(flag: '🇦🇪', code: 'AE', dialCode: '+971', maxDigits: 9),
  _Country(flag: '🇹🇷', code: 'TR', dialCode: '+90',  maxDigits: 10),
  _Country(flag: '🇮🇹', code: 'IT', dialCode: '+39',  maxDigits: 10),
  _Country(flag: '🇪🇸', code: 'ES', dialCode: '+34',  maxDigits: 9),
];

const Map<String, String> _kCountryNames = {
  'TN': 'Tunisia',  'DZ': 'Algeria',        'MA': 'Morocco',
  'LY': 'Libya',    'EG': 'Egypt',           'FR': 'France',
  'DE': 'Germany',  'GB': 'United Kingdom',  'US': 'United States',
  'SA': 'Saudi Arabia', 'AE': 'UAE',         'TR': 'Turkey',
  'IT': 'Italy',    'ES': 'Spain',
};

class NewPassengerModal {
  static Future<Map<String, String>?> show(
    BuildContext context, {
    Map<String, String>? initial,
  }) {
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _NewPassengerForm(initial: initial),
    );
  }
}

class _NewPassengerForm extends StatefulWidget {
  final Map<String, String>? initial;
  const _NewPassengerForm({this.initial});

  @override
  State<_NewPassengerForm> createState() => _NewPassengerFormState();
}

class _NewPassengerFormState extends State<_NewPassengerForm> {
  final _firstCtrl = TextEditingController();
  final _lastCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();

  _Country _country = _kCountries.first;

  bool get _isEdit  => widget.initial != null;
  bool get _canSave =>
      _firstCtrl.text.trim().isNotEmpty &&
      _phoneCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final parts = (widget.initial!['name'] ?? '').split(' ');
      _firstCtrl.text = parts.isNotEmpty ? parts.first : '';
      _lastCtrl.text  = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      final raw = widget.initial!['subtitle'] ?? '';
      _Country matched = _kCountries.first;
      String digits = raw;
      for (final c in _kCountries) {
        if (raw.startsWith('${c.dialCode} ')) {
          matched = c;
          digits  = raw.substring(c.dialCode.length + 1);
          break;
        }
      }
      _country = matched;
      _phoneCtrl.text = digits;
    }
    _firstCtrl.addListener(() => setState(() {}));
    _phoneCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _pickCountry() async {
    final picked = await showModalBottomSheet<_Country>(
      context: context,
      backgroundColor: AppColors.surface(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CountryPickerSheet(selected: _country),
    );
    if (picked != null) {
      setState(() {
        _country = picked;
        _phoneCtrl.clear();
      });
    }
  }

  void _submit() {
    final first    = _firstCtrl.text.trim();
    final last     = _lastCtrl.text.trim();
    final phone    = _phoneCtrl.text.trim();
    final fullName = last.isEmpty ? first : '$first $last';
    Navigator.pop<Map<String, String>>(context, {
      'name':     fullName,
      'subtitle': '${_country.dialCode} $phone',
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              _RoundedBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                size: 16,
                onTap: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  _isEdit ? 'Edit passenger' : 'New passenger',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text(context),
                  ),
                ),
              ),
              _RoundedBtn(
                icon: Icons.close_rounded,
                size: 18,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This name will be visible to drivers.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryPurple,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Changing it here won't affect your device contacts.",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryPurple.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _LabeledField(
            label: 'First name',
            hint: 'Ex. Ahmed',
            controller: _firstCtrl,
            capitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),

          _LabeledField(
            label: 'Last name',
            hint: 'Ex. Ben Ali',
            controller: _lastCtrl,
            capitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),

          // Phone field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phone number',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text(context),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border(context)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Country selector
                    GestureDetector(
                      onTap: _pickCountry,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.bg(context),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(11),
                            bottomLeft: Radius.circular(11),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _country.flag,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _country.dialCode,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text(context),
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: AppColors.subtext(context)),
                          ],
                        ),
                      ),
                    ),
                    Container(
                        width: 1,
                        height: 46,
                        color: AppColors.border(context)),
                    Expanded(
                      child: TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: AppColors.text(context)),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(
                              _country.maxDigits),
                        ],
                        decoration: InputDecoration(
                          hintText: 'XX XXX XXX',
                          hintStyle: TextStyle(
                              color: AppColors.subtext(context),
                              fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Disclaimer
          RichText(
            text: TextSpan(
              style: TextStyle(
                  fontSize: 12, color: AppColors.subtext(context)),
              children: [
                const TextSpan(text: 'By tapping '),
                TextSpan(
                  text: _isEdit ? "'Save changes'" : "'Add passenger'",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(
                  text: ', you confirm that this person has agreed to '
                      'share their contact information to receive ride updates.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // CTA
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _canSave ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                disabledBackgroundColor:
                    AppColors.primaryPurple.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                _isEdit ? 'Save changes' : 'Add passenger',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  final _Country selected;
  const _CountryPickerSheet({required this.selected});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  String _query = '';

  List<_Country> get _filtered => _kCountries.where((c) {
        final name = (_kCountryNames[c.code] ?? '').toLowerCase();
        final q    = _query.toLowerCase();
        return name.contains(q) ||
            c.code.toLowerCase().contains(q) ||
            c.dialCode.contains(_query);
      }).toList();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
              children: [
                // Drag handle
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Select country',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text(context),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: TextStyle(color: AppColors.text(context)),
                  decoration: InputDecoration(
                    hintText: 'Search country or dial code…',
                    hintStyle: TextStyle(
                        color: AppColors.subtext(context), fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: AppColors.subtext(context), size: 20),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: AppColors.border(context)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primaryPurple, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          Expanded(
            child: ListView.separated(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.border(context),
              ),
              itemBuilder: (_, i) {
                final c          = _filtered[i];
                final isSelected = c.code == widget.selected.code;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () => Navigator.pop(context, c),
                  leading: Text(c.flag,
                      style: const TextStyle(fontSize: 26)),
                  title: Text(
                    _kCountryNames[c.code] ?? c.code,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text(context),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        c.dialCode,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.subtext(context),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.primaryPurple, size: 18),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

// Renamed from _CircleBtn to _RoundedBtn — matches the rounded rectangle style
class _RoundedBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  const _RoundedBtn(
      {required this.icon, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.border(context),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: size, color: AppColors.text(context)),
        ),
      );
}

class _LabeledField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextCapitalization capitalization;
  const _LabeledField({
    required this.label,
    required this.hint,
    required this.controller,
    this.capitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            textCapitalization: capitalization,
            style: TextStyle(color: AppColors.text(context)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  color: AppColors.subtext(context), fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppColors.primaryPurple, width: 1.5),
              ),
            ),
          ),
        ],
      );
}