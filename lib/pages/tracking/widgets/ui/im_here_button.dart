import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// "I'm Here" CTA — shown only during driverArrived phase
// ─────────────────────────────────────────────────────────────────────────────

class ImHereButton extends StatelessWidget {
  final VoidCallback onTap;
  const ImHereButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const green = Color(0xFF4ADE80);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: green,
          foregroundColor: const Color(0xFF0A1F0A),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on_rounded, size: 18),
            const SizedBox(width: 8),
            Text(
              l10n.translate('im_here'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
