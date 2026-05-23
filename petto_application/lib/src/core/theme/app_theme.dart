import 'package:flutter/material.dart';

class AppTheme {
  static const String sansFontFamily = 'PlusJakartaSans';
  static const String displayFontFamily = 'Outfit';
  static const Color primaryColor = Color(0xFFF58071);
  static const Color secondaryColor = Color(0xFF3F6174);
  static const Color accentColor = Color(0xFFFFD25A);
  static const Color backgroundColor = Color(0xFFFFFDF9);
  static const Color surfaceColor = Colors.white;
  static const Color secondaryText = Color(0xFF324D5C);
  static const Color mutedText = Color(0xFF8EA3A6);
  static const Color successColor = Color(0xFF57C785);
  static const Color dangerColor = Color(0xFFE57373);

  static const LinearGradient appBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFEFD), Color(0xFFFFFBF7)],
  );

  static const List<BoxShadow> subtleShadow = [
    BoxShadow(color: Color(0x143F6174), blurRadius: 24, offset: Offset(0, 10)),
  ];

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x1A3F6174), blurRadius: 30, offset: Offset(0, 12)),
  ];

  static BoxDecoration glassCardDecoration({
    Color color = const Color(0xD9FFFFFF),
    BorderRadius? borderRadius,
    bool hasShadow = true, // Add a flag to control shadow
    double borderWidth = 2, // Allow custom border width
    Color? borderColor, // Allow custom border color
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: borderRadius ?? BorderRadius.circular(32),
      border: Border.all(
        color: borderColor ?? Colors.white.withValues(alpha: 0.95),
        width: borderWidth,
      ),
      boxShadow: hasShadow ? subtleShadow : null,
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      brightness: Brightness.light,
    );
    const textTheme = TextTheme(
      headlineLarge: TextStyle(
        fontFamily: displayFontFamily,
        fontSize: 36,
        fontWeight: FontWeight.w800,
        height: 1.0,
        color: secondaryText,
        letterSpacing: -0.9,
      ),
      headlineMedium: TextStyle(
        fontFamily: displayFontFamily,
        fontSize: 30,
        fontWeight: FontWeight.w800,
        height: 1.02,
        color: secondaryText,
        letterSpacing: -0.7,
      ),
      headlineSmall: TextStyle(
        fontFamily: displayFontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        height: 1.08,
        color: secondaryText,
        letterSpacing: -0.45,
      ),
      titleLarge: TextStyle(
        fontFamily: displayFontFamily,
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: secondaryText,
        letterSpacing: -0.25,
      ),
      titleMedium: TextStyle(
        fontFamily: sansFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: secondaryText,
        letterSpacing: -0.05,
      ),
      bodyLarge: TextStyle(
        fontFamily: sansFontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: secondaryText,
        height: 1.45,
        letterSpacing: -0.05,
      ),
      bodyMedium: TextStyle(
        fontFamily: sansFontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: mutedText,
        height: 1.45,
        letterSpacing: 0,
      ),
      labelMedium: TextStyle(
        fontFamily: sansFontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: secondaryText,
        letterSpacing: 0.05,
      ),
      labelSmall: TextStyle(
        fontFamily: sansFontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: mutedText,
        letterSpacing: 0.9,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: secondaryText,
        centerTitle: false,
      ),
      cardColor: surfaceColor,
      dividerColor: Colors.transparent,
      fontFamily: sansFontFamily,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 58),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          textStyle: const TextStyle(
            fontFamily: sansFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 56),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          textStyle: const TextStyle(
            fontFamily: sansFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondaryText,
          side: BorderSide(
            color: secondaryColor.withValues(alpha: 0.08),
            width: 1.4,
          ),
          backgroundColor: Colors.white.withValues(alpha: 0.65),
          minimumSize: const Size(0, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontFamily: sansFontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontFamily: sansFontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.78),
          foregroundColor: secondaryText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.82),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 20,
        ),
        hintStyle: const TextStyle(
          fontFamily: sansFontFamily,
          color: mutedText,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: const TextStyle(
          fontFamily: sansFontFamily,
          color: mutedText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        errorStyle: const TextStyle(
          fontFamily: sansFontFamily,
          color: dangerColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.9),
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.92),
            width: 2,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
          borderSide: BorderSide(color: dangerColor, width: 2),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: secondaryText,
        contentTextStyle: const TextStyle(
          fontFamily: sansFontFamily,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}
