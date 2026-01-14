import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Professional blue-based color system (Swiggy/Zomato inspired, fintech-like)
  static const Color primaryBlue = Color(0xFF1976D2); // Deep blue for buttons, active states
  static const Color secondaryBlue = Color(0xFF42A5F5); // Softer blue for cards, highlights
  static const Color accentBlue = Color(0xFFE3F2FD); // Very light blue for icons, chips, progress
  static const Color backgroundBlue = Color(0xFFF5F9FF); // Light blue-tinted off-white background
  
  // Status colors
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color warningAmber = Color(0xFFFFB300);
  static const Color errorRed = Color(0xFFE53935);
  
  // Neutral palette
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceLightBlue = Color(0xFFFAFCFF); // Very light blue surface
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color dividerGray = Color(0xFFE0E0E0);
  
  // Status colors
  static const Color activeGreen = Color(0xFF4CAF50);
  static const Color offlineGray = Color(0xFF9E9E9E);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: secondaryBlue,
        surface: surfaceWhite,
        error: errorRed,
        onPrimary: Colors.white,
        onSurface: textPrimary,
        background: backgroundBlue,
      ),
      scaffoldBackgroundColor: backgroundBlue,
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          color: textPrimary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: textSecondary,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          color: textTertiary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: surfaceWhite,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          shadowColor: primaryBlue.withOpacity(0.3),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dividerGray, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dividerGray, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  // Soft shadow for cards
  static List<BoxShadow> cardShadow() {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ];
  }

  // Blue gradient for hero sections
  static BoxDecoration heroGradient() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryBlue, secondaryBlue],
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: primaryBlue.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // Subtle blue-tinted background
  static BoxDecoration subtleGradient() {
    return BoxDecoration(
      color: backgroundBlue,
    );
  }

  // Backward compatibility aliases (mapped to blue equivalents)
  static const Color deepBlue = textPrimary;
  static const Color lightBlue = accentBlue;
  static const Color white = surfaceWhite;
  static const Color lightGray = backgroundBlue;
  static const Color mediumGray = dividerGray;
  static const Color darkGray = textSecondary;
  static const Color grey = textSecondary;
  static const Color successGreen = accentGreen;
  static const Color warningOrange = warningAmber;

  // Backward compatibility methods
  static BoxDecoration gradientBackground() => subtleGradient();
  
  static BoxDecoration glassmorphismCard({double opacity = 0.95, double blur = 10}) {
    return BoxDecoration(
      color: surfaceWhite.withOpacity(opacity),
      borderRadius: BorderRadius.circular(16),
      boxShadow: cardShadow(),
    );
  }

  static BoxDecoration gradientCard({List<Color>? colors}) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors ?? [primaryBlue, secondaryBlue],
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: primaryBlue.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static List<BoxShadow> premiumShadow({Color? color, double blur = 20}) {
    return [
      BoxShadow(
        color: (color ?? Colors.black).withOpacity(0.08),
        blurRadius: blur,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: (color ?? Colors.black).withOpacity(0.04),
        blurRadius: blur * 2,
        offset: const Offset(0, 8),
      ),
    ];
  }
}
