import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';

class SavedCardSection extends StatefulWidget {
  final VoidCallback onUseNewCard;
  /// Called with the entered CVV when the section is ready to pay.
  /// The parent reads [cvvController] directly via the global key, or use the
  /// [cvvValid] getter exposed via [SavedCardSectionState].
  const SavedCardSection({super.key, required this.onUseNewCard});

  @override
  State<SavedCardSection> createState() => SavedCardSectionState();
}

class SavedCardSectionState extends State<SavedCardSection> {
  final cvvController = TextEditingController();
  bool _cvvError = false;

  @override
  void dispose() {
    cvvController.dispose();
    super.dispose();
  }

  /// Returns true if CVV is valid (3 digits). Call before payment.
  bool validate() {
    final valid = cvvController.text.trim().length == 3;
    setState(() => _cvvError = !valid);
    return valid;
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
          Text('SAVED CARD',
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.subtext(context),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                fontSize: 11,
              )),
          const SizedBox(height: 12),

          // ── Card row ───────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.primaryPurple.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.credit_card_rounded,
                      color: AppColors.primaryPurple, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('•••• •••• •••• 4444',
                      style: AppTextStyles.bodyMedium(context).copyWith(
                          fontWeight: FontWeight.w700, letterSpacing: 1)),
                ),
                Icon(Icons.check_circle_rounded,
                    color: AppColors.primaryPurple, size: 20),
                const SizedBox(width: 8),
                Icon(Icons.delete_outline_rounded,
                    color: AppColors.subtext(context), size: 20),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── CVV inline ─────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CVV',
                      style: AppTextStyles.bodySmall(context)
                          .copyWith(color: AppColors.subtext(context))),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: cvvController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 3,
                      onChanged: (_) {
                        if (_cvvError) setState(() => _cvvError = false);
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: AppTextStyles.bodyLarge(context)
                          .copyWith(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: '123',
                        counterText: '',
                        hintStyle: AppTextStyles.bodyMedium(context)
                            .copyWith(
                                color: AppColors.subtext(context)),
                        filled: true,
                        fillColor: AppColors.bg(context),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: _cvvError
                                  ? Colors.red
                                  : AppColors.border(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: _cvvError
                                  ? Colors.red
                                  : AppColors.border(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: _cvvError
                                  ? Colors.red
                                  : AppColors.primaryPurple,
                              width: 2),
                        ),
                      ),
                    ),
                  ),
                  if (_cvvError) ...[
                    const SizedBox(height: 4),
                    Text('CVV is required',
                        style: AppTextStyles.bodySmall(context)
                            .copyWith(color: Colors.red, fontSize: 11)),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Use new card ───────────────────────────────────
          GestureDetector(
            onTap: widget.onUseNewCard,
            child: Text(
              'Use a different card',
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}