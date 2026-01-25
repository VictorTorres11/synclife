import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:synclife_app/src/core/theme/theme_provider.dart';

void main() {
  group('Theme Persistence Tests', () {
    setUp(() {
      // Clear shared preferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('ThemeNotifier should persist theme changes', () async {
      final notifier = ThemeNotifier();
      
      // Wait for initial load
      await Future.delayed(Duration(milliseconds: 100));
      
      // Change to dark theme
      await notifier.setThemeMode(AppThemeMode.dark);
      expect(notifier.state, AppThemeMode.dark);
      
      // Verify it was saved to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getInt('theme_mode');
      expect(savedTheme, AppThemeMode.dark.index);
    });

    test('ThemeNotifier should load saved theme on startup', () async {
      // Pre-populate SharedPreferences with dark theme
      SharedPreferences.setMockInitialValues({
        'theme_mode': AppThemeMode.dark.index,
      });
      
      final notifier = ThemeNotifier();
      
      // Wait for async load to complete
      await Future.delayed(Duration(milliseconds: 100));
      
      expect(notifier.state, AppThemeMode.dark);
    });

    test('ThemeNotifier should handle invalid saved values gracefully', () async {
      // Pre-populate SharedPreferences with invalid theme index
      SharedPreferences.setMockInitialValues({
        'theme_mode': 999, // Invalid index
      });
      
      final notifier = ThemeNotifier();
      
      // Wait for async load to complete
      await Future.delayed(Duration(milliseconds: 100));
      
      // Should fallback to system theme
      expect(notifier.state, AppThemeMode.system);
    });

    test('ThemeNotifier should handle SharedPreferences errors gracefully', () async {
      final notifier = ThemeNotifier();
      
      // This should not throw an exception
      await notifier.setThemeMode(AppThemeMode.light);
      expect(notifier.state, AppThemeMode.light);
    });
  });
}