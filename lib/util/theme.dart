import 'package:flutter/material.dart';

final Color _background = const Color(0xFF121212);
final Color _surface = const Color(0xFF1E1E1E);
final Color _elevatedSurface = const Color(0xFF2C2C2C);
final Color _primaryText = Colors.white;
final Color _secondaryText = const Color(0xFFB3B3B3);
final Color _accentPurple = const Color(0xFF8A2BE2);
final Color _accentDarkPurple = const Color(0xFF6A0DAD);
final Color _highlight = const Color(0xFFD1C4E9);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: _background,
  canvasColor: _surface,
  cardColor: _surface,
  dividerColor: _elevatedSurface,
  primaryColor: _accentPurple,
  colorScheme: ColorScheme.dark().copyWith(
    primary: _accentPurple,
    primaryContainer: _accentDarkPurple,
    onPrimary: _primaryText,
    secondary: _accentPurple,
    surface: _surface,
    background: _background,
    onSurface: _primaryText,
    onBackground: _primaryText,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: _background,
    foregroundColor: _primaryText,
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: _secondaryText),
    titleTextStyle: TextStyle(
      color: _primaryText,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  iconTheme: IconThemeData(color: _secondaryText),
  textTheme: TextTheme(
    titleLarge: TextStyle(
      color: _primaryText,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(color: _secondaryText),
    bodyMedium: TextStyle(color: _secondaryText),
    labelLarge: TextStyle(
      color: _primaryText,
      fontWeight: FontWeight.w500,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _accentPurple,
      foregroundColor: _primaryText,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: _accentPurple,
    foregroundColor: _primaryText,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _surface,
    labelStyle: TextStyle(color: _secondaryText),
    hintStyle: TextStyle(color: _secondaryText),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _elevatedSurface),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _elevatedSurface),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _accentPurple),
    ),
  ),
);

// --- Light Theme Colors ---
final Color _lightBackground = Color(0xFFFFFFFF);
final Color _lightSurface = Color(0xFFF5F5F5);
final Color _lightElevatedSurface = Color(0xFFFFFFFF);
final Color _lightPrimaryText = Color(0xFF212121);
final Color _lightSecondaryText = Color(0xFF757575);
final Color _lightAccentPurple = Color(0xFF8A2BE2);
final Color _lightAccentDarkPurple = Color(0xFF6A0DAD);
final Color _lightDivider = Color(0xFFEEEEEE);
final Color _lightHighlight = Color(0xFFF3E5F5);

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: _lightBackground,
  canvasColor: _lightSurface,
  cardColor: _lightSurface,
  dividerColor: _lightDivider,
  primaryColor: _lightAccentPurple,
  colorScheme: ColorScheme.light().copyWith(
    primary: _lightAccentPurple,
    primaryContainer: _lightAccentDarkPurple,
    onPrimary: _lightBackground,
    secondary: _lightAccentPurple,
    surface: _lightSurface,
    background: _lightBackground,
    onSurface: _lightPrimaryText,
    onBackground: _lightPrimaryText,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: _lightBackground,
    foregroundColor: _lightPrimaryText,
    elevation: 1,
    centerTitle: true,
    iconTheme: IconThemeData(color: _lightSecondaryText),
    titleTextStyle: TextStyle(
      color: _lightPrimaryText,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  iconTheme: IconThemeData(color: _lightSecondaryText),
  textTheme: TextTheme(
    titleLarge: TextStyle(
      color: _lightPrimaryText,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(color: _lightPrimaryText),
    bodyMedium: TextStyle(color: _lightSecondaryText),
    labelLarge: TextStyle(
      color: _lightPrimaryText,
      fontWeight: FontWeight.w500,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _lightAccentPurple,
      foregroundColor: _lightBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: _lightAccentPurple,
    foregroundColor: _lightBackground,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _lightElevatedSurface,
    labelStyle: TextStyle(color: _lightSecondaryText),
    hintStyle: TextStyle(color: _lightSecondaryText),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _lightDivider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _lightDivider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _lightAccentPurple),
    ),
  ),
  dividerTheme: DividerThemeData(color: _lightDivider),
  highlightColor: _lightHighlight,
);

// Color palette for use in legacy code
class AppColors {
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceVariant = Color(0xFF2C2C2C);
  static const Color primaryPurple = Color(0xFF8A2BE2);
  static const Color purpleLight = Color(0xFF8A2BE2);
  static const Color purpleDark = Color(0xFF6A0DAD);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB3B3B3);
}

class AppStyles {
  /// Input decoration consistent with the dark theme
  static InputDecoration getDarkInputDecoration(
    BuildContext context, {
    String? labelText,
    String? hintText,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      filled: true,
      fillColor: theme.cardColor,
      labelText: labelText,
      hintText: hintText,
      labelStyle: theme.textTheme.bodyMedium,
      hintStyle: theme.textTheme.bodyMedium,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        borderSide: BorderSide(color: theme.colorScheme.primary),
      ),
    );
  }

  /// Input decoration consistent with the light theme
  static InputDecoration getLightInputDecoration(
    BuildContext context, {
    String? labelText,
    String? hintText,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      filled: true,
      fillColor: theme.cardColor,
      labelText: labelText,
      hintText: hintText,
      labelStyle: theme.textTheme.bodyMedium,
      hintStyle: theme.textTheme.bodyMedium,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary),
      ),
    );
  }
}
