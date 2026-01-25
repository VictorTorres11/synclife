import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Represents a premium theme configuration
class PremiumTheme extends Equatable {
  const PremiumTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.isPremium,
    required this.colorScheme,
    required this.createdAt,
    this.previewImageUrl,
    this.customProperties = const {},
  });

  final String id;
  final String name;
  final String description;
  final ThemeCategory category;
  final bool isPremium;
  final PremiumColorScheme colorScheme;
  final DateTime createdAt;
  final String? previewImageUrl;
  final Map<String, dynamic> customProperties;

  /// Creates PremiumTheme from map data
  factory PremiumTheme.fromMap(Map<String, dynamic> map) => PremiumTheme(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String,
        category: ThemeCategory.values.firstWhere(
          (e) => e.name == map['category'],
          orElse: () => ThemeCategory.standard,
        ),
        isPremium: map['isPremium'] as bool,
        colorScheme: PremiumColorScheme.fromMap(
          Map<String, dynamic>.from(map['colorScheme'] as Map),
        ),
        createdAt: DateTime.parse(map['createdAt'] as String),
        previewImageUrl: map['previewImageUrl'] as String?,
        customProperties: Map<String, dynamic>.from(
          map['customProperties'] as Map? ?? {},
        ),
      );

  /// Converts PremiumTheme to map data
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category.name,
        'isPremium': isPremium,
        'colorScheme': colorScheme.toMap(),
        'createdAt': createdAt.toIso8601String(),
        'previewImageUrl': previewImageUrl,
        'customProperties': customProperties,
      };

  /// Converts to Flutter ThemeData
  ThemeData toThemeData({required bool isDark}) {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: isDark ? colorScheme.darkScheme : colorScheme.lightScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark
            ? colorScheme.darkScheme.surface
            : colorScheme.lightScheme.surface,
        foregroundColor: isDark
            ? colorScheme.darkScheme.onSurface
            : colorScheme.lightScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
      ),
    );
  }

  PremiumTheme copyWith({
    String? id,
    String? name,
    String? description,
    ThemeCategory? category,
    bool? isPremium,
    PremiumColorScheme? colorScheme,
    DateTime? createdAt,
    String? previewImageUrl,
    Map<String, dynamic>? customProperties,
  }) =>
      PremiumTheme(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        category: category ?? this.category,
        isPremium: isPremium ?? this.isPremium,
        colorScheme: colorScheme ?? this.colorScheme,
        createdAt: createdAt ?? this.createdAt,
        previewImageUrl: previewImageUrl ?? this.previewImageUrl,
        customProperties: customProperties ?? this.customProperties,
      );

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        category,
        isPremium,
        colorScheme,
        createdAt,
        previewImageUrl,
        customProperties,
      ];
}

/// Categories of premium themes
enum ThemeCategory {
  standard,
  nature,
  minimal,
  vibrant,
  professional,
  seasonal,
  custom,
}

/// Premium color scheme with light and dark variants
class PremiumColorScheme extends Equatable {
  const PremiumColorScheme({
    required this.lightScheme,
    required this.darkScheme,
  });

  final ColorScheme lightScheme;
  final ColorScheme darkScheme;

  /// Creates PremiumColorScheme from map data
  factory PremiumColorScheme.fromMap(Map<String, dynamic> map) =>
      PremiumColorScheme(
        lightScheme: _colorSchemeFromMap(
          Map<String, dynamic>.from(map['light'] as Map),
        ),
        darkScheme: _colorSchemeFromMap(
          Map<String, dynamic>.from(map['dark'] as Map),
        ),
      );

  /// Converts PremiumColorScheme to map data
  Map<String, dynamic> toMap() => {
        'light': _colorSchemeToMap(lightScheme),
        'dark': _colorSchemeToMap(darkScheme),
      };

  /// Creates a color scheme from hex color map
  static ColorScheme _colorSchemeFromMap(Map<String, dynamic> map) {
    return ColorScheme(
      brightness:
          map['brightness'] == 'dark' ? Brightness.dark : Brightness.light,
      primary: Color(int.parse(map['primary'] as String, radix: 16)),
      onPrimary: Color(int.parse(map['onPrimary'] as String, radix: 16)),
      secondary: Color(int.parse(map['secondary'] as String, radix: 16)),
      onSecondary: Color(int.parse(map['onSecondary'] as String, radix: 16)),
      error: Color(int.parse(map['error'] as String, radix: 16)),
      onError: Color(int.parse(map['onError'] as String, radix: 16)),
      surface: Color(int.parse(map['surface'] as String, radix: 16)),
      onSurface: Color(int.parse(map['onSurface'] as String, radix: 16)),
    );
  }

  /// Converts a color scheme to hex color map
  static Map<String, dynamic> _colorSchemeToMap(ColorScheme scheme) => {
        'brightness': scheme.brightness.name,
        'primary': scheme.primary.value.toRadixString(16),
        'onPrimary': scheme.onPrimary.value.toRadixString(16),
        'secondary': scheme.secondary.value.toRadixString(16),
        'onSecondary': scheme.onSecondary.value.toRadixString(16),
        'error': scheme.error.value.toRadixString(16),
        'onError': scheme.onError.value.toRadixString(16),
        'surface': scheme.surface.value.toRadixString(16),
        'onSurface': scheme.onSurface.value.toRadixString(16),
      };

  @override
  List<Object?> get props => [lightScheme, darkScheme];
}

/// User's theme preferences
class UserThemePreferences extends Equatable {
  const UserThemePreferences({
    required this.userId,
    required this.selectedThemeId,
    required this.isDarkMode,
    required this.followSystemTheme,
    required this.updatedAt,
    this.customizations = const {},
  });

  final String userId;
  final String selectedThemeId;
  final bool isDarkMode;
  final bool followSystemTheme;
  final DateTime updatedAt;
  final Map<String, dynamic> customizations;

  /// Creates UserThemePreferences from Firestore document data
  factory UserThemePreferences.fromMap(Map<String, dynamic> map) =>
      UserThemePreferences(
        userId: map['userId'] as String,
        selectedThemeId: map['selectedThemeId'] as String,
        isDarkMode: map['isDarkMode'] as bool,
        followSystemTheme: map['followSystemTheme'] as bool,
        updatedAt: DateTime.parse(map['updatedAt'] as String),
        customizations: Map<String, dynamic>.from(
          map['customizations'] as Map? ?? {},
        ),
      );

  /// Converts UserThemePreferences to Firestore document data
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'selectedThemeId': selectedThemeId,
        'isDarkMode': isDarkMode,
        'followSystemTheme': followSystemTheme,
        'updatedAt': updatedAt.toIso8601String(),
        'customizations': customizations,
      };

  UserThemePreferences copyWith({
    String? userId,
    String? selectedThemeId,
    bool? isDarkMode,
    bool? followSystemTheme,
    DateTime? updatedAt,
    Map<String, dynamic>? customizations,
  }) =>
      UserThemePreferences(
        userId: userId ?? this.userId,
        selectedThemeId: selectedThemeId ?? this.selectedThemeId,
        isDarkMode: isDarkMode ?? this.isDarkMode,
        followSystemTheme: followSystemTheme ?? this.followSystemTheme,
        updatedAt: updatedAt ?? this.updatedAt,
        customizations: customizations ?? this.customizations,
      );

  @override
  List<Object?> get props => [
        userId,
        selectedThemeId,
        isDarkMode,
        followSystemTheme,
        updatedAt,
        customizations,
      ];
}
