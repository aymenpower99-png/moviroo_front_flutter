import 'package:flutter/material.dart';

/// Centralized toast utility for the app.
/// Shows a themed floating SnackBar at the bottom of the screen.
class AppToast {
  AppToast._();

  static void success(BuildContext context, String message) {
    _show(context, message, const Color(0xFF10B981), Icons.check_circle_rounded);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, const Color(0xFFEF4444), Icons.error_rounded);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, const Color(0xFFA855F7), Icons.info_rounded);
  }

  // ── Messenger-based variants (safe across async gaps) ─────────────────────
  // Use these when you need to show a toast AFTER an await, because by then
  // the widget may have been removed from the tree and context.mounted is false.
  // Capture `ScaffoldMessenger.of(context)` BEFORE the await, pass it here.

  static void successMessenger(ScaffoldMessengerState m, String message) {
    _showMessenger(m, message, const Color(0xFF10B981), Icons.check_circle_rounded);
  }

  static void errorMessenger(ScaffoldMessengerState m, String message) {
    _showMessenger(m, message, const Color(0xFFEF4444), Icons.error_rounded);
  }

  static void infoMessenger(ScaffoldMessengerState m, String message) {
    _showMessenger(m, message, const Color(0xFFA855F7), Icons.info_rounded);
  }

  static void _show(BuildContext context, String message, Color bg, IconData icon) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(_buildSnackBar(message, bg, icon));
  }

  static void _showMessenger(ScaffoldMessengerState m, String message, Color bg, IconData icon) {
    m
      ..hideCurrentSnackBar()
      ..showSnackBar(_buildSnackBar(message, bg, icon));
  }

  static SnackBar _buildSnackBar(String message, Color bg, IconData icon) {
    return SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      duration: const Duration(seconds: 3),
      elevation: 4,
    );
  }
}
