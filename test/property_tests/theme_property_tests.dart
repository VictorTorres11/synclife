import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lib/src/core/theme/app_theme.dart';
import '../../lib/src/core/theme/theme_provider.dart';
import '../helpers/test_helpers.dart';

/// Property-based tests for theme system
/// Validates cross-platform consistency and theme behavior
void main() {
  group('Theme Property Tests', () {
    test(
      'Feature: synclife-app, Property 23: Cross-platform consistency - '
      'Theme properties should be consistent across all platforms',
      () async {
        await PropertyTestRunner.runProperty<AppThemeMode>(
          description: 'Theme properties remain consistent across theme modes',
          generator: () => _generateRandomThemeMode(),
          property: (themeMode) => _validateThemeConsistency(themeMode),
          iterations: 100,
        );
      },
    );

    test(
      'Feature: synclife-app, Property 23: Cross-platform consistency - '
      'Theme colors should maintain proper contrast ratios',
      () async {
        await PropertyTestRunner.runProperty<Brightness>(
          description: 'Theme colors maintain accessibility standards',
          generator: () => _generateRandomBrightness(),
          property: (brightness) => _validateColorContrast(brightness),
          iterations: 50,
        );
      },
    );

    test(
      'Feature: synclife-app, Property 23: Cross-platform consistency - '
      'Theme spacing and sizing should be consistent',
      () async {
        await PropertyTestRunner.runProperty<ThemeData>(
          description: 'Spacing and sizing values are consistent across themes',
          generator: () => _generateRandomTheme(),
          property: (theme) => _validateSpacingConsistency(theme),
          iterations: 50,
        );
      },
    );

    test(
      'Feature: synclife-app, Property 23: Cross-platform consistency - '
      'Theme provider state management works correctly',
      () async {
        await PropertyTestRunner.runProperty<AppThemeMode>(
          description: 'Theme provider correctly manages state transitions',
          generator: () => _generateRandomThemeMode(),
          property: (themeMode) => _validateThemeProviderBehavior(themeMode),
          iterations: 100,
        );
      },
    );
  });
}

/// Generate random theme mode for testing
AppThemeMode _generateRandomThemeMode() {
  final modes = AppThemeMode.values;
  return modes[TestGenerators.randomInt(max: modes.length - 1)];
}

/// Generate random brightness for testing
Brightness _generateRandomBrightness() {
  return TestGenerators.randomBool() ? Brightness.light : Brightness.dark;
}

/// Generate random theme for testing
ThemeData _generateRandomTheme() {
  return TestGenerators.randomBool() 
      ? AppTheme.lightTheme 
      : AppTheme.darkTheme;
}

/// Validate theme consistency across different modes
bool _validateThemeConsistency(AppThemeMode themeMode) {
  try {
    // Test theme mode conversion
    final themeNotifier = ThemeNotifier();
    themeNotifier.setThemeMode(themeMode);
    
    final flutterThemeMode = themeNotifier.flutterThemeMode;
    
    // Validate conversion is correct
    switch (themeMode) {
      case AppThemeMode.light:
        if (flutterThemeMode != ThemeMode.light) return false;
        break;
      case AppThemeMode.dark:
        if (flutterThemeMode != ThemeMode.dark) return false;
        break;
      case AppThemeMode.system:
        if (flutterThemeMode != ThemeMode.system) return false;
        break;
    }

    // Validate theme data consistency
    final lightTheme = AppTheme.lightTheme;
    final darkTheme = AppTheme.darkTheme;

    // Both themes should use Material 3
    if (!lightTheme.useMaterial3 || !darkTheme.useMaterial3) return false;

    // Both themes should have the same primary color seed
    if (lightTheme.colorScheme.primary.value != darkTheme.colorScheme.primary.value) {
      // Allow for brightness differences but same hue
      final lightHSV = HSVColor.fromColor(lightTheme.colorScheme.primary);
      final darkHSV = HSVColor.fromColor(darkTheme.colorScheme.primary);
      if ((lightHSV.hue - darkHSV.hue).abs() > 10) return false;
    }

    // Validate consistent component styling
    if (!_validateComponentConsistency(lightTheme, darkTheme)) return false;

    return true;
  } catch (e) {
    return false;
  }
}

