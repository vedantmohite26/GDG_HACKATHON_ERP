import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StitchTheme {
  // Brand Colors - "Electric & Deep"
  static const Color primaryDeep = Color(0xFF1A237E); // Deep Indigo
  static const Color primaryLight = Color(0xFF3949AB);
  static const Color accentTeal = Color(0xFF00E5FF); // Electric Teal
  static const Color accentPurple = Color(0xFFD500F9); // Vibrant Purple

  // Surface Colors - Glassmorphism Support
  static const Color background = Color(0xFFF5F7FA);
  static const Color surfaceGlass = Colors.white; // Used with opacity

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDeep, primaryLight],
  );

  static const LinearGradient meshGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE8EAF6), // Very light indigo
      Color(0xFFE0F7FA), // Very light teal
      Color(0xFFF3E5F5), // Very light purple
    ],
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryDeep,
        primary: primaryDeep,
        secondary: accentTeal,
        tertiary: accentPurple,
        // background: background, // Deprecated
        surface: surfaceGlass,
      ),
      scaffoldBackgroundColor: background,

      // Typography ("Catchy & Modern")
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primaryDeep,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: primaryDeep,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
      ),

      // Component Styles ("Stitched" look)
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        color: surfaceGlass,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDeep,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primaryDeep.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50], // Slightly off-white for inputs
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryDeep, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: GoogleFonts.inter(color: Colors.grey[600]),
      ),
    );
  }
}
