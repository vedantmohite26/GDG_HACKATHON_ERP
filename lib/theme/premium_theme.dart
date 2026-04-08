import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Academic Vitality Design System
/// Inspired by the UniConnect graduation-cap icon:
///   Royal Blue header, Orange CTAs, Green success, light airy surfaces.
class PremiumTheme {
  // ────────────────────────────────────────────
  // Core Color Tokens
  // ────────────────────────────────────────────
  static const Color primary = Color(0xFF1565C0);        // Icon Royal Blue
  static const Color primaryLight = Color(0xFF29B6F6);   // Icon Sky Blue
  static const Color primaryContainer = Color(0xFFE3F2FD); // Light Blue-50
  static const Color secondary = Color(0xFFFF8F00);      // Icon Amber Orange
  static const Color secondaryLight = Color(0xFFFFB300); // Icon Tassel Yellow
  static const Color tertiary = Color(0xFF4CAF50);       // Icon Emerald Green
  static const Color tertiaryLight = Color(0xFF81C784);  // Light Green

  // Light Mode Surfaces
  static const Color background = Color(0xFFF1F7FE);     // Blue-tinted page bg
  static const Color surface = Color(0xFFFFFFFF);        // Card surface
  static const Color surfaceVariant = Color(0xFFE8F0FE); // Subtle tinted card
  static const Color surfaceContainer = Color(0xFFDCEEFD); // Stat card bg

  // Text Colors (Light Mode)
  static const Color textPrimary = Color(0xFF0F172A);    // Slate 900 (More standard deep navy)
  static const Color textSecondary = Color(0xFF334155);  // Slate 700 (High contrast)

  // Status
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFCDD2);
  static const Color success = tertiary;
  static const Color warning = secondary;

  // Committee Dark Mode Surfaces (Vibrant Navy)
  static const Color darkBackground = Color(0xFF0A192F); // Vibrant Navy
  static const Color darkSurface = Color(0xFF112240);    // Deep Navy Surface
  static const Color darkSurfaceVariant = Color(0xFF1D2D44); // Elevated navy card
  static const Color darkText = Color(0xFFE6F1FF);       // Off-white/Sky tint
  static const Color darkTextSecondary = Color(0xFF8892B0);

  // ────────────────────────────────────────────
  // Gradients
  // ────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFF8F00), Color(0xFFFFA000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient academicPathGradient = LinearGradient(
    colors: [primary, secondary, tertiary],
    stops: [0.3, 0.6, 1.0],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  static const LinearGradient committeeHeroGradient = LinearGradient(
    colors: [Color(0xFF0A192F), Color(0xFF1565C0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ────────────────────────────────────────────
  // Radius Constants
  // ────────────────────────────────────────────
  static const double radiusCard = 20.0;
  static const double radiusPill = 48.0;
  static const double radiusInput = 14.0;
  static const double radiusChip = 24.0;

  // ────────────────────────────────────────────
  // LIGHT THEME (Student & Faculty)
  // ────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primary,

      colorScheme: const ColorScheme.light(
        primary: primary,
        primaryContainer: primaryContainer,
        secondary: secondary,
        tertiary: tertiary,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
        surfaceContainerHighest: surfaceVariant,
      ),

      textTheme: TextTheme(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32, fontWeight: FontWeight.w700,
          color: textPrimary, letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 28, fontWeight: FontWeight.w700,
          color: textPrimary, letterSpacing: -0.5,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 24, fontWeight: FontWeight.w600, color: textPrimary,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w400, color: textSecondary,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white,
        ),
        labelMedium: GoogleFonts.plusJakartaSans(
          fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
      dividerColor: const Color(0xFFCFD8DC),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
        shadowColor: primary.withValues(alpha: 0.08),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFE8F4FD),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: Color(0xFFBBDEFB), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 13),
        hintStyle: GoogleFonts.inter(
          color: textSecondary.withValues(alpha: 0.7), fontSize: 14,
        ),
        prefixIconColor: primary,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w600,
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondary,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 10, fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 10),
        elevation: 8,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: primary,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusChip),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFFE3EEF7),
        thickness: 1,
        space: 1,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary,
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ────────────────────────────────────────────
  // DARK THEME (Committee Portal — Academic Sanctuary)
  // ────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primary,

      colorScheme: const ColorScheme.dark(
        primary: primary,
        primaryContainer: Color(0xFF0D2137),
        secondary: secondary,
        tertiary: tertiary,
        surface: darkSurface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onSurface: darkText,
        onError: Colors.white,
        surfaceContainerHighest: darkSurfaceVariant,
      ),

      textTheme: TextTheme(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32, fontWeight: FontWeight.w700, color: darkText,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 28, fontWeight: FontWeight.w700, color: darkText,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 24, fontWeight: FontWeight.w600, color: darkText,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 20, fontWeight: FontWeight.w600, color: darkText,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w600, color: darkText,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w600, color: darkText,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w400, color: darkText,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w400, color: darkTextSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w400, color: darkTextSecondary,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: darkText),
        actionsIconTheme: const IconThemeData(color: darkText),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkText,
          letterSpacing: -0.5,
        ),
      ),

      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: darkTextSecondary),
        hintStyle: GoogleFonts.inter(
          color: darkTextSecondary.withValues(alpha: 0.6),
        ),
        prefixIconColor: primary,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w600,
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondary,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceVariant,
        selectedColor: primary,
        labelStyle: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w500, color: darkText,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusChip),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.08),
        thickness: 1,
        space: 1,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        modalBackgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurfaceVariant,
        contentTextStyle: GoogleFonts.inter(color: darkText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ────────────────────────────────────────────
  // Helper: get greeting based on time of day
  // ────────────────────────────────────────────
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // ────────────────────────────────────────────
  // Helper: initials avatar color per name
  // ────────────────────────────────────────────
  static Color avatarColor(String name) {
    final colors = [
      const Color(0xFF1565C0),
      const Color(0xFF6A1B9A),
      const Color(0xFF00695C),
      const Color(0xFFE65100),
      const Color(0xFF880E4F),
      const Color(0xFF1B5E20),
    ];
    if (name.isEmpty) return colors[0];
    return colors[name.codeUnitAt(0) % colors.length];
  }
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}
