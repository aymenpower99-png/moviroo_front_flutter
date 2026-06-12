import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────
// Voice backend URL — points to NestJS backend, not the ML engine directly.
// The backend forwards requests to the ML engine (Render) with auth + timeout.
import 'package:moviroo/core/config/app_config.dart';
const String kBackendUrl = '${AppConfig.baseUrl}/voice';

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
