import 'package:flutter/material.dart';

class GetzyColors {
  static const background = Color(0xFF0C1113);
  static const surface = Color(0xFF202528);
  static const elevated = Color(0xFF2A2F32);
  static const divider = Color(0xFF30373A);
  static const textPrimary = Color(0xFFE7EAEC);
  static const textSecondary = Color(0xFFB7BEC2);
  static const textDisabled = Color(0xFF5D666A);
  static const accent = Color(0xFF67D5FF);
  static const action = Color(0xFF008DAA);
  static const fab = Color(0xFFA9004C);
  static const warning = Color(0xFFFFD54F);

  static const backgroundLight = Color(0xFFF5F7F8);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const elevatedLight = Color(0xFFF0F2F3);
  static const dividerLight = Color(0xFFDDE1E4);
  static const textPrimaryLight = Color(0xFF1A1C1E);
  static const textSecondaryLight = Color(0xFF5D666A);
  static const textDisabledLight = Color(0xFF9EA8AD);
  static const accentLight = Color(0xFF008DAA);
  static const actionLight = Color(0xFF006B82);
  static const fabLight = Color(0xFFC2185B);
  static const warningLight = Color(0xFFE65100);

  static GetzyColorSet of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _darkColors : _lightColors;
  }

  static const _darkColors = GetzyColorSet._(
    background: Color(0xFF0C1113),
    surface: Color(0xFF202528),
    elevated: Color(0xFF2A2F32),
    divider: Color(0xFF30373A),
    textPrimary: Color(0xFFE7EAEC),
    textSecondary: Color(0xFFB7BEC2),
    textDisabled: Color(0xFF5D666A),
    accent: Color(0xFF67D5FF),
    action: Color(0xFF008DAA),
    fab: Color(0xFFA9004C),
    warning: Color(0xFFFFD54F),
  );

  static const _lightColors = GetzyColorSet._(
    background: Color(0xFFF5F7F8),
    surface: Color(0xFFFFFFFF),
    elevated: Color(0xFFF0F2F3),
    divider: Color(0xFFDDE1E4),
    textPrimary: Color(0xFF1A1C1E),
    textSecondary: Color(0xFF5D666A),
    textDisabled: Color(0xFF9EA8AD),
    accent: Color(0xFF008DAA),
    action: Color(0xFF006B82),
    fab: Color(0xFFC2185B),
    warning: Color(0xFFE65100),
  );
}

class GetzyColorSet {
  const GetzyColorSet._({
    required this.background,
    required this.surface,
    required this.elevated,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.accent,
    required this.action,
    required this.fab,
    required this.warning,
  });

  final Color background;
  final Color surface;
  final Color elevated;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color accent;
  final Color action;
  final Color fab;
  final Color warning;
}

ThemeData buildDarkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: GetzyColors.accent,
    brightness: Brightness.dark,
    surface: GetzyColors.surface,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: GetzyColors.background,
    colorScheme: colorScheme.copyWith(
      primary: GetzyColors.accent,
      secondary: GetzyColors.fab,
      surface: GetzyColors.surface,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: GetzyColors.background,
      foregroundColor: GetzyColors.textPrimary,
      titleTextStyle: TextStyle(fontSize: 28, color: GetzyColors.textPrimary),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: GetzyColors.elevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    dividerTheme: const DividerThemeData(
      color: GetzyColors.divider,
      thickness: 1,
      space: 1,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: GetzyColors.fab,
      foregroundColor: Colors.white,
      extendedTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: GetzyColors.elevated,
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: GetzyColors.accent, width: 2),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: GetzyColors.textSecondary),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: GetzyColors.textSecondary,
      textColor: GetzyColors.textPrimary,
      subtitleTextStyle: TextStyle(color: GetzyColors.textSecondary),
    ),
    tabBarTheme: const TabBarTheme(
      dividerColor: GetzyColors.divider,
      indicatorColor: GetzyColors.accent,
      labelColor: GetzyColors.textPrimary,
      unselectedLabelColor: GetzyColors.textSecondary,
      labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      unselectedLabelStyle:
          TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    ),
  );
}

ThemeData buildLightTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: GetzyColors.accentLight,
    brightness: Brightness.light,
    surface: GetzyColors.surfaceLight,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: GetzyColors.backgroundLight,
    colorScheme: colorScheme.copyWith(
      primary: GetzyColors.accentLight,
      secondary: GetzyColors.fabLight,
      surface: GetzyColors.surfaceLight,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: GetzyColors.backgroundLight,
      foregroundColor: GetzyColors.textPrimaryLight,
      titleTextStyle: TextStyle(fontSize: 28, color: GetzyColors.textPrimaryLight),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: GetzyColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    dividerTheme: const DividerThemeData(
      color: GetzyColors.dividerLight,
      thickness: 1,
      space: 1,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: GetzyColors.fabLight,
      foregroundColor: Colors.white,
      extendedTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: GetzyColors.elevatedLight,
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: GetzyColors.accentLight, width: 2),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: GetzyColors.textSecondaryLight),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: GetzyColors.textSecondaryLight,
      textColor: GetzyColors.textPrimaryLight,
      subtitleTextStyle: TextStyle(color: GetzyColors.textSecondaryLight),
    ),
    tabBarTheme: const TabBarTheme(
      dividerColor: GetzyColors.dividerLight,
      indicatorColor: GetzyColors.accentLight,
      labelColor: GetzyColors.textPrimaryLight,
      unselectedLabelColor: GetzyColors.textSecondaryLight,
      labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      unselectedLabelStyle:
          TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    ),
  );
}
