import 'package:flutter/material.dart';

class AppColors {
  // Light mode colors inspired by meditation aesthetics
  static const Color primaryBackground = Color(0xFFFAF9F6); // Warm off-white
  static const Color surfaceBackground = Color(0xFFFFFFFF); // Pure white
  static const Color cardBackground = Color(0xFFF5F3F0); // Light warm grey

  // Accent colors - meditation focused
  static const Color primaryAccent = Color(0xFFE65100); // Deeper saffron orange
  static const Color secondaryAccent = Color(0xFFFF8F00); // Warm amber

  // Text colors for light mode
  static const Color textPrimary = Color(0xFF2C2C2C); // Dark charcoal
  static const Color textSecondary = Color(0xFF666666); // Medium grey
  static const Color textTertiary = Color(0xFF999999); // Light grey

  // Additional colors for enhanced UI
  static const Color divider = Color(0xFFE0E0E0);
  static const Color success = Color(0xFF388E3C);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF57C00);

  // Meditation inspired gradients for light mode
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFF8E1), // Light amber
      Color(0xFFFFF3E0), // Light orange
    ],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryAccent,
      Color(0xFFFF6F00), // Lighter orange
    ],
  );

  // Soft shadows for light mode
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);

  // Special colors for meditation elements
  static const Color meditationGold = Color(0xFFFFB300); // For quotes and special text
  static const Color peaceBlue = Color(0xFF1976D2); // For meditation-related elements
}