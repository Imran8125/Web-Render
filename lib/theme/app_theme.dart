import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Core colors (Black, White, Silver Theme)
  static const Color deepBlack = Color(0xFF000000); // True black
  static const Color surfaceDark = Color(0xFF1A1A1A); // Surface variant
  static const Color elevatedGray = Color(0xFF242424); // Elevated surface
  static const Color primaryWhite = Color(0xFFFFFFFF); // Primary CTA
  static const Color secondarySilver = Color(0xFFE0E0E0); // Secondary accent
  static const Color pureWhite = Color(0xFFFFFFFF); // Pure white for text
  static const Color lightSilver = Color(0xFF9CA3AF); // Secondary text
  static const Color editorBg = Color(0xFF0A0A0A); // Dark editor bg

  // Semantic/Syntax colors
  static const Color errorColor = Color(0xFFEF4444); // Error red
  static const Color syntax1 = Color(0xFFFFFFFF);
  static const Color syntax2 = Color(0xFFD1D5DB);
  static const Color syntax3 = Color(0xFF9CA3AF);
  static const Color syntax4 = Color(0xFF6B7280);
  static const Color syntaxGray = Color(0xFF4B5563);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deepBlack,
      colorScheme: const ColorScheme.dark(
        primary: primaryWhite,
        secondary: secondarySilver,
        surface: elevatedGray,
        onSurface: pureWhite,
        onPrimary: deepBlack,
        onSecondary: deepBlack,
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            color: pureWhite,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: pureWhite,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(color: pureWhite, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: pureWhite),
          bodyLarge: TextStyle(color: lightSilver),
          bodyMedium: TextStyle(color: lightSilver),
          labelLarge: TextStyle(color: pureWhite, fontWeight: FontWeight.w500),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: deepBlack,
        foregroundColor: pureWhite,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: pureWhite,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryWhite,
        foregroundColor: deepBlack,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      cardTheme: CardThemeData(
        color: elevatedGray,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceDark,
        indicatorColor: primaryWhite.withAlpha(25),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.spaceGrotesk(
              color: primaryWhite,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return GoogleFonts.spaceGrotesk(color: lightSilver, fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryWhite);
          }
          return const IconThemeData(color: lightSilver);
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryWhite,
        unselectedLabelColor: lightSilver,
        indicatorColor: primaryWhite,
        labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.spaceGrotesk(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryWhite, width: 2),
        ),
        hintStyle: const TextStyle(color: lightSilver),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: elevatedGray,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: pureWhite,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
