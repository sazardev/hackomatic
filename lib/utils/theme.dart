import 'package:flutter/material.dart';

class HackomaticTheme {
  // Hacker-style color palette
  static const Color primaryGreen = Color(0xFF00FF41);
  static const Color darkGreen = Color(0xFF00CC33);
  static const Color backgroundColor = Color(0xFF0A0A0A);
  static const Color surfaceColor = Color(0xFF1A1A1A);
  static const Color cardColor = Color(0xFF2A2A2A);
  static const Color textColor = Color(0xFF00FF41);
  static const Color secondaryTextColor = Color(0xFF888888);
  static const Color errorColor = Color(0xFFFF4444);
  static const Color warningColor = Color(0xFFFFAA00);
  static const Color successColor = Color(0xFF00FF41);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      fontFamily: 'Courier',

      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        secondary: darkGreen,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: backgroundColor,
        onSecondary: backgroundColor,
        onSurface: textColor,
        onError: backgroundColor,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Courier',
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: backgroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Courier',
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: primaryGreen, width: 1),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryGreen),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryGreen),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        labelStyle: const TextStyle(color: textColor),
        hintStyle: const TextStyle(color: secondaryTextColor),
      ),

      iconTheme: const IconThemeData(color: primaryGreen),

      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textColor, fontFamily: 'Courier'),
        displayMedium: TextStyle(color: textColor, fontFamily: 'Courier'),
        displaySmall: TextStyle(color: textColor, fontFamily: 'Courier'),
        headlineLarge: TextStyle(color: textColor, fontFamily: 'Courier'),
        headlineMedium: TextStyle(color: textColor, fontFamily: 'Courier'),
        headlineSmall: TextStyle(color: textColor, fontFamily: 'Courier'),
        titleLarge: TextStyle(color: textColor, fontFamily: 'Courier'),
        titleMedium: TextStyle(color: textColor, fontFamily: 'Courier'),
        titleSmall: TextStyle(color: textColor, fontFamily: 'Courier'),
        bodyLarge: TextStyle(color: textColor, fontFamily: 'Courier'),
        bodyMedium: TextStyle(color: textColor, fontFamily: 'Courier'),
        bodySmall: TextStyle(color: secondaryTextColor, fontFamily: 'Courier'),
        labelLarge: TextStyle(color: textColor, fontFamily: 'Courier'),
        labelMedium: TextStyle(color: textColor, fontFamily: 'Courier'),
        labelSmall: TextStyle(color: secondaryTextColor, fontFamily: 'Courier'),
      ),
    );
  }
}
