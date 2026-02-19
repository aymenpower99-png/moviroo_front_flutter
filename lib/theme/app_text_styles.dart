import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ─── Font Family ───────────────────────────────────────────────
  static const String _fontFamily = 'Inter';

  // ─── PAGE TITLES (e.g. "Ride details", "Settings") ─────────────
  static const TextStyle pageTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText,
    letterSpacing: 0,
  );

  static const TextStyle pageTitleLight = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.lightText,
    letterSpacing: 0,
  );

  // ─── SECTION LABELS (e.g. "PASSENGER", "VEHICLE CLASS", "ACCOUNT", "PREFERENCES") ──
  static const TextStyle sectionLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.gray7B,
    letterSpacing: 1.2,
  );

  // ─── BOOKING ID (e.g. "#78438620") ─────────────────────────────
  static const TextStyle bookingId = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText,
    letterSpacing: 0.5,
  );

  // ─── BODY LARGE (e.g. passenger name "Aymen Ben Nacer", place names) ──
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.darkText,
  );

  static const TextStyle bodyLargeLight = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.lightText,
  );

  // ─── BODY MEDIUM (e.g. email, phone, address subtitles) ────────
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.darkText,
  );

  // ─── BODY SMALL / SECONDARY (e.g. city names, field hints) ─────
  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.gray7B,
  );

  // ─── PRICE LARGE (e.g. "EUR 142.26" total) ──────────────────────
  static const TextStyle priceLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText,
    letterSpacing: 0.3,
  );

  // ─── PRICE MEDIUM (e.g. "EUR 142.26" line item, "EUR 0.00" discount) ──
  static const TextStyle priceMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.darkText,
  );

  // ─── PRICE DISCOUNT (green discount value) ──────────────────────
  static const TextStyle priceDiscount = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.success,
  );

  // ─── PRICE LABEL (e.g. "Price", "Discount", "Total") ───────────
  static const TextStyle priceLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.gray7B,
  );

  // ─── PRICE FOOTER (e.g. "(INCL. VAT, FEES & TOLLS)") ───────────
  static const TextStyle priceFooter = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.gray7B,
    letterSpacing: 0.5,
  );

  // ─── BUTTON TEXT ─────────────────────────────────────────────────
  static const TextStyle buttonPrimary = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.2,
  );

  static const TextStyle buttonSecondary = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.error,
    letterSpacing: 0.2,
  );

  // ─── TAB BAR LABELS (e.g. "Accueil", "Trajets", "IA", "Support", "Profil") ──
  static const TextStyle tabLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.gray7B,
  );

  static const TextStyle tabLabelActive = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryPurple,
  );

  // ─── STATUS BADGE (e.g. "Payment pending") ──────────────────────
  static const TextStyle statusBadge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.warning,
    letterSpacing: 0.2,
  );

  // ─── DATE / TIME (e.g. "13 February 2026, 13:00") ───────────────
  static const TextStyle dateTime = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.gray7B,
  );

  // ─── PROFILE NAME (e.g. "hamza") ────────────────────────────────
  static const TextStyle profileName = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText,
  );

  // ─── PROFILE PHONE (e.g. "92969805") ────────────────────────────
  static const TextStyle profilePhone = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.gray7B,
  );

  // ─── PROFILE STAT VALUE (e.g. "4.9", "128", "Gold") ────────────
  static const TextStyle profileStatValue = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText,
  );

  // ─── PROFILE STAT LABEL (e.g. "RATING", "RIDES", "MEMBER") ─────
  static const TextStyle profileStatLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.gray7B,
    letterSpacing: 0.8,
  );

  // ─── SETTINGS ITEM (e.g. "Personal Data", "Payments", "Notifications") ──
  static const TextStyle settingsItem = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.darkText,
  );

  // ─── SETTINGS ITEM VALUE (e.g. "Visa ••42") ─────────────────────
  static const TextStyle settingsItemValue = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.gray7B,
  );

  // ─── VEHICLE CLASS NAME (e.g. "Standard") ───────────────────────
  static const TextStyle vehicleClassName = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.darkText,
  );

  // ─── VEHICLE CLASS DESCRIPTION (e.g. "Mercedes E Class, BMW 5 or similar") ──
  static const TextStyle vehicleClassDesc = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.gray7B,
  );
}