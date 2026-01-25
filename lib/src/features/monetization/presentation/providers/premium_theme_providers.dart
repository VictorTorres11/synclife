import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/firebase_premium_theme_service.dart';
import '../../domain/models/premium_theme.dart';
import '../../domain/services/premium_theme_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'monetization_providers.dart';

/// Provider for PremiumThemeService
final premiumThemeServiceProvider = Provider<PremiumThemeService>((ref) {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return FirebasePremiumThemeService(subscriptionService: subscriptionService);
});

/// Provider for all available themes
final allThemesProvider = FutureProvider<List<PremiumTheme>>((ref) {
  final service = ref.watch(premiumThemeServiceProvider);
  return service.getAllThemes();
});

/// Provider for themes available to current user
final availableThemesProvider = StreamProvider<List<PremiumTheme>>((ref) {
  final service = ref.watch(premiumThemeServiceProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return Stream.value([]);
  }

  return service.watchAvailableThemes(user.uid);
});

/// Provider for themes by category
final themesByCategoryProvider =
    FutureProvider.family<List<PremiumTheme>, ThemeCategory>((ref, category) {
  final service = ref.watch(premiumThemeServiceProvider);
  return service.getThemesByCategory(category);
});

/// Provider for specific theme
final themeProvider =
    FutureProvider.family<PremiumTheme?, String>((ref, themeId) {
  final service = ref.watch(premiumThemeServiceProvider);
  return service.getTheme(themeId);
});

/// Provider for user's theme preferences
final userThemePreferencesProvider =
    StreamProvider<UserThemePreferences>((ref) {
  final service = ref.watch(premiumThemeServiceProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return Stream.value(UserThemePreferences(
      userId: '',
      selectedThemeId: 'default_light',
      isDarkMode: false,
      followSystemTheme: true,
      updatedAt: DateTime.now(),
    ));
  }

  return service.watchUserThemePreferences(user.uid);
});

/// Provider for user's custom themes
final userCustomThemesProvider = FutureProvider<List<PremiumTheme>>((ref) {
  final service = ref.watch(premiumThemeServiceProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return [];
  }

  return service.getUserCustomThemes(user.uid);
});

/// Provider for active theme
final activeThemeProvider = FutureProvider<PremiumTheme>((ref) {
  final service = ref.watch(premiumThemeServiceProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    // Return default theme
    return PremiumTheme(
      id: 'default_light',
      name: 'Default Light',
      description: 'Clean and minimal light theme',
      category: ThemeCategory.standard,
      isPremium: false,
      colorScheme: PremiumColorScheme(
        lightScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        darkScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      createdAt: DateTime.now(),
    );
  }

  return service.getActiveTheme(user.uid);
});

/// Provider for active theme data
final activeThemeDataProvider = FutureProvider<ThemeData>((ref) {
  final service = ref.watch(premiumThemeServiceProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return ThemeData.light();
  }

  return service.getActiveThemeData(user.uid);
});

/// Provider for checking theme access
final canAccessThemeProvider =
    FutureProvider.family<bool, String>((ref, themeId) {
  final service = ref.watch(premiumThemeServiceProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return false;
  }

  return service.canAccessTheme(user.uid, themeId);
});

/// Provider for creating custom theme
final createCustomThemeProvider =
    FutureProvider.family<PremiumTheme, CreateCustomThemeParams>((ref, params) {
  final service = ref.watch(premiumThemeServiceProvider);
  return service.createCustomTheme(
    userId: params.userId,
    name: params.name,
    description: params.description,
    colorScheme: params.colorScheme,
    customProperties: params.customProperties,
  );
});

/// Provider for exporting theme
final exportThemeProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, themeId) {
  final service = ref.watch(premiumThemeServiceProvider);
  return service.exportTheme(themeId);
});

/// Provider for importing theme
final importThemeProvider = FutureProvider.family<PremiumTheme,
    ({String userId, Map<String, dynamic> themeData})>((ref, params) {
  final service = ref.watch(premiumThemeServiceProvider);
  return service.importTheme(params.userId, params.themeData);
});

/// Parameters for creating custom theme
class CreateCustomThemeParams {
  const CreateCustomThemeParams({
    required this.userId,
    required this.name,
    required this.description,
    required this.colorScheme,
    this.customProperties = const {},
  });

  final String userId;
  final String name;
  final String description;
  final PremiumColorScheme colorScheme;
  final Map<String, dynamic> customProperties;
}
