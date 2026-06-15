import 'package:flutter/material.dart';

class AppTheme {
  static const String sansFontFamily = 'PlusJakartaSans';
  static const String displayFontFamily = 'Outfit';
  static const Color primaryColor = Color(0xFF7B3034);
  static const Color secondaryColor = Color(0xFFB8757A);
  static const Color accentColor = Color(0xFFC29A45);
  static const Color backgroundColor = Color(0xFFF6F4F1);
  static const Color surfaceColor = Color(0xFFFCFAF6);
  static const Color creamSurfaceColor = Color(0xFFFFF6EA);
  static const Color blushSurfaceColor = Color(0xFFFFECE8);
  static const Color roseSurfaceColor = Color(0xFFEED0D3);
  static const Color warmSurfaceColor = Color(0xFFF1E1CB);
  static const Color secondaryText = Color(0xFF4E1F22);
  static const Color mutedText = Color(0xFF9B756F);
  static const Color successColor = Color(0xFF718656);
  static const Color dangerColor = Color(0xFFC03945);

  static const LinearGradient appBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFC), Color(0xFFF6F4F1)],
  );

  static const List<BoxShadow> subtleShadow = [
    BoxShadow(color: Color(0x1A7B3034), blurRadius: 24, offset: Offset(0, 10)),
  ];

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x237B3034), blurRadius: 30, offset: Offset(0, 12)),
  ];

  static BoxDecoration glassCardDecoration({
    Color color = const Color(0xFCFCFAF6),
    BorderRadius? borderRadius,
    bool hasShadow = true,
    double borderWidth = 2,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: borderRadius ?? BorderRadius.circular(32),
      border: Border.all(
        color: borderColor ?? primaryColor.withValues(alpha: 0.10),
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
      tertiary: accentColor,
      surface: surfaceColor,
      error: dangerColor,
      brightness: Brightness.light,
    );
    const textTheme = TextTheme(
      headlineLarge: TextStyle(
        fontFamily: displayFontFamily,
        fontSize: 36,
        fontWeight: FontWeight.w800,
        height: 1.0,
        color: secondaryText,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        fontFamily: displayFontFamily,
        fontSize: 30,
        fontWeight: FontWeight.w800,
        height: 1.02,
        color: secondaryText,
        letterSpacing: 0,
      ),
      headlineSmall: TextStyle(
        fontFamily: displayFontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        height: 1.08,
        color: secondaryText,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        fontFamily: displayFontFamily,
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: secondaryText,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        fontFamily: sansFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: secondaryText,
        letterSpacing: 0,
      ),
      bodyLarge: TextStyle(
        fontFamily: sansFontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: secondaryText,
        height: 1.45,
        letterSpacing: 0,
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
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _PettoPageTransitionsBuilder(),
          TargetPlatform.iOS: _PettoPageTransitionsBuilder(),
          TargetPlatform.macOS: _PettoPageTransitionsBuilder(),
          TargetPlatform.windows: _PettoPageTransitionsBuilder(),
          TargetPlatform.linux: _PettoPageTransitionsBuilder(),
        },
      ),
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
            color: warmSurfaceColor.withValues(alpha: 0.72),
            width: 1.4,
          ),
          backgroundColor: surfaceColor.withValues(alpha: 0.94),
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
          backgroundColor: surfaceColor.withValues(alpha: 0.94),
          foregroundColor: secondaryText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor.withValues(alpha: 0.96),
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
            color: warmSurfaceColor.withValues(alpha: 0.58),
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(
            color: warmSurfaceColor.withValues(alpha: 0.66),
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

class _PettoPageTransitionsBuilder extends PageTransitionsBuilder {
  const _PettoPageTransitionsBuilder();

  static final Animatable<double> _fadeIn = CurveTween(
    curve: const Interval(0.0, 0.78, curve: Curves.easeOutCubic),
  );

  static final Animatable<double> _fadeOut = CurveTween(
    curve: const Interval(0.0, 0.34, curve: Curves.easeOutCubic),
  ).chain(Tween<double>(begin: 1, end: 0.94));

  static final Animatable<Offset> _slideIn = Tween<Offset>(
    begin: const Offset(0.055, 0.018),
    end: Offset.zero,
  ).chain(CurveTween(curve: Curves.easeOutCubic));

  static final Animatable<Offset> _slideOut = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(-0.018, -0.006),
  ).chain(CurveTween(curve: Curves.easeOutCubic));

  static final Animatable<double> _scaleIn = Tween<double>(
    begin: 0.985,
    end: 1,
  ).chain(CurveTween(curve: Curves.easeOutCubic));

  static final Animatable<double> _scaleOut = Tween<double>(
    begin: 1,
    end: 0.992,
  ).chain(CurveTween(curve: Curves.easeOutCubic));

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.fullscreenDialog) {
      return FadeTransition(
        opacity: animation.drive(_fadeIn),
        child: SlideTransition(
          position: animation.drive(
            Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic)),
          ),
          child: child,
        ),
      );
    }

    return FadeTransition(
      opacity: secondaryAnimation.drive(_fadeOut),
      child: SlideTransition(
        position: secondaryAnimation.drive(_slideOut),
        child: ScaleTransition(
          scale: secondaryAnimation.drive(_scaleOut),
          child: FadeTransition(
            opacity: animation.drive(_fadeIn),
            child: SlideTransition(
              position: animation.drive(_slideIn),
              child: ScaleTransition(
                scale: animation.drive(_scaleIn),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
