import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const String _font = 'Inter';

  // ─── PAGE TITLES ───────────────────────────────────────────────
  static TextStyle pageTitle(BuildContext context) => TextStyle(
        fontFamily: _font,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.text(context),
      );

  // ─── SECTION LABELS ────────────────────────────────────────────
  static TextStyle sectionLabel(BuildContext context) => TextStyle(
        fontFamily: _font,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.subtext(context),
        letterSpacing: 1.5,
      );

  // ─── BOOKING ID ────────────────────────────────────────────────
  static TextStyle bookingId(BuildContext context) => TextStyle(
        fontFamily: _font,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.text(context),
        letterSpacing: 0.5,
      );

  // ─── BODY LARGE ────────────────────────────────────────────────
  static TextStyle bodyLarge(BuildContext context) => TextStyle(
        fontFamily: _font,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.text(context),
      );

  // ─── BODY MEDIUM ───────────────────────────────────────────────
  static TextStyle bodyMedium(BuildContext context) => TextStyle(
        fontFamily: _font,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.text(context),
      );

  // ─── BODY SMALL / SECONDARY ────────────────────────────────────
  static TextStyle bodySmall(BuildContext context) => TextStyle(
        fontFamily: _font,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.subtext(context),
      );

  // ─── PRICE LARGE ───────────────────────────────────────────────
  static TextStyle priceLarge(BuildContext context) => TextStyle(
        fontFamily: _font,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.text(context),
        letterSpacing: 0.3,
      );

  // ─── PRICE MEDIUM ──────────────────────────────────────────────
  static TextStyle priceMedium(BuildContext context) => TextStyle(
        fontFamily: _font,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.text(context),
      );

  // ─── PRICE DISCOUNT ────────────────────────────────────────────
  static const TextStyle priceDiscount = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.success,
  );

  // ─── PRICE LABEL ───────────────────────────────────────────────
  static TextStyle priceLabel(BuildContext context) => TextStyle(
        fontFamily: _font,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.subtext(context),
      );

  // ─── PRICE FOOTER ──────────────────────────────────────────────
  static TextStyle priceFooter(BuildContext context) => TextStyle(
        fontFamily: _font,
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: AppColors.subtext(context),
        letterSpacing: 0.5,
      );

  // ─── BUTTON TEXT ───────────────────────────────────────────────
  static const TextStyle buttonPrimary = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.2,
  );

  static const TextStyle buttonSecondary = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.error,
    letterSpacing: 0.2,
  );

  // ─── TAB BAR LABELS ────────────────────────────────────────────
  static TextStyle tabLabel(BuildContext context) => TextStyle(
        fontFamily: _font,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.subtext(context),
      );

  static const TextStyle tabLabelActive = TextStyle(
    fontFamily: _font,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryPurple,
  );

  // ─── STATUS BADGE ──────────────────────────────────────────────
  static const TextStyle statusBadge = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.warning,
    letterSpacing: 0.2,
  );

  // ─── DATE / TIME ───────────────────────────────────────────────
  static TextStyle dateTime(BuildContext context) => TextStyle(
        fontFamily: _font,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.subtext(context),
      );

  // ─── PROFILE NAME ──────────────────────────────────────────────
  static TextStyle profileName(BuildContext context) => TextStyle(
        fontFamily: _font,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.text(context),
      );

  // ─── PROFILE PHONE ─────────────────────────────────────────────
  static TextStyle profilePhone(BuildContext context) => TextStyle(
        fontFamily: _font,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.subtext(context),
      );

  // ─── PROFILE STAT VALUE ────────────────────────────────────────
  static TextStyle profileStatValue(BuildContext context) => TextStyle(
        fontFamily: _font,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.text(context),
      );

  // ─── PROFILE STAT LABEL ────────────────────────────────────────
  static TextStyle profileStatLabel(BuildContext context) => TextStyle(
        fontFamily: _font,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.subtext(context),
        letterSpacing: 0.8,
      );

  // ─── SETTINGS ITEM ─────────────────────────────────────────────
  static TextStyle settingsItem(BuildContext context) => TextStyle(
        fontFamily: _font,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.text(context),
      );

  // ─── SETTINGS ITEM VALUE ───────────────────────────────────────
  static TextStyle settingsItemValue(BuildContext context) => TextStyle(
        fontFamily: _font,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.subtext(context),
      );

  // ─── VEHICLE CLASS NAME ────────────────────────────────────────
  static TextStyle vehicleClassName(BuildContext context) => TextStyle(
        fontFamily: _font,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.text(context),
      );

  // ─── VEHICLE CLASS DESCRIPTION ─────────────────────────────────
  static TextStyle vehicleClassDesc(BuildContext context) => TextStyle(
        fontFamily: _font,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.subtext(context),
      );
}