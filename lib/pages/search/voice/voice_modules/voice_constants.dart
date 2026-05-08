import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────
const String kBackendUrl =
    'https://important-satisfy-sternness.ngrok-free.dev/api/voice';

// ─────────────────────────────────────────────────────────────
// Colors
// ─────────────────────────────────────────────────────────────
const Color kBg = Color(0xFF0A0D1A);
const Color kBgCard = Color(0xFF12172B);
const Color kPurple = Color(0xFFA855F7);
const Color kPurpleGlow = Color(0xFF7C3AED);
const Color kPink = Color(0xFFE06FD8);
const Color kTextSub = Color(0xFF6B7299);
const Color kTextMain = Color(0xFFE8EAF6);

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
