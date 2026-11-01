import 'package:flutter/material.dart';

class AppConstants {
  // App Name
  static const String appName = 'SkillConnect';

  // Colors
  static const Color primaryColor = Color(0xFF0F766E); // Teal 700
  static const Color primaryLightColor = Color(0xFF14B8A6); // Teal 500
  static const Color secondaryColor = Color(0xFFF59E0B); // Amber 500
  static const Color backgroundColor = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceColor = Colors.white;
  
  static const Color textPrimaryColor = Color(0xFF1E293B); // Slate 800
  static const Color textSecondaryColor = Color(0xFF64748B); // Slate 500
  static const Color errorColor = Color(0xFFEF4444); // Red 500
  static const Color successColor = Color(0xFF10B981); // Emerald 500

  // Paddings & Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double borderRadius = 12.0;

  // Text Styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimaryColor,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textSecondaryColor,
  );
}
