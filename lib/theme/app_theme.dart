import 'package:flutter/material.dart';

import '../utils/system_ui.dart';

/// 深空蓝 + 霓虹青的视觉基调。
const Color appCyan = Color(0xFF35C8FF);
const Color appViolet = Color(0xFF7B6BFF);
const Color appAmber = Color(0xFFFFC451);
const Color appCrimson = Color(0xFFFF5A7A);

ThemeData buildLightTheme({String? fontFamily}) {
  const scheme = ColorScheme.light(
    primary: Color(0xFF0E63B8),
    primaryContainer: Color(0xFFD8EBFF),
    onPrimaryContainer: Color(0xFF082B52),
    secondary: Color(0xFF4F5F7A),
    onSecondary: Color(0xFFFFFFFF),
    surface: Color(0xFFFBFDFF),
    onSurface: Color(0xFF111827),
    surfaceContainerHighest: Color(0xFFEAF1FA),
    onSurfaceVariant: Color(0xFF5E6C82),
    outline: Color(0xFFD3DEEA),
    outlineVariant: Color(0xFFE6EDF5),
    error: Color(0xFFB3261E),
    surfaceTint: Colors.transparent,
    tertiary: Color(0xFF7B3FF2),
  );

  return _buildBase(
    colorScheme: scheme,
    scaffoldColor: const Color(0xFFEEF4FC),
    fontFamily: fontFamily,
  );
}

ThemeData buildDarkTheme({String? fontFamily}) {
  const scheme = ColorScheme.dark(
    primary: Color(0xFF57D6FF),
    onPrimary: Color(0xFF00253A),
    primaryContainer: Color(0xFF123C55),
    onPrimaryContainer: Color(0xFFC7F0FF),
    secondary: Color(0xFF9DB2D4),
    onSecondary: Color(0xFF14202F),
    surface: Color(0xFF121A2E),
    onSurface: Color(0xFFE7EEFA),
    surfaceContainerHighest: Color(0xFF1A2440),
    onSurfaceVariant: Color(0xFF97A6BE),
    outline: Color(0xFF2A3856),
    outlineVariant: Color(0xFF202C46),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF3A0A08),
    surfaceTint: Colors.transparent,
    tertiary: Color(0xFFB39DFF),
  );

  return _buildBase(
    colorScheme: scheme,
    scaffoldColor: const Color(0xFF070B18),
    fontFamily: fontFamily,
  );
}

ThemeData _buildBase({
  required ColorScheme colorScheme,
  required Color scaffoldColor,
  String? fontFamily,
}) {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: scaffoldColor,
    fontFamily: fontFamily,
  );
  final textTheme = base.textTheme.apply(
    bodyColor: colorScheme.onSurface,
    displayColor: colorScheme.onSurface,
    fontFamily: fontFamily,
  );

  return base.copyWith(
    textTheme: textTheme.copyWith(
      headlineMedium: textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 4,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: systemOverlayStyleFor(scaffoldColor),
      toolbarHeight: 52,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.7)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        side: BorderSide(color: colorScheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outline.withValues(alpha: 0.6),
      thickness: 0.6,
      space: 1,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    splashFactory: InkSparkle.splashFactory,
  );
}
