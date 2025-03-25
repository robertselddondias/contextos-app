// core/theme/app_theme.dart
import 'package:contextual/core/constants/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Tema claro
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: ColorConstants.primary,
      onPrimary: Colors.white,
      primaryContainer: ColorConstants.primaryVariant,
      onPrimaryContainer: Colors.white,
      secondary: ColorConstants.secondary,
      onSecondary: Colors.white,
      secondaryContainer: ColorConstants.secondaryVariant,
      onSecondaryContainer: Colors.white,
      tertiary: ColorConstants.accent,
      onTertiary: Colors.white,
      tertiaryContainer: ColorConstants.accent.withOpacity(0.8),
      onTertiaryContainer: Colors.white,
      error: ColorConstants.error,
      onError: Colors.white,
      errorContainer: ColorConstants.error.withOpacity(0.1),
      onErrorContainer: ColorConstants.error,
      background: ColorConstants.background,
      onBackground: ColorConstants.textPrimary,
      surface: ColorConstants.surface,
      onSurface: ColorConstants.textPrimary,
      surfaceVariant: ColorConstants.surfaceVariant,
      onSurfaceVariant: ColorConstants.textSecondary,
      outline: ColorConstants.textHint,
      outlineVariant: ColorConstants.textDisabled,
      shadow: Colors.black.withOpacity(0.1),
      scrim: Colors.black.withOpacity(0.3),
      inverseSurface: ColorConstants.darkSurface,
      onInverseSurface: ColorConstants.darkTextPrimary,
      inversePrimary: Color.lerp(ColorConstants.primary, Colors.white, 0.3)!,
    ),

    // Fonte elegante para todo o app
    textTheme: GoogleFonts.poppinsTextTheme(
      ThemeData.light().textTheme,
    ),

    // Componentes
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: ColorConstants.surface,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: ColorConstants.primary,
        foregroundColor: Colors.white,
        shadowColor: ColorConstants.primary.withOpacity(0.4),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(
          color: ColorConstants.primary,
          width: 2,
        ),
        foregroundColor: ColorConstants.primary,
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        foregroundColor: ColorConstants.primary,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: ColorConstants.textHint,
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: ColorConstants.textHint.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: ColorConstants.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: ColorConstants.error,
          width: 1.5,
        ),
      ),
      filled: true,
      fillColor: ColorConstants.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      hintStyle: TextStyle(
        color: ColorConstants.textHint,
        fontWeight: FontWeight.w400,
      ),
      suffixIconColor: ColorConstants.primary,
    ),

    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: ColorConstants.primary,
      foregroundColor: Colors.white,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(
        color: Colors.white,
        size: 24,
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: ColorConstants.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      extendedPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 16,
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentTextStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.white,
      ),
      backgroundColor: Color.lerp(ColorConstants.textPrimary, Colors.black, 0.2),
      elevation: 4,
      actionTextColor: ColorConstants.secondary,
    ),

    // Controles
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      checkColor: MaterialStateProperty.all(Colors.white),
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return ColorConstants.primary;
        }
        return Colors.transparent;
      }),
      side: BorderSide(
        color: ColorConstants.textSecondary,
        width: 1.5,
      ),
    ),

    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return ColorConstants.primary;
        }
        return ColorConstants.textSecondary;
      }),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return ColorConstants.primary;
        }
        return Colors.grey;
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return ColorConstants.primary.withOpacity(0.5);
        }
        return Colors.grey.withOpacity(0.5);
      }),
      trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
    ),

    dividerTheme: DividerThemeData(
      color: ColorConstants.textHint.withOpacity(0.2),
      thickness: 1,
      space: 1,
      indent: 0,
      endIndent: 0,
    ),

    // Navegação
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: ColorConstants.surface,
      selectedItemColor: ColorConstants.primary,
      unselectedItemColor: ColorConstants.textSecondary,
      selectedLabelStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
  );

  // Tema escuro
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: ColorConstants.primary,
      onPrimary: Colors.white,
      primaryContainer: ColorConstants.primaryVariant,
      onPrimaryContainer: Colors.white,
      secondary: ColorConstants.secondary,
      onSecondary: Colors.white,
      secondaryContainer: ColorConstants.secondaryVariant,
      onSecondaryContainer: Colors.white,
      tertiary: ColorConstants.accent,
      onTertiary: Colors.white,
      tertiaryContainer: ColorConstants.accent.withOpacity(0.8),
      onTertiaryContainer: Colors.white,
      error: ColorConstants.error,
      onError: Colors.white,
      errorContainer: ColorConstants.error.withOpacity(0.2),
      onErrorContainer: Colors.white,
      background: ColorConstants.darkBackground,
      onBackground: ColorConstants.darkTextPrimary,
      surface: ColorConstants.darkSurface,
      onSurface: ColorConstants.darkTextPrimary,
      surfaceVariant: ColorConstants.darkSurfaceVariant,
      onSurfaceVariant: ColorConstants.darkTextSecondary,
      outline: ColorConstants.darkTextSecondary.withOpacity(0.7),
      outlineVariant: ColorConstants.darkTextSecondary.withOpacity(0.4),
      shadow: Colors.black.withOpacity(0.3),
      scrim: Colors.black.withOpacity(0.6),
      inverseSurface: ColorConstants.surface,
      onInverseSurface: ColorConstants.textPrimary,
      inversePrimary: Color.lerp(ColorConstants.primary, Colors.black, 0.2)!,
    ),

    // Fonte elegante para todo o app
    textTheme: GoogleFonts.poppinsTextTheme(
      ThemeData.dark().textTheme,
    ),

    // Componentes
    cardTheme: CardTheme(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: ColorConstants.darkSurfaceVariant,
      shadowColor: Colors.black.withOpacity(0.3),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 3,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: ColorConstants.primary,
        foregroundColor: Colors.white,
        shadowColor: Colors.black.withOpacity(0.4),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(
          color: ColorConstants.primary,
          width: 2,
        ),
        foregroundColor: ColorConstants.primary,
      ),
    ),

    // Restante dos componentes similar ao tema claro, mas adaptados para o modo escuro
    // ...

    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: ColorConstants.darkSurface,
      foregroundColor: Colors.white,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(
        color: Colors.white,
        size: 24,
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentTextStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.white,
      ),
      backgroundColor: Colors.grey[850],
      elevation: 4,
      actionTextColor: ColorConstants.secondary,
    ),
  );
}
