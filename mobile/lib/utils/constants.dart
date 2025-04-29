import 'package:flutter/material.dart';

class ApiConstants {
  // Base URL for API
  static const String baseUrl = 'http://0.0.0.0:5000'; // Backend running on port 5000
}

class AppColors {
  // Light theme colors
  static const Color primary = Color(0xFF2E7D32); // Green 800
  static const Color secondary = Color(0xFF00796B); // Teal 700
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFB71C1C); // Red 900
  
  // Dark theme colors
  static const Color primaryDark = Color(0xFF66BB6A); // Green 400
  static const Color secondaryDark = Color(0xFF26A69A); // Teal 400
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color errorDark = Color(0xFFEF5350); // Red 400
  
  // Functional colors
  static const Color suitabilitySafe = Color(0xFF4CAF50); // Green
  static const Color suitabilityModerate = Color(0xFFFFA000); // Amber
  static const Color suitabilityAvoid = Color(0xFFF44336); // Red
  
  // High contrast colors
  static const Color highContrastLight = Colors.black;
  static const Color highContrastDark = Colors.white;
}

class Dimensions {
  static const double cardPadding = 16.0;
  static const double pagePadding = 16.0;
  static const double itemSpacing = 8.0;
  static const double sectionSpacing = 24.0;
  static const double borderRadius = 8.0;
  
  // Text sizes (before scaling)
  static const double fontSizeSmall = 12.0;
  static const double fontSizeNormal = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeHeading = 22.0;
}

class AnimationDurations {
  static const Duration short = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration long = Duration(milliseconds: 500);
}
