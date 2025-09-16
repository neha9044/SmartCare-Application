import 'package:flutter/material.dart';

class AppColors {
  // Original colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color accentColor = Color(0xFF03DAC6);
  static const Color scaffoldBackgroundColor = Color(0xFFF5F5F5);
  static const Color textColor = Color(0xFF333333);
  static const Color lightGrey = Color(0xFFBDBDBD);
  static const Color darkGrey = Color(0xFF616161);
  static const Color green = Color(0xFF4CAF50);
  static const Color orange = Color(0xFFFF9800);
  static const Color red = Color(0xFFF44336);

  // Glassmorphism gradient colors (pure blue tones)
  static const Color gradientStart = Color(0xFF4A90E2);
  static const Color gradientMid1 = Color(0xFF357ABD);
  static const Color gradientMid2 = Color(0xFF2C5F95);
  static const Color gradientEnd = Color(0xFF1A3B6B);

  // Glass effect colors
  static const Color glassWhite = Colors.white;
  static const Color glassTransparent = Colors.transparent;

  // Glass opacity variations
  static Color glassWhite10 = Colors.white.withOpacity(0.1);
  static Color glassWhite20 = Colors.white.withOpacity(0.2);
  static Color glassWhite30 = Colors.white.withOpacity(0.3);
  static Color glassWhite80 = Colors.white.withOpacity(0.8);

  // Gradient definition for easy reuse
  static const LinearGradient glassmorphismGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      gradientStart,
      gradientMid1,
      gradientMid2,
      gradientEnd,
    ],
    stops: [0.0, 0.3, 0.7, 1.0],
  );
}