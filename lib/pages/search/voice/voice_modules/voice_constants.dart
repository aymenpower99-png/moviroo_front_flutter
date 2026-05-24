import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────
const String kBackendUrl =
    'https://important-satisfy-sternness.ngrok-free.dev/api/voice';

// ─────────────────────────────────────────────────────────────
// Theme-aware helpers (call inside build / with context)
// ─────────────────────────────────────────────────────────────
const Color kVoiceBackground = Color(0xFFF3F0FF);
Color voiceBg(BuildContext context) => kVoiceBackground;
Color voiceSurface(BuildContext context) => AppColors.surface(context);
Color voiceBorder(BuildContext context) => AppColors.border(context);
Color voiceText(BuildContext context) => AppColors.text(context);
Color voiceSubtext(BuildContext context) => AppColors.subtext(context);

const Color kPurple = AppColors.primaryPurple;
const Color kPurpleGlow = AppColors.secondaryPurple;
const Color kPink = Color(0xFFE06FD8);

// ─────────────────────────────────────────────────────────────
// Phase
// ─────────────────────────────────────────────────────────────
enum VoicePhase {
  idle,
  recording,
  uploading,
  question,
  waitAnswer,
  result,
  search,
  error,
}
