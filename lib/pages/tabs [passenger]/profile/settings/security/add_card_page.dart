// TODO Implement this library.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../../l10n/app_localizations.dart';
import 'payment_method_page.dart';

class AddCardPage extends StatefulWidget {
  const AddCardPage({super.key});

  @override
  State<AddCardPage> createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  final _holderController = TextEditingController();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _saveCard = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _holderController.dispose();
    _numberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  CardType _detectType(String number) {
    final n = number.replaceAll(' ', '');
    if (n.startsWith('4')) return CardType.visa;
    if (n.startsWith('5')) return CardType.mastercard;
    if (n.startsWith('3')) return CardType.amex;
    return CardType.other;
  }

  Future<void> _handleAdd() async {
    final number = _numberController.text.replaceAll(' ', '');
    if (number.length < 4) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800)); // TODO: real API

    final card = PaymentCard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      holder: _holderController.text.isEmpty ? 'Card Holder' : _holderController.text,
      last4: number.substring(number.length - 4),
      expiry: _expiryController.text.isEmpty ? '--/--' : _expiryController.text,
      type: _detectType(number),
    );

    if (mounted) Navigator.pop(context, card);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _SubPageTopBar(title: t('Add New Card')),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── Section label ──
                    Text(
                      t('CARD DETAILS').toUpperCase(),
                      style: AppTextStyles.sectionLabel(context),
                    ),
                    const SizedBox(height: 16),

                    // ── Card holder ──
                    _CardField(
                      controller: _holderController,
                      label: t('Card Holder Name'),
                      hint: t('John Doe'),
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: 14),

                    // ── Card number ──
                    _CardField(
                      controller: _numberController,
                      label: t('Card Number'),
                      hint: '0000 0000 0000 0000',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _CardNumberFormatter(),
                      ],
                      maxLength: 19,
                    ),
                    const SizedBox(height: 14),

                    // ── Expiry + CVV ──
                    Row(
                      children: [
                        Expanded(
                          child: _CardField(
                            controller: _expiryController,
                            label: t('Expiry'),
                            hint: 'MM/YY',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              _ExpiryFormatter(),
                            ],
                            maxLength: 5,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _CardField(
                            controller: _cvvController,
                            label: t('CVV'),
                            hint: '•••',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            maxLength: 4,
                            obscure: true,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Save card checkbox ──
                    GestureDetector(
                      onTap: () => setState(() => _saveCard = !_saveCard),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              gradient: _saveCard ? AppColors.purpleGradient : null,
                              color: _saveCard ? null : Colors.transparent,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: _saveCard
                                    ? AppColors.primaryPurple
                                    : AppColors.border(context),
                              ),
                            ),
                            child: _saveCard
                                ? const Icon(Icons.check,
                                    size: 13, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            t('Save card for future payments'),
                            style: AppTextStyles.bodyMedium(context),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Add button ──
                    GestureDetector(
                      onTap: _isLoading ? null : _handleAdd,
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: AppColors.purpleGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(t('Add Card'),
                                style: AppTextStyles.buttonPrimary),
                      ),
                    ),

                    const SizedBox(height: 24),
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

// ── Card Field ────────────────────────────────────────────────────────────────

class _CardField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final bool obscure;

  const _CardField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.maxLength,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySmall(context)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          obscureText: obscure,
          cursorColor: AppColors.subtext(context),
          style: AppTextStyles.settingsItem(context),
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            hintStyle: AppTextStyles.bodySmall(context),
            filled: true,
            fillColor: AppColors.surface(context),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Input Formatters ──────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final result = buffer.toString();
    return newValue.copyWith(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('/', '');
    String result = digits;
    if (digits.length >= 3) {
      result = '${digits.substring(0, 2)}/${digits.substring(2)}';
    }
    return newValue.copyWith(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────

class _SubPageTopBar extends StatelessWidget {
  final String title;
  const _SubPageTopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: AppColors.subtext(context)),
            ),
          ),
          Expanded(
            child: Text(title,
                textAlign: TextAlign.center,
                style: AppTextStyles.pageTitle(context)),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}