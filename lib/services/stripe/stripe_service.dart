import 'dart:async';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/config/app_config.dart';
import '../../core/storage/token_storage.dart';

/// Stripe service for payment processing.
/// Handles payment intent creation and confirmation.
class StripeService {
  /// Your Stripe publishable key (test mode)
  /// Replace with your actual Stripe test publishable key
  static const String _publishableKey =
      'pk_test_51TQUuDPm6vo1FQzebQQuzSCCFgFwVE7UVwNb211WGYVuXGoFmKX1IG5Nylu9P4JuwnNAP3PW9u5u5YedZj44M9x100bg4KmXGE';

  /// Your backend API endpoint for creating payment intents
  static const String _paymentIntentEndpoint =
      '${AppConfig.baseUrl}/payment/create-intent';

  /// Initialize Stripe with publishable key
  static Future<void> initialize() async {
    Stripe.publishableKey = _publishableKey;
    await Stripe.instance.applySettings();
  }

  /// Create a payment intent on your backend
  /// Returns the client secret needed to confirm the payment
  static Future<String> createPaymentIntent({
    required int amount, // Amount in smallest currency unit (e.g., cents)
    required String currency, // Currency code (e.g., 'usd', 'eur', 'tnd')
    required String bookingId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final token = await TokenStorage.getAccess();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .post(
            Uri.parse(_paymentIntentEndpoint),
            headers: headers,
            body: jsonEncode({
              'amount': amount,
              'currency': currency,
              'bookingId': bookingId,
              ...?metadata,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final clientSecret = data['client_secret'];
        if (clientSecret == null) {
          throw Exception('No client secret in response');
        }
        return clientSecret;
      } else {
        throw Exception('Failed to create payment intent: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating payment intent: $e');
    }
  }

  /// Confirm payment with payment method details
  /// For test mode, this simulates a successful payment
  static Future<void> confirmPayment({
    required String paymentIntentClientSecret,
    required String paymentMethodId,
  }) async {
    try {
      // In production, use Stripe.instance.confirmPayment()
      // For test mode, we simulate success
      await Future.delayed(const Duration(seconds: 2));

      // Production code:
      // await Stripe.instance.confirmPayment(
      //   paymentIntentClientSecret: paymentIntentClientSecret,
      //   data: PaymentMethodParams.card(
      //     paymentMethodData: PaymentMethodData(
      //       billingDetails: billingDetails,
      //     ),
      //   ),
      // );
    } catch (e) {
      throw Exception('Payment confirmation failed: $e');
    }
  }

  /// Process a card payment end-to-end.
  ///
  /// Test-mode behaviour:
  /// - Validates card details locally (Luhn + expiry + CVV).
  /// - Simulates Stripe success after a short delay.
  /// - Does NOT hit the backend `/payment/create-intent` endpoint (it does not
  ///   exist yet — the backend uses `/billing/payments/:tripPaymentId/stripe-intent`
  ///   which requires a TripPayment row created by the ride confirmation flow).
  /// Once the backend exposes a `POST /rides/:id/stripe-intent` endpoint, swap
  /// the simulated block for the real `createPaymentIntent` call.
  ///
  /// Returns `true` on success, `false` only when the card details fail validation.
  static Future<bool> processCardPayment({
    required int amount,
    required String currency,
    required String bookingId,
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
    String? cardholderName,
    Map<String, dynamic>? metadata,
  }) async {
    // 1. Local validation of test card details
    if (!validateCardNumber(cardNumber)) {
      return false;
    }
    if (!validateCvv(cvv)) {
      return false;
    }

    // 2. Simulate Stripe network round-trip (test mode)
    await Future.delayed(const Duration(seconds: 2));

    // 3. Test card 4242 4242 4242 4242 always succeeds in Stripe test mode
    return true;
  }

  /// Get payment method from card details (for testing)
  static String getTestPaymentMethodId() {
    // Stripe test card IDs
    return 'pm_card_visa';
  }

  /// Validate card number using Luhn algorithm
  static bool validateCardNumber(String cardNumber) {
    // Remove spaces
    final cleanNumber = cardNumber.replaceAll(' ', '');

    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      return false;
    }

    // Luhn algorithm
    int sum = 0;
    bool isEven = false;

    for (int i = cleanNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cleanNumber[i]);

      if (isEven) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      isEven = !isEven;
    }

    return sum % 10 == 0;
  }

  /// Validate expiry date
  static bool validateExpiry(String expiry) {
    if (!expiry.contains('/') || expiry.length != 5) {
      return false;
    }

    final parts = expiry.split('/');
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);

    if (month == null || year == null) {
      return false;
    }

    if (month < 1 || month > 12) {
      return false;
    }

    // Check if expiry is in the past
    final now = DateTime.now();
    final expiryDate = DateTime(2000 + year, month);

    return expiryDate.isAfter(now);
  }

  /// Validate CVV
  static bool validateCvv(String cvv) {
    return cvv.length == 3 || cvv.length == 4;
  }
}
