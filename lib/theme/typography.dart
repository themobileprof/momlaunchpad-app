import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography — Fraunces for warmth, Plus Jakarta Sans for clarity.
/// Colors come from [ThemeData.textTheme] / [BuildContext.appInk] at use site.
class AppTypography {
  static TextStyle get headingLarge => GoogleFonts.fraunces(
        fontSize: 34,
        fontWeight: FontWeight.w600,
        height: 1.15,
        letterSpacing: -0.8,
      );

  static TextStyle get headingMedium => GoogleFonts.fraunces(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: -0.4,
      );

  static TextStyle get headingSmall => GoogleFonts.fraunces(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get bodyText => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.55,
      );

  static TextStyle get bodyTextMedium => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.5,
      );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
      );

  static TextStyle get label => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        height: 1.2,
      );

  static TextStyle get button => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        height: 1.2,
      );

  static TextStyle get brandTitle => GoogleFonts.fraunces(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      );

  static TextStyle get appBarBrand => GoogleFonts.fraunces(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.1,
      );

  static TextStyle get pageTitle => GoogleFonts.fraunces(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );
}
