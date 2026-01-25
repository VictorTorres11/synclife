import 'package:flutter/material.dart';
import '../models/premium_theme.dart';

/// Service for managing premium themes
abstract class PremiumThemeService {
  /// Gets all available themes
  Future<List<PremiumTheme>> getAllThemes();

  /// Gets themes available to a user (based on subscription)
  Future<List<PremiumTheme>> getAvailableThemes(String userId);

  /// Gets themes by category
  Future<List<PremiumTheme>> getThemesByCategory(ThemeCategory category);

  /// Gets a specific theme by ID
  Future<PremiumTheme?> getTheme(String themeId);

  /// Gets user's theme preferences
  Future<UserThemePreferences> getUserThemePreferences(String userId);

  /// Updates user's theme preferences
  Future<UserThemePreferences> updateUserThemePreferences(
    String userId,
    UserThemePreferences preferences,
  );

  /// Sets the active theme for a user
  Future<void> setActiveTheme(String userId, String themeId);

  /// Toggles dark mode for a user
  Future<void> toggleDarkMode(String userId, bool isDarkMode);

  /// Toggles system theme following for a user
  Future<void> toggleSystemTheme(String userId, bool followSystem);

  /// Creates a custom theme (premium feature)
  Future<PremiumTheme> createCustomTheme({
    required String userId,
    required String name,
    required String description,
    required PremiumColorScheme colorScheme,
    Map<String, dynamic> customProperties = const {},
  });

  /// Updates a custom theme
  Future<PremiumTheme> updateCustomTheme(
    String themeId,
    PremiumTheme theme,
  );

  /// Deletes a custom theme
  Future<void> deleteCustomTheme(String themeId);

  /// Gets user's custom themes
  Future<List<PremiumTheme>> getUserCustomThemes(String userId);

  /// Checks if user can access a theme
  Future<bool> canAccessTheme(String userId, String themeId);

  /// Exports a theme configuration
  Future<Map<String, dynamic>> exportTheme(String themeId);

  /// Imports a theme configuration
  Future<PremiumTheme> importTheme(
    String userId,
    Map<String, dynamic> themeData,
  );

  /// Gets the current active theme for a user
  Future<PremiumTheme> getActiveTheme(String userId);

  /// Gets the current ThemeData for a user
  Future<ThemeData> getActiveThemeData(String userId);

  /// Watches user's theme preferences
  Stream<UserThemePreferences> watchUserThemePreferences(String userId);

  /// Watches available themes for a user
  Stream<List<PremiumTheme>> watchAvailableThemes(String userId);
}
