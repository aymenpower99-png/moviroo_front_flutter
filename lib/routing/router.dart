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
import '../pages/auth/login_page.dart';
import '../pages/auth/sign_up_page.dart';
import '../pages/auth/forget_password.dart';
import '../pages/tabs [passenger]/home/home_page.dart';
import '../pages/tabs [passenger]/support/support_page.dart';
import '../pages/tabs [passenger]/profile/settings_page.dart';
import '../pages/tabs [passenger]/trajet/trajet_page.dart';
import '../pages/tabs [passenger]/membre/membre_pass_screen.dart';
import '../pages/booking/VehicleSelection/vehicle_selection_page.dart';
import '../pages/splash/splash_page.dart';

class AppRouter {
  static const String splash                     = '/splash';
  static const String chat                       = '/chat';
  static const String getStartedPage             = '/onboarding';
  static const String booking                    = '/booking';
  static const String payment                    = '/payment';
  static const String mapEtaPage                 = '/map-eta';
  static const String trackRide                  = '/track_ride';
  static const String paymentSuccess             = '/payment-success';
  static const String rideCard                   = '/ride-card';
  static const String nextDestinationSearchRoute = '/nextdestinationsearch';
  static const String vehicleSelectionPage       = '/vehicle_selection_page';
  static const String login                      = '/login';
  static const String signup                     = '/signup';
  static const String forgotPass                 = '/forgot-password';
  static const String home                       = '/home';
  static const String support                    = '/support';
  static const String profile                    = '/profile';
  static const String rideDetails                = '/ride-details';
  static const String trajet                     = '/trajet';
  static const String membre                     = '/membre';

  static const String initialRoute = home;

  static Map<String, WidgetBuilder> get routes => {
        splash:                     (_) => const SplashPage(),
        payment:                    (_) => const PaymentPage(),
        paymentSuccess:             (_) => const PaymentSuccessPage(),
        rideDetails:                (_) => const RideDetailsPage(),
        chat:                       (_) => const ChatPage(),
        booking:                    (_) => const BookingSummaryPage(),
        vehicleSelectionPage:       (_) => const VehicleSelectionPage(),
        getStartedPage:             (_) => const OnboardingPage(),
        login:                      (_) => const LoginPage(),
        signup:                     (_) => const SignUpPage(),
        forgotPass:                 (_) => const ForgotPasswordPage(),
        home:                       (_) => const HomePage(),
        support:                    (_) => const SupportPage(),
        profile:                    (_) => const SettingsPage(),
        nextDestinationSearchRoute: (_) => const LocationScreen(),
        mapEtaPage:                 (_) => const MapEtaPage(),
        trajet:                     (_) => const TrajetPage(),
        membre:                     (_) => const MembrePassScreen(),
        trackRide:                  (_) => const TrackRidePage(),  // ← NEW
      };

  static Future<T?> push<T>(BuildContext context, String routeName,
      {Object? args}) {
    return Navigator.pushNamed<T>(context, routeName, arguments: args);
  }

  static Future<T?> replace<T>(BuildContext context, String routeName,
      {Object? args}) {
    return Navigator.pushReplacementNamed<T, dynamic>(context, routeName,
        arguments: args);
  }

  static Future<T?> clearAndGo<T>(BuildContext context, String routeName,
      {Object? args}) {
    return Navigator.pushNamedAndRemoveUntil<T>(context, routeName,
        (_) => false,
        arguments: args);
  }

  static void pop(BuildContext context, [dynamic result]) {
    Navigator.pop(context, result);
  }
}