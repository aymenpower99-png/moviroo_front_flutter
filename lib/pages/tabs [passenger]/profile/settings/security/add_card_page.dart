import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../services/ride_api/booking_api_service.dart';
import '../../../../../services/stripe/stripe_service.dart';

class AddCardPage extends StatefulWidget {
  const AddCardPage({super.key});

  @override
  State<AddCardPage> createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  bool _isLoading = false;
  final _bookingApi = BookingApiService();

  Future<void> _handleAdd() async {
    setState(() => _isLoading = true);
    try {
      // 1. Create SetupIntent on backend (creates Stripe customer if needed)
      final data = await _bookingApi.createSetupIntent();
      final setupSecret = data['setupIntentClientSecret'] as String?;
      final customerId = data['customerId'] as String?;
      final ephemeralKey = data['ephemeralKey'] as String?;

      if (setupSecret == null || customerId == null || ephemeralKey == null) {
        throw Exception('Invalid setup intent response');
      }

      // 2. Present Stripe PaymentSheet in setup mode — validates card without charging
      await StripeService.presentSetupSheet(
        setupIntentClientSecret: setupSecret,
        customerId: customerId,
        ephemeralKey: ephemeralKey,
      );

      // 3. Card saved successfully
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context).translate('card_added_successfully'),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: AppColors.primaryPurple,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
      // Return true so the list page knows to reload
      Navigator.pop(context, true);
    } on StripeException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final msg = e.error.localizedMessage ?? 'Card setup cancelled';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add card: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _SubPageTopBar(title: t('add_new_card')),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),

                    // ── Icon ──
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: AppColors.purpleGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.credit_card_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Title ──
                    Center(
                      child: Text(
                        t('add_card_securely'),
                        style: AppTextStyles.pageTitle(context),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        t('add_card_description'),
                        style: AppTextStyles.bodySmall(context).copyWith(
                          color: AppColors.subtext(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ── Security badges ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SecurityBadge(
                          icon: Icons.lock_rounded,
                          label: t('secure_encrypted'),
                        ),
                        const SizedBox(width: 20),
                        _SecurityBadge(
                          icon: Icons.verified_rounded,
                          label: t('stripe_protected'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // ── Add Card button ──
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
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.add_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(t('add_card'), style: AppTextStyles.buttonPrimary),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        t('powered_by_stripe'),
                        style: AppTextStyles.bodySmall(context).copyWith(
                          color: AppColors.subtext(context),
                          fontSize: 12,
                        ),
                      ),
                    ),
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

// ── Security Badge ─────────────────────────────────────────────────────────────

class _SecurityBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SecurityBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primaryPurple, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTextStyles.bodySmall(context).copyWith(fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
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
              child: Icon(
                Icons.chevron_left_rounded,
                size: 22,
                color: AppColors.text(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.pageTitle(context),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}
