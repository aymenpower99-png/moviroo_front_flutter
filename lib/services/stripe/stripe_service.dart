import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

/// Stripe service — handles PaymentSheet and SetupSheet presentation.
/// Payment intent creation and saved-card management are handled server-side
/// via [BookingApiService].
class StripeService {
  static const String _publishableKey =
      'pk_test_51TQUuDPm6vo1FQzebQQuzSCCFgFwVE7UVwNb211WGYVuXGoFmKX1IG5Nylu9P4JuwnNAP3PW9u5u5YedZj44M9x100bg4KmXGE';

  static bool _initialized = false;

  /// Lazy initialisation — safe to call multiple times.
  static Future<void> initialize() async {
    if (_initialized) return;
    Stripe.publishableKey = _publishableKey;
    await Stripe.instance.applySettings();
    _initialized = true;
  }

  /// Present the Stripe PaymentSheet for a given [clientSecret].
  ///
  /// Pass [customerId] and [ephemeralKey] to show saved cards inside the sheet.
  static Future<void> presentPaymentSheet(
    String clientSecret, {
    String? customerId,
    String? ephemeralKey,
  }) async {
    await initialize();
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Moviroo',
        style: ThemeMode.system,
        customerId: customerId?.isNotEmpty == true ? customerId : null,
        customerEphemeralKeySecret:
            ephemeralKey?.isNotEmpty == true ? ephemeralKey : null,
      ),
    );
    await Stripe.instance.presentPaymentSheet();
  }

  /// Present the Stripe PaymentSheet in SetupIntent mode to save a card
  /// without charging it.
  static Future<void> presentSetupSheet({
    required String setupIntentClientSecret,
    required String customerId,
    required String ephemeralKey,
  }) async {
    await initialize();
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        setupIntentClientSecret: setupIntentClientSecret,
        merchantDisplayName: 'Moviroo',
        style: ThemeMode.system,
        customerId: customerId,
        customerEphemeralKeySecret: ephemeralKey,
      ),
    );
    await Stripe.instance.presentPaymentSheet();
  }
}

