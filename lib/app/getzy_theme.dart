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
}

ThemeData buildGetzyTheme() {
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
