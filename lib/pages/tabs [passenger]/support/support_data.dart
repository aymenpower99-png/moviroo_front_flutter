import 'package:flutter/material.dart';
import 'support_models.dart';

const List<FaqCategory> kFaqCategories = [
  FaqCategory(
    title: 'Booking & Reservations',
    entries: [
      FaqEntry(
        question: 'How do I book a ride in advance?',
        answer:
            'Open the app, tap "Schedule a Ride", select your pickup and destination, then choose a future date and time. You\'ll receive a reminder 30 minutes before your ride.',
      ),
      FaqEntry(
        question: 'Can I modify my reservation after booking?',
        answer:
            'Yes. Go to "My Trips" > select the upcoming ride > tap "Edit". You can change the time, destination, or vehicle type up to 15 minutes before pickup.',
      ),
      FaqEntry(
        question: 'How far in advance can I schedule a ride?',
        answer:
            'You can schedule rides up to 7 days ahead. For airport transfers we recommend booking at least 24 hours in advance to guarantee availability.',
      ),
    ],
  ),
  FaqCategory(
    title: 'Payments & Refunds',
    entries: [
      FaqEntry(
        question: 'How do I request a refund for a cancelled ride?',
        answer:
            'Go to "My Trips", find the cancelled ride, and tap "Request Refund". Refunds are processed within 3–5 business days to your original payment method.',
      ),
      FaqEntry(
        question: 'How do I update my primary payment method?',
        answer:
            'Go to Profile > Payment Methods > tap "+" to add a new card or PayPal. Tap the method and select "Set as Default". Remove old methods by swiping left.',
      ),
      FaqEntry(
        question: 'Why was I charged more than the estimated fare?',
        answer:
            'Final fares can differ due to route changes, traffic, tolls, or surge pricing. The full breakdown is always shown in your trip receipt right after the ride.',
      ),
    ],
  ),
  FaqCategory(
    title: 'Account & Security',
    entries: [
      FaqEntry(
        question: 'How do I change my password?',
        answer:
            'Go to Profile > Settings > Security > "Change Password". Enter your current password then your new one twice. You\'ll be signed out of other devices automatically.',
      ),
      FaqEntry(
        question: 'What should I do if my account is compromised?',
        answer:
            'Tap "Report Compromised Account" in Settings > Security, or call our 24/7 support line. We\'ll lock your account and guide you through a secure recovery process.',
      ),
      FaqEntry(
        question: 'How do I enable two-factor authentication?',
        answer:
            'Go to Profile > Settings > Security > "Two-Factor Authentication" and toggle it on. Choose SMS or an authenticator app — we strongly recommend enabling 2FA.',
      ),
    ],
  ),
];

const List<IconData> kFaqIcons = [
  Icons.calendar_month_rounded,
  Icons.wallet_rounded,
  Icons.shield_outlined,
];