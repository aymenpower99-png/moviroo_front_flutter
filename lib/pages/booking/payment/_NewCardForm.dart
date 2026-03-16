import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';

class NewCardForm extends StatefulWidget {
  final VoidCallback? onSaved;
  final VoidCallback? onBackToSaved;
  const NewCardForm({super.key, this.onSaved, this.onBackToSaved});

  @override
  State<NewCardForm> createState() => NewCardFormState();
}

class NewCardFormState extends State<NewCardForm> {
  final nameController = TextEditingController();
  final cardController = TextEditingController();
  final expiryController = TextEditingController();

  bool _nameError = false;
  bool _cardError = false;
  bool _expiryError = false;
  bool _saveCard = false;

  @override
  void dispose() {
    nameController.dispose();
    cardController.dispose();
    expiryController.dispose();
    super.dispose();
  }

  /// Returns true if all fields are valid. Call before payment.
  bool validate() {
    setState(() {
      _nameError = nameController.text.trim().isEmpty;
      _cardError = cardController.text.replaceAll(' ', '').length < 16;
      _expiryError = expiryController.text.trim().length < 5;
    });
    return !_nameError && !_cardError && !_expiryError;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.credit_card_outlined,
                  color: AppColors.primaryPurple, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('CARD DETAILS',
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.subtext(context),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontSize: 11,
                    )),
              ),
              if (widget.onBackToSaved != null)
                GestureDetector(
                  onTap: widget.onBackToSaved,
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back_ios_rounded,
                          size: 12, color: AppColors.primaryPurple),
                      const SizedBox(width: 2),
                      Text('Saved card',
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: AppColors.primaryPurple,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          )),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Cardholder name ────────────────────────────────
          _FieldLabel(label: 'Cardholder name'),
          const SizedBox(height: 6),
          _CardField(
            controller: nameController,
            hint: 'John Doe',
            inputType: TextInputType.name,
            hasError: _nameError,
            errorText: 'Name is required',
            onChanged: (_) {
              if (_nameError) setState(() => _nameError = false);
            },
          ),
          const SizedBox(height: 14),

          // ── Card number ────────────────────────────────────
          _FieldLabel(label: 'Card number'),
          const SizedBox(height: 6),
          _CardField(
            controller: cardController,
            hint: '4242 4242 4242 4242',
            inputType: TextInputType.number,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              _CardNumberFormatter(),
            ],
            maxLength: 19,
            hasError: _cardError,
            errorText: 'Enter a valid 16-digit card number',
            onChanged: (_) {
              if (_cardError) setState(() => _cardError = false);
            },
          ),
          const SizedBox(height: 14),

          // ── Expiry (half width) ────────────────────────────
          SizedBox(
            width: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel(label: 'Expiry date'),
                const SizedBox(height: 6),
                _CardField(
                  controller: expiryController,
                  hint: 'MM/YY',
                  inputType: TextInputType.number,
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ExpiryFormatter(),
                  ],
                  maxLength: 5,
                  hasError: _expiryError,
                  errorText: 'Required',
                  onChanged: (_) {
                    if (_expiryError) setState(() => _expiryError = false);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Save card toggle ───────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _saveCard = !_saveCard),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _saveCard
                          ? AppColors.primaryPurple
                          : AppColors.border(context),
                      width: 2,
                    ),
                    color: _saveCard
                        ? AppColors.primaryPurple
                        : Colors.transparent,
                  ),
                  child: _saveCard
                      ? const Icon(Icons.check_rounded,
                          size: 12, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                Icon(Icons.save_outlined,
                    size: 16, color: AppColors.subtext(context)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Save this card for next time',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall(context),
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

// ── Helpers ───────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: AppTextStyles.bodySmall(context)
            .copyWith(color: AppColors.subtext(context)));
  }
}

class _CardField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType inputType;
  final bool obscure;
  final List<TextInputFormatter>? formatters;
  final int? maxLength;
  final bool hasError;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const _CardField({
    required this.controller,
    required this.hint,
    this.inputType = TextInputType.text,
    this.obscure = false,
    this.formatters,
    this.maxLength,
    this.hasError = false,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: inputType,
          obscureText: obscure,
          maxLength: maxLength,
          inputFormatters: formatters,
          onChanged: onChanged,
          style: AppTextStyles.bodyMedium(context),
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            hintStyle: AppTextStyles.bodyMedium(context)
                .copyWith(color: AppColors.subtext(context)),
            filled: true,
            fillColor: AppColors.bg(context),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: hasError ? Colors.red : AppColors.border(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: hasError ? Colors.red : AppColors.border(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: hasError ? Colors.red : AppColors.primaryPurple,
                  width: 2),
            ),
          ),
        ),
        if (hasError && errorText != null) ...[
          const SizedBox(height: 4),
          Text(errorText!,
              style: AppTextStyles.bodySmall(context)
                  .copyWith(color: Colors.red, fontSize: 11)),
        ],
      ],
    );
  }
}

// ── Formatters ────────────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    final text = next.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    final string = buffer.toString();
    return next.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    var text = next.text.replaceAll('/', '');
    if (text.length > 2) {
      text = '${text.substring(0, 2)}/${text.substring(2)}';
    }
    return next.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}