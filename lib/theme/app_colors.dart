import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryPurple = Color(0xFFB12CFF);
  static const Color secondaryPurple = Color(0xFF8D21B7);
  
  // Dark Mode
  static const Color darkBg = Color(0xFF0B000F);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkText = Color(0xFFFFFFFF);
  
  // Light Mode
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF5F5F5);
  static const Color lightText = Color(0xFF0B000F);
  
  // Gray Scale
  static const Color gray7B = Color(0xFF7B7B85);
  static const Color grayE6 = Color(0xFFE6E6EA);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFF9500);
  
  // Gradients
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [primaryPurple, secondaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient glowGradient = LinearGradient(
    colors: [
      Color(0x99B12CFF), // primaryPurple with 60% opacity
      Color(0x4D8D21B7), // secondaryPurple with 30% opacity
      Color(0x00000000), // transparent
    ],
    begin: Alignment.center,
    end: Alignment.bottomCenter,
  );
}