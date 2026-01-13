import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // LinkedIn-style blue fintech colors
  static const Color primaryBlue = Color(0xFF0A66C2);
  static const Color lightBlue = Color(0xFFE7F3FF);
  static const Color deepBlue = Color(0xFF004182);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF666666);
  static const Color lightGrey = Color(0xFFF3F2EF);
  static const Color successGreen = Color(0xFF057642);
  static const Color warningOrange = Color(0xFFE37318);
  static const Color errorRed = Color(0xFFD93025);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: lightBlue,
        surface: white,
        background: lightGrey,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: deepBlue,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: deepBlue,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: deepBlue,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: deepBlue,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: grey,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
      ),
    );
  }

  // Glassmorphism card decoration
  static BoxDecoration glassmorphismCard() {
    return BoxDecoration(
      color: white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Gradient decoration
  static BoxDecoration gradientCard() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryBlue, deepBlue],
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: primaryBlue.withOpacity(0.3),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}

