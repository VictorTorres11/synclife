import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode options for the app
enum AppThemeMode {
  system,
  light,
  dark,
}

/// Theme state notifier that manages theme mode and persistence
class ThemeNotifier extends StateNotifier<AppThemeMode> {
  ThemeNotifier() : super(AppThemeMode.system) {
    _loadThemeMode();
  }

  static const String _themeKey = 'theme_mode';

  /// Load theme mode from shared preferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey);
      if (themeIndex != null && themeIndex < AppThemeMode.values.length) {
        state = AppThemeMode.values[themeIndex];
      }
    } catch (e) {
      // If loading fails, keep default system theme
      state = AppThemeMode.system;
    }
  }

  /// Set theme mode and persist to shared preferences
  Future<void> setThemeMode(AppThemeMode themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, themeMode.index);
      state = themeMode;
    } catch (e) {
      // If saving fails, still update the state
      state = themeMode;
    }
  }

  /// Convert AppThemeMode to Flutter's ThemeMode
  ThemeMode get flutterThemeMode {
    switch (state) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

/// Provider for theme state management
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>(
  (ref) => ThemeNotifier(),
);

/// Provider for getting the current Flutter ThemeMode
final themeModeProvider = Provider<ThemeMode>((ref) {
  final themeMode = ref.watch(themeProvider);
  switch (themeMode) {
    case AppThemeMode.light:
      return ThemeMode.light;
    case AppThemeMode.dark:
      return ThemeMode.dark;
    case AppThemeMode.system:
      return ThemeMode.system;
  }
});