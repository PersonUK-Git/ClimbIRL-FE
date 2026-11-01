import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography for ClimbIRL: Onest throughout, tight and confident at large sizes.
class AppTextStyles {
  AppTextStyles._();

  /// Large display style for headings and numerals.
  static TextStyle display(
    double fontSize, {
    Color? color,
    double height = 1.1,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return GoogleFonts.onest(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: fontSize * -0.025,
      color: color,
    );
  }

  static TextTheme get textTheme {
    return GoogleFonts.onestTextTheme().copyWith(
      displayLarge: display(56),
      displayMedium: display(44),
      displaySmall: display(36),
      headlineLarge: display(32),
      headlineMedium: display(26),
      headlineSmall: display(21),
      titleLarge: display(18),
      titleMedium: GoogleFonts.onest(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
      ),
      titleSmall: GoogleFonts.onest(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      bodyLarge: GoogleFonts.onest(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      bodyMedium: GoogleFonts.onest(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      bodySmall: GoogleFonts.onest(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.35,
      ),
      labelLarge: GoogleFonts.onest(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: GoogleFonts.onest(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: GoogleFonts.onest(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
