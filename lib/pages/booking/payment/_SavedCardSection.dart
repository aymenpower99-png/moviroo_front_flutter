import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';

class SavedCardSection extends StatefulWidget {
  final VoidCallback onUseNewCard;
  final List<Map<String, dynamic>> savedCards;
  final Function(String)? onDeleteCard;
  const SavedCardSection({
    super.key,
    required this.onUseNewCard,
    this.savedCards = const [],
    this.onDeleteCard,
  });

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

  bool validate() {
    final valid = cvvController.text.trim().length == 3;
    setState(() => _cvvError = !valid);
    return valid;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

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
          Text(
            t.translate('saved_card_title'),
            style: AppTextStyles.bodySmall(context).copyWith(
              color: AppColors.subtext(context),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),

          // ── Saved cards list ─────────────────────────────────
          if (widget.savedCards.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No saved cards',
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(color: AppColors.subtext(context)),
                ),
              ),
            )
          else
            ...widget.savedCards.map((card) {
              final lastFour = card['lastFour'] as String;
              final token = card['token'] as String;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primaryPurple.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.credit_card_rounded,
                        color: AppColors.primaryPurple,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '•••• •••• •••• $lastFour',
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primaryPurple,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        if (widget.onDeleteCard != null) {
                          widget.onDeleteCard!(token);
                        }
                      },
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.subtext(context),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

          const SizedBox(height: 16),

          // ── CVV inline ─────────────────────────────────────
          if (widget.savedCards.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.translate('cvv'),
                      style: AppTextStyles.bodySmall(
                        context,
                      ).copyWith(color: AppColors.subtext(context)),
                    ),
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
                        style: AppTextStyles.bodyLarge(
                          context,
                        ).copyWith(fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: '123',
                          counterText: '',
                          hintStyle: AppTextStyles.bodyMedium(
                            context,
                          ).copyWith(color: AppColors.subtext(context)),
                          filled: true,
                          fillColor: AppColors.bg(context),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _cvvError
                                  ? Colors.red
                                  : AppColors.border(context),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _cvvError
                                  ? Colors.red
                                  : AppColors.border(context),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _cvvError
                                  ? Colors.red
                                  : AppColors.primaryPurple,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_cvvError) ...[
                      const SizedBox(height: 4),
                      Text(
                        t.translate('error_cvv_required'),
                        style: AppTextStyles.bodySmall(
                          context,
                        ).copyWith(color: Colors.red, fontSize: 11),
                      ),
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
              t.translate('use_different_card'),
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
