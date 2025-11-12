import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Ana Renk Paleti
  static const Color tealBlue = Color(0xFF009DAE);
  static const Color lightAquaGradientStart = Color(0xFFB2FEFA);
  static const Color aquaGradientEnd = Color(0xFF0ED2F7);
  static const Color mintBlue = Color(0xFFA7E3F4);
  static const Color deepCyan = Color(0xFF007C91);
  static const Color turquoiseSoft = Color(0xFF80DEEA);
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF023047);
  static const Color grayText = Color(0xFF6C757D);
  static const Color accentYellow = Color(0xFFFFD166);

  // Ek Arayüz Renkleri
  static const Color backgroundLight = Color(0xFFF8FBFD);
  static const Color inputFieldGray = Color(0xFFF1F3F4);
  static const Color iconGray = Color(0xFFA0A0A0);
  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color successGreen = Color(0xFF06D6A0);
  static const Color warningOrange = Color(0xFFF9A826);
  
  // Anasayfa Renkleri
  static const Color lightTurquoise = Color(0xFFCFF6F7);
  static const Color mediumTurquoise = Color(0xFF85E4E0);

  // Gradient
  static LinearGradient get backgroundGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [lightAquaGradientStart, aquaGradientEnd],
  );

  // Text Styles
  static TextStyle get headingLarge => GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: darkText,
  );

  static TextStyle get headingMedium => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: darkText,
  );

  static TextStyle get headingSmall => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: darkText,
  );

  static TextStyle get bodyLarge => GoogleFonts.poppins(
    fontSize: 14,
    color: darkText,
  );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
    fontSize: 13,
    color: darkText,
  );

  static TextStyle get bodySmall => GoogleFonts.poppins(
    fontSize: 11,
    color: grayText,
  );

  // Theme Data
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    textTheme: GoogleFonts.poppinsTextTheme(),
    colorScheme: ColorScheme.light(
      primary: tealBlue,
      secondary: deepCyan,
      surface: white,
      background: backgroundLight,
      error: Colors.red,
      onPrimary: white,
      onSecondary: white,
      onSurface: darkText,
      onBackground: darkText,
    ),
    scaffoldBackgroundColor: backgroundLight,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: darkText),
      titleTextStyle: GoogleFonts.poppins(
        color: darkText,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputFieldGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: tealBlue, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: tealBlue,
        foregroundColor: white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
