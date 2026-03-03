import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Core colors from Stitch design (Nano Banana Redesign)
  static const Color deepCharcoal = Color(0xFF111110); // Very dark slate/black
  static const Color darkNavy = Color(0xFF1A1A18); // Surface variant
  static const Color elevatedDark = Color(0xFF242421); // Elevated surface
  static const Color electricCyan = Color(0xFFFFD700); // Nano Banana Yellow
  static const Color vibrantPurple = Color(0xFFF59E0B); // Ripe accent orange
  static const Color pureWhite = Color(0xFFFDFDFB); // Off-white
  static const Color lightSlate = Color(0xFFA1A19A); // Warm slate
  static const Color editorBg = Color(0xFF0A0A09); // Dark editor bg

  // Syntax highlighting colors
  static const Color syntaxCoral = Color(0xFFFF6B6B);
  static const Color syntaxSkyBlue = Color(0xFF38BDF8);
  static const Color syntaxAmber = Color(0xFFFACC15);
  static const Color syntaxEmerald = Color(0xFF34D399);
  static const Color syntaxGray = Color(0xFF71716A);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deepCharcoal,
      colorScheme: const ColorScheme.dark(
        primary: electricCyan,
        secondary: vibrantPurple,
        surface: elevatedDark,
        onSurface: pureWhite,
        onPrimary: deepCharcoal,
        onSecondary: pureWhite,
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
          bodyLarge: TextStyle(color: lightSlate),
          bodyMedium: TextStyle(color: lightSlate),
          labelLarge: TextStyle(color: pureWhite, fontWeight: FontWeight.w500),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: deepCharcoal,
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
        backgroundColor: electricCyan,
        foregroundColor: deepCharcoal,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      cardTheme: CardThemeData(
        color: elevatedDark.withAlpha(200),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkNavy,
        indicatorColor: electricCyan.withAlpha(40),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.spaceGrotesk(
              color: electricCyan,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return GoogleFonts.spaceGrotesk(color: lightSlate, fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: electricCyan);
          }
          return const IconThemeData(color: lightSlate);
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: electricCyan,
        unselectedLabelColor: lightSlate,
        indicatorColor: electricCyan,
        labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.spaceGrotesk(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkNavy,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: electricCyan, width: 2),
        ),
        hintStyle: const TextStyle(color: lightSlate),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: elevatedDark,
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
