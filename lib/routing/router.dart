import 'package:flutter/material.dart';
import 'package:moviroo/pages/booking/CarInformation/booking.dart';
import 'package:moviroo/pages/booking/RideDetailsPage/ride_details_page.dart';
import 'package:moviroo/pages/booking/payment/payment_page.dart';
import 'package:moviroo/pages/chat/chat_page.dart';
import 'package:moviroo/pages/map_eta/map_eta_page.dart';
import 'package:moviroo/pages/booking/payment/payment_success/payment_success_page.dart';
import 'package:moviroo/pages/search/location_screen.dart';
import 'package:moviroo/pages/tracking/track_ride_page.dart';

import '../pages/onboarding/onboarding_page.dart';
import '../pages/auth/login/login_page.dart';
import '../pages/auth/signup/sign_up_page.dart';
import '../pages/auth/forgot_password/forget_password.dart';
import '../pages/auth/complete_profile/complete_profile_page.dart';
import '../pages/auth/otp/otp.dart';
import '../pages/auth/check_email/check_email_page.dart';
import '../pages/tabs [passenger]/home/home_page.dart' as home_tab;
import '../pages/tabs [passenger]/support/support_page.dart';
import '../pages/tabs [passenger]/profile/settings_page.dart';
import '../pages/tabs [passenger]/trajet/trajet_page.dart';
import '../pages/tabs [passenger]/membre/membre_pass_screen.dart';
import '../pages/booking/VehicleSelection/vehicle_selection_page.dart';
import '../pages/splash/splash_page.dart';

class AppRouter {
  static const String splash = '/splash';
  static const String chat = '/chat';
  static const String getStartedPage = '/onboarding';
  static const String booking = '/booking';
  static const String payment = '/payment';
  static const String mapEtaPage = '/map-eta';
  static const String trackRide = '/track_ride';
  static const String paymentSuccess = '/payment-success';
  static const String rideCard = '/ride-card';
  static const String nextDestinationSearchRoute = '/nextdestinationsearch';
  static const String vehicleSelectionPage = '/vehicle_selection_page';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPass = '/forgot-password';
  static const String otp = '/otp';
  static const String checkEmail = '/check-email';
  static const String completeProfile = '/complete-profile';
  static const String home = '/home';
  static const String support = '/support';
  static const String profile = '/profile';
  static const String rideDetails = '/ride-details';
  static const String trajet = '/trajet';
  static const String membre = '/membre';

  static const String initialRoute = splash;

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashPage(),
    payment: (_) => const PaymentPage(),
    paymentSuccess: (_) => const PaymentSuccessPage(),
    rideDetails: (_) => const RideDetailsPage(),
    chat: (_) => const ChatPage(),
    booking: (_) => const BookingSummaryPage(),
    vehicleSelectionPage: (_) => const VehicleSelectionPage(),
    getStartedPage: (_) => const OnboardingPage(),
    login: (_) => const LoginPage(),
    signup: (_) => const SignUpPage(),
    forgotPass: (_) => const ForgotPasswordPage(),
    otp: (_) => const OtpPage(),
    checkEmail: (_) => const CheckEmailPage(),
    completeProfile: (_) => const CompleteProfilePage(),
    home: (_) => const home_tab.HomePage(),
    support: (_) => const SupportPage(),
    profile: (_) => const SettingsPage(),
    nextDestinationSearchRoute: (_) => const LocationScreen(),
    mapEtaPage: (_) => const MapEtaPage(),
    trajet: (_) => const TrajetPage(),
    membre: (_) => const MembrePassScreen(),
    trackRide: (ctx) {
      final args =
          ModalRoute.of(ctx)?.settings.arguments as Map<String, dynamic>?;
      return TrackRidePage(
        rideId: args?['rideId'] as String? ?? '',
        pickupLat: (args?['pickupLat'] as num?)?.toDouble() ?? 36.8189,
        pickupLon: (args?['pickupLon'] as num?)?.toDouble() ?? 10.1658,
        dropoffLat: (args?['dropoffLat'] as num?)?.toDouble() ?? 36.8300,
        dropoffLon: (args?['dropoffLon'] as num?)?.toDouble() ?? 10.1750,
        pickupAddress: args?['pickupAddress'] as String? ?? 'Pickup',
        dropoffAddress: args?['dropoffAddress'] as String? ?? 'Drop-off',
        driverName: args?['driverName'] as String? ?? 'Driver',
        vehicleName: args?['vehicleName'] as String? ?? 'Vehicle',
        vehicleColor: args?['vehicleColor'] as String? ?? '',
        plateNumber: args?['plateNumber'] as String? ?? '',
        etaMins: args?['etaMins'] as int?,
      );
    },
  };

  static Future<T?> push<T>(
    BuildContext context,
    String routeName, {
    Object? args,
  }) {
    return Navigator.pushNamed<T>(context, routeName, arguments: args);
  }

  static Future<T?> replace<T>(
    BuildContext context,
    String routeName, {
    Object? args,
  }) {
    return Navigator.pushReplacementNamed<T, dynamic>(
      context,
      routeName,
      arguments: args,
    );
  }

  static Future<T?> clearAndGo<T>(
    BuildContext context,
    String routeName, {
    Object? args,
  }) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      (_) => false,
      arguments: args,
    );
  }

  static void pop(BuildContext context, [dynamic result]) {
    Navigator.pop(context, result);
  }
}
