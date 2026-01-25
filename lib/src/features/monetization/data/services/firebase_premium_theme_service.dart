import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/premium_theme.dart';
import '../../domain/services/premium_theme_service.dart';
import '../../domain/services/subscription_service.dart';

/// Firebase implementation of PremiumThemeService
class FirebasePremiumThemeService implements PremiumThemeService {
  FirebasePremiumThemeService({
    FirebaseFirestore? firestore,
    SubscriptionService? subscriptionService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _subscriptionService = subscriptionService,
        _uuid = const Uuid();

  final FirebaseFirestore _firestore;
  final SubscriptionService? _subscriptionService;
  final Uuid _uuid;

  // Default theme ID for free users
  static const String _defaultThemeId = 'default_light';

  @override
  Future<List<PremiumTheme>> getAllThemes() async {
    try {
      final querySnapshot = await _firestore
          .collection('premium_themes')
          .orderBy('category')
          .orderBy('name')
          .get();

      final themes = querySnapshot.docs
          .map((doc) => PremiumTheme.fromMap(doc.data()))
          .toList();

      // Add built-in themes if not present
      final builtInThemes = await _getBuiltInThemes();
      final existingIds = themes.map((t) => t.id).toSet();

      for (final theme in builtInThemes) {
        if (!existingIds.contains(theme.id)) {
          themes.add(theme);
        }
      }

      return themes;
    } catch (e) {
      throw Exception('Failed to get all themes: $e');
    }
  }

  @override
  Future<List<PremiumTheme>> getAvailableThemes(String userId) async {
    try {
      final allThemes = await getAllThemes();

      // Check user's subscription status
      bool hasPremium = false;
      if (_subscriptionService != null) {
        final limitations =
            await _subscriptionService!.getUserLimitations(userId);
        hasPremium = limitations.canUsePremiumThemes;
      }

      // Filter themes based on subscription
      return allThemes.where((theme) {
        return !theme.isPremium || hasPremium;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get available themes: $e');
    }
  }

  @override
  Future<List<PremiumTheme>> getThemesByCategory(ThemeCategory category) async {
    try {
      final querySnapshot = await _firestore
          .collection('premium_themes')
          .where('category', isEqualTo: category.name)
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => PremiumTheme.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get themes by category: $e');
    }
  }

  @override
  Future<PremiumTheme?> getTheme(String themeId) async {
    try {
      // Check built-in themes first
      final builtInThemes = await _getBuiltInThemes();
      final builtInTheme =
          builtInThemes.where((t) => t.id == themeId).firstOrNull;

      if (builtInTheme != null) {
        return builtInTheme;
      }

      // Check Firestore themes
      final doc =
          await _firestore.collection('premium_themes').doc(themeId).get();

      if (!doc.exists) return null;

      return PremiumTheme.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get theme: $e');
    }
  }

  @override
  Future<UserThemePreferences> getUserThemePreferences(String userId) async {
    try {
      final doc = await _firestore
          .collection('user_theme_preferences')
          .doc(userId)
          .get();

      if (!doc.exists) {
        // Create default preferences
        final defaultPrefs = UserThemePreferences(
          userId: userId,
          selectedThemeId: _defaultThemeId,
          isDarkMode: false,
          followSystemTheme: true,
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('user_theme_preferences')
            .doc(userId)
            .set(defaultPrefs.toMap());

        return defaultPrefs;
      }

      return UserThemePreferences.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get user theme preferences: $e');
    }
  }

  @override
  Future<UserThemePreferences> updateUserThemePreferences(
    String userId,
    UserThemePreferences preferences,
  ) async {
    try {
      final updatedPrefs = preferences.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('user_theme_preferences')
          .doc(userId)
          .set(updatedPrefs.toMap());

      return updatedPrefs;
    } catch (e) {
      throw Exception('Failed to update user theme preferences: $e');
    }
  }

  @override
  Future<void> setActiveTheme(String userId, String themeId) async {
    try {
      // Verify user can access this theme
      final canAccess = await canAccessTheme(userId, themeId);
      if (!canAccess) {
        throw Exception('User cannot access theme: $themeId');
      }

      final preferences = await getUserThemePreferences(userId);
      await updateUserThemePreferences(
        userId,
        preferences.copyWith(selectedThemeId: themeId),
      );
    } catch (e) {
      throw Exception('Failed to set active theme: $e');
    }
  }

  @override
  Future<void> toggleDarkMode(String userId, bool isDarkMode) async {
    try {
      final preferences = await getUserThemePreferences(userId);
      await updateUserThemePreferences(
        userId,
        preferences.copyWith(isDarkMode: isDarkMode),
      );
    } catch (e) {
      throw Exception('Failed to toggle dark mode: $e');
    }
  }

  @override
  Future<void> toggleSystemTheme(String userId, bool followSystem) async {
    try {
      final preferences = await getUserThemePreferences(userId);
      await updateUserThemePreferences(
        userId,
        preferences.copyWith(followSystemTheme: followSystem),
      );
    } catch (e) {
      throw Exception('Failed to toggle system theme: $e');
    }
  }

  @override
  Future<PremiumTheme> createCustomTheme({
    required String userId,
    required String name,
    required String description,
    required PremiumColorScheme colorScheme,
    Map<String, dynamic> customProperties = const {},
  }) async {
    try {
      // Verify user has premium access
      if (_subscriptionService != null) {
        final limitations =
            await _subscriptionService!.getUserLimitations(userId);
        if (!limitations.canUsePremiumThemes) {
          throw Exception('Premium subscription required for custom themes');
        }
      }

      final theme = PremiumTheme(
        id: _uuid.v4(),
        name: name,
        description: description,
        category: ThemeCategory.custom,
        isPremium: true,
        colorScheme: colorScheme,
        createdAt: DateTime.now(),
        customProperties: {
          ...customProperties,
          'createdBy': userId,
        },
      );

      await _firestore
          .collection('premium_themes')
          .doc(theme.id)
          .set(theme.toMap());

      return theme;
    } catch (e) {
      throw Exception('Failed to create custom theme: $e');
    }
  }

  @override
  Future<PremiumTheme> updateCustomTheme(
    String themeId,
    PremiumTheme theme,
  ) async {
    try {
      await _firestore
          .collection('premium_themes')
          .doc(themeId)
          .update(theme.toMap());

      return theme;
    } catch (e) {
      throw Exception('Failed to update custom theme: $e');
    }
  }

  @override
  Future<void> deleteCustomTheme(String themeId) async {
    try {
      await _firestore.collection('premium_themes').doc(themeId).delete();
    } catch (e) {
      throw Exception('Failed to delete custom theme: $e');
    }
  }

  @override
  Future<List<PremiumTheme>> getUserCustomThemes(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('premium_themes')
          .where('customProperties.createdBy', isEqualTo: userId)
          .where('category', isEqualTo: ThemeCategory.custom.name)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PremiumTheme.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user custom themes: $e');
    }
  }

  @override
  Future<bool> canAccessTheme(String userId, String themeId) async {
    try {
      final theme = await getTheme(themeId);
      if (theme == null) return false;

      // Free themes are always accessible
      if (!theme.isPremium) return true;

      // Check premium access
      if (_subscriptionService != null) {
        final limitations =
            await _subscriptionService!.getUserLimitations(userId);
        return limitations.canUsePremiumThemes;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> exportTheme(String themeId) async {
    try {
      final theme = await getTheme(themeId);
      if (theme == null) {
        throw Exception('Theme not found: $themeId');
      }

      return {
        'version': '1.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'theme': theme.toMap(),
      };
    } catch (e) {
      throw Exception('Failed to export theme: $e');
    }
  }

  @override
  Future<PremiumTheme> importTheme(
    String userId,
    Map<String, dynamic> themeData,
  ) async {
    try {
      // Verify user has premium access
      if (_subscriptionService != null) {
        final limitations =
            await _subscriptionService!.getUserLimitations(userId);
        if (!limitations.canUsePremiumThemes) {
          throw Exception('Premium subscription required for theme import');
        }
      }

      final themeMap = Map<String, dynamic>.from(themeData['theme'] as Map);

      // Create new theme with new ID and user ownership
      final theme = PremiumTheme.fromMap(themeMap).copyWith(
        id: _uuid.v4(),
        category: ThemeCategory.custom,
        isPremium: true,
        createdAt: DateTime.now(),
        customProperties: {
          ...themeMap['customProperties'] as Map<String, dynamic>? ?? {},
          'createdBy': userId,
          'importedAt': DateTime.now().toIso8601String(),
        },
      );

      await _firestore
          .collection('premium_themes')
          .doc(theme.id)
          .set(theme.toMap());

      return theme;
    } catch (e) {
      throw Exception('Failed to import theme: $e');
    }
  }

  @override
  Future<PremiumTheme> getActiveTheme(String userId) async {
    try {
      final preferences = await getUserThemePreferences(userId);
      final theme = await getTheme(preferences.selectedThemeId);

      if (theme == null) {
        // Fallback to default theme
        return (await _getBuiltInThemes()).first;
      }

      return theme;
    } catch (e) {
      throw Exception('Failed to get active theme: $e');
    }
  }

  @override
  Future<ThemeData> getActiveThemeData(String userId) async {
    try {
      final preferences = await getUserThemePreferences(userId);
      final theme = await getActiveTheme(userId);

      // Determine if dark mode should be used
      bool isDark = preferences.isDarkMode;
      if (preferences.followSystemTheme) {
        // In a real app, you'd get this from the system
        // For now, use the preference
        isDark = preferences.isDarkMode;
      }

      return theme.toThemeData(isDark: isDark);
    } catch (e) {
      throw Exception('Failed to get active theme data: $e');
    }
  }

  @override
  Stream<UserThemePreferences> watchUserThemePreferences(String userId) {
    return _firestore
        .collection('user_theme_preferences')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserThemePreferences.fromMap(doc.data()!);
      } else {
        // Return default preferences
        return UserThemePreferences(
          userId: userId,
          selectedThemeId: _defaultThemeId,
          isDarkMode: false,
          followSystemTheme: true,
          updatedAt: DateTime.now(),
        );
      }
    });
  }

  @override
  Stream<List<PremiumTheme>> watchAvailableThemes(String userId) {
    return _firestore
        .collection('premium_themes')
        .orderBy('category')
        .orderBy('name')
        .snapshots()
        .asyncMap((snapshot) async {
      final themes =
          snapshot.docs.map((doc) => PremiumTheme.fromMap(doc.data())).toList();

      // Add built-in themes
      final builtInThemes = await _getBuiltInThemes();
      themes.addAll(builtInThemes);

      // Filter based on user's subscription
      bool hasPremium = false;
      if (_subscriptionService != null) {
        try {
          final limitations =
              await _subscriptionService!.getUserLimitations(userId);
          hasPremium = limitations.canUsePremiumThemes;
        } catch (e) {
          // Default to no premium access on error
        }
      }

      return themes.where((theme) {
        return !theme.isPremium || hasPremium;
      }).toList();
    });
  }

  // Private helper methods

  Future<List<PremiumTheme>> _getBuiltInThemes() async {
    return [
      PremiumTheme(
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
      ),
      PremiumTheme(
        id: 'nature_green',
        name: 'Nature Green',
        description: 'Calming green theme inspired by nature',
        category: ThemeCategory.nature,
        isPremium: true,
        colorScheme: PremiumColorScheme(
          lightScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.light,
          ),
          darkScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.dark,
          ),
        ),
        createdAt: DateTime.now(),
      ),
      PremiumTheme(
        id: 'vibrant_purple',
        name: 'Vibrant Purple',
        description: 'Bold and energetic purple theme',
        category: ThemeCategory.vibrant,
        isPremium: true,
        colorScheme: PremiumColorScheme(
          lightScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          darkScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
        ),
        createdAt: DateTime.now(),
      ),
      PremiumTheme(
        id: 'professional_navy',
        name: 'Professional Navy',
        description: 'Sophisticated navy theme for professionals',
        category: ThemeCategory.professional,
        isPremium: true,
        colorScheme: PremiumColorScheme(
          lightScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.light,
          ),
          darkScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.dark,
          ),
        ),
        createdAt: DateTime.now(),
      ),
    ];
  }
}
