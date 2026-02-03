import 'package:flutter/material.dart';

/// App color palette
/// Serene, feminine modern interface with soft pastel warm tones
class AppColors {
  // Primary Colors (Pastels)
  static const Color creamBackground = Color(0xFFFDFBF7); // Warm, soft beige/white background
  static const Color blushPrimary = Color(0xFFFFD6D6); // Soft pink - Main accent
  static const Color peachAccent = Color(0xFFFFCBA4); // Warm peach
  static const Color mintSuccess = Color(0xFFB8E0D2); // Soft mint
  static const Color lavenderSecondary = Color(0xFFE6E6FA); // Soft lavender

  // Text Colors
  static const Color textDark = Color(0xFF4A4A4A); // Softer dark gray
  static const Color textMedium = Color(0xFF7D7D7D); // Medium gray
  static const Color textLight = Color(0xFFA1A1A1); // Light gray
  
  // Semantic Colors (Softened)
  static const Color success = Color(0xFFB8E0D2); // Mint green
  static const Color warning = Color(0xFFFFE0B2); // Soft orange/peach
  static const Color error = Color(0xFFFFB3B3); // Soft red/pink
  static const Color info = Color(0xFFB3E5FC); // Soft blue

  // Priority Colors (Pastel)
  static const Color priorityUrgent = Color(0xFFFFB3B3); // Soft red
  static const Color priorityHigh = Color(0xFFFFD180); // Soft orange
  static const Color priorityMedium = Color(0xFFE1BEE7); // Soft purple
  static const Color priorityLow = Color(0xFFEEEEEE); // Light gray

  // Glass & Shadows
  static Color glassWhite = Colors.white.withOpacity(0.7);
  static Color glassBorder = Colors.white.withOpacity(0.5);
  static final Color shadowLight = Colors.white;
  static final Color shadowDark = Color(0xFFD1CDC7);

  // Gradients
  static const LinearGradient blushGradient = LinearGradient(
    colors: [Color(0xFFFFD6D6), Color(0xFFFFE4E1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient peachGradient = LinearGradient(
    colors: [Color(0xFFFFCBA4), Color(0xFFFFDAB9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Legacy mappings (to prevent immediate breakages, mapped to new palette)
  static const Color primaryPink = blushPrimary;
  static const Color primaryPurple = lavenderSecondary;
  static const Color backgroundLight = creamBackground;
  static const Color white = Colors.white;
}
