// utils/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primaryColor = Color(0xFF4ECDC4);
  static const backgroundColor = Color(0xFF1A1A1A);
  static const cardColor = Color(0xFF2A2A2A);
  static const surfaceColor = Color(0xFF2C2C2C);

  static const accentBlue = Color(0xFF4ECDC4);
  static const accentPurple = Color(0xFF9D84FF);

  static TextStyle get headingStyle => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      );

  static TextStyle get subheadingStyle => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.white70,
      );

  static TextStyle get bodyStyle => GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.white70,
      );

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      );

  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        shadowColor: primaryColor.withOpacity(0.3),
      );
}