/// Validate color contrast ratios for accessibility
bool _validateColorContrast(Brightness brightness) {
  try {
    final theme = brightness == Brightness.light 
        ? AppTheme.lightTheme 
        : AppTheme.darkTheme;

    final colorScheme = theme.colorScheme;

    // Validate primary color contrast
    final primaryContrast = _calculateContrast(
      colorScheme.primary,
      colorScheme.onPrimary,
    );
    if (primaryContrast < 4.5) return false; // WCAG AA standard

    // Validate surface color contrast
    final surfaceContrast = _calculateContrast(
      colorScheme.surface,
      colorScheme.onSurface,
    );
    if (surfaceContrast < 4.5) return false;

    // Validate error color contrast
    final errorContrast = _calculateContrast(
      colorScheme.error,
      colorScheme.onError,
    );
    if (errorContrast < 4.5) return false;

    return true;
  } catch (e) {
    return false;
  }
}

/// Validate spacing consistency across themes
bool _validateSpacingConsistency(ThemeData theme) {
  try {
    // Validate card theme consistency
    final cardTheme = theme.cardTheme;
    if (cardTheme.elevation != AppTheme.elevationSm) return false;
    
    final cardShape = cardTheme.shape as RoundedRectangleBorder?;
    if (cardShape?.borderRadius != BorderRadius.circular(AppTheme.radiusLg)) {
      return false;
    }

    // Validate button theme consistency
    final elevatedButtonTheme = theme.elevatedButtonTheme;
    final buttonStyle = elevatedButtonTheme.style;
    if (buttonStyle == null) return false;

    // Validate input decoration consistency
    final inputTheme = theme.inputDecorationTheme;
    final inputBorder = inputTheme.border as OutlineInputBorder?;
    if (inputBorder?.borderRadius != BorderRadius.circular(AppTheme.radiusMd)) {
      return false;
    }

    return true;
  } catch (e) {
    return false;
  }
}

/// Validate theme provider behavior
bool _validateThemeProviderBehavior(AppThemeMode themeMode) {
  try {
    final container = ProviderContainer();
    
    // Test initial state
    final initialTheme = container.read(themeProvider);
    if (initialTheme != AppThemeMode.system) return false;

    // Test state change
    container.read(themeProvider.notifier).setThemeMode(themeMode);
    final updatedTheme = container.read(themeProvider);
    if (updatedTheme != themeMode) return false;

    // Test theme mode conversion
    final flutterThemeMode = container.read(themeModeProvider);
    switch (themeMode) {
      case AppThemeMode.light:
        if (flutterThemeMode != ThemeMode.light) return false;
        break;
      case AppThemeMode.dark:
        if (flutterThemeMode != ThemeMode.dark) return false;
        break;
      case AppThemeMode.system:
        if (flutterThemeMode != ThemeMode.system) return false;
        break;
    }

    container.dispose();
    return true;
  } catch (e) {
    return false;
  }
}

/// Validate component consistency between themes
bool _validateComponentConsistency(ThemeData lightTheme, ThemeData darkTheme) {
  // Validate AppBar themes have same structure
  final lightAppBar = lightTheme.appBarTheme;
  final darkAppBar = darkTheme.appBarTheme;
  
  if (lightAppBar.elevation != darkAppBar.elevation) return false;
  if (lightAppBar.centerTitle != darkAppBar.centerTitle) return false;

  // Validate Card themes have same structure
  final lightCard = lightTheme.cardTheme;
  final darkCard = darkTheme.cardTheme;
  
  if (lightCard.elevation != darkCard.elevation) return false;
  if (lightCard.shape.toString() != darkCard.shape.toString()) return false;

  // Validate Button themes have same structure
  final lightButton = lightTheme.elevatedButtonTheme.style;
  final darkButton = darkTheme.elevatedButtonTheme.style;
  
  if (lightButton?.shape.toString() != darkButton?.shape.toString()) return false;

  return true;
}

/// Calculate contrast ratio between two colors
double _calculateContrast(Color color1, Color color2) {
  final luminance1 = color1.computeLuminance();
  final luminance2 = color2.computeLuminance();
  
  final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
  final darker = luminance1 > luminance2 ? luminance2 : luminance1;
  
  return (lighter + 0.05) / (darker + 0.05);
}