/// Consistent spacing system - all values are multiples of 8
class AppSpacing {
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;

  // Layout Padding Guidelines:
  // - Screen edges: spaceLG (24px)
  // - Card padding: spaceMD (16px)
  // - Between sections: spaceXL (32px)
  // - Between related items: spaceMD (16px)
  // - Tight spacing: spaceSM (8px)
}

/// Border radius standards - all components use rounded corners
class AppRadius {
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusCircle = 999.0; // For circular elements

  // Usage:
  // - Buttons: radiusMedium (16)
  // - Cards: radiusLarge (24)
  // - Input fields: radiusMedium (16)
  // - Bottom sheets: radiusLarge (24) top corners only
  // - Avatar/profile: radiusCircle
}
