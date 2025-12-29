import 'package:flutter/material.dart';

/// App color palette extracted from logo
/// Soft pink/purple theme for calm, nurturing aesthetic
class AppColors {
  // Primary Colors
  static const Color primaryPink = Color(0xFFE91E63); // Soft pink/coral - Primary CTA
  static const Color primaryPurple = Color(0xFF5E548E); // Deep purple/indigo - Secondary actions
  static const Color backgroundLight = Color(0xFFFAF9F6); // Off-white/very light pink
  static const Color textDark = Color(0xFF424242); // Dark gray (NOT black)
  static const Color textLight = Color(0xFF757575); // Medium gray for secondary text
  static const Color white = Color(0xFFFFFFFF); // Pure white for cards/contrast

  // Priority Colors (for calendar/reminders)
  static const Color priorityUrgent = Color(0xFFFF6B9D); // Soft coral
  static const Color priorityHigh = Color(0xFFE91E63); // Primary pink
  static const Color priorityMedium = Color(0xFF9C88C8); // Soft purple
  static const Color priorityLow = Color(0xFFB8B8D0); // Very soft gray-purple

  // Semantic Colors
  static const Color success = Color(0xFF66BB6A); // Soft green
  static const Color warning = Color(0xFFFFA726); // Soft orange
  static const Color error = Color(0xFFFF6B9D); // Soft coral (not harsh red)
  static const Color info = Color(0xFF42A5F5); // Soft blue

  // Gradients (for special UI elements)
  static const LinearGradient pinkGradient = LinearGradient(
    colors: [Color(0xFFE91E63), Color(0xFFFF6B9D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF5E548E), Color(0xFF9C88C8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Usage Rules:
  // - Primary CTA buttons: primaryPink
  // - Secondary actions: primaryPurple
  // - App background: backgroundLight
  // - Primary text: textDark (never pure black)
  // - Secondary text/hints: textLight
  // - Cards/elevated surfaces: white
}
