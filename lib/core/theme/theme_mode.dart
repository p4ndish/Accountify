import 'package:accountify/core/theme/colors.dart';
import 'package:flutter/material.dart';

const String _fontFamily = 'Inter';

ThemeData darkTheme = ThemeData.dark().copyWith(
  scaffoldBackgroundColor: AppColors.darkBgApp,
  colorScheme: const ColorScheme.dark(
    brightness: Brightness.dark,
    primary: AppColors.primaryBrand,
    surface: AppColors.darkBgApp,
    onSurface: AppColors.darkTextPrimary,
    surfaceContainerHighest: AppColors.darkBgCard,
    onSurfaceVariant: AppColors.darkTextSecondary,
    outline: AppColors.darkBorderColor,
    // Transaction colors — softer pastels
    primaryContainer: AppColors.darkBgReceived,
    onPrimaryContainer: AppColors.darkTextReceived,
    errorContainer: AppColors.darkBgSent,
    onErrorContainer: AppColors.darkTextSent,
    // Bank card neutral bg
    surfaceContainerLow: AppColors.darkBgBankCard,
  ),
  cardTheme: CardThemeData(
    color: AppColors.darkBgCard,
    elevation: 0,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.darkBgCard,
    foregroundColor: AppColors.darkTextPrimary,
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.darkBorderColor,
  ),
  iconTheme: const IconThemeData(
    color: AppColors.darkTextSecondary,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 32,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
    ),
  ),
);

ThemeData lightTheme = ThemeData.light().copyWith(
  scaffoldBackgroundColor: AppColors.bgApp,
  colorScheme: const ColorScheme.light(
    brightness: Brightness.light,
    primary: AppColors.primaryBrand,
    surface: AppColors.bgApp,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: AppColors.bgCard,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.borderColor,
    // Transaction colors — softer pastels
    primaryContainer: AppColors.bgReceived,
    onPrimaryContainer: AppColors.textReceived,
    errorContainer: AppColors.bgSent,
    onErrorContainer: AppColors.textSent,
    // Bank card neutral bg
    surfaceContainerLow: AppColors.bgBankCard,
  ),
  cardTheme: CardThemeData(
    color: AppColors.bgCard,
    elevation: 0,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.bgCard,
    foregroundColor: AppColors.textPrimary,
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.borderColor,
  ),
  iconTheme: const IconThemeData(
    color: AppColors.textSecondary,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 32,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
    ),
  ),
);
