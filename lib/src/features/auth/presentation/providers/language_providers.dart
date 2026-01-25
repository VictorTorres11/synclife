import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/language_preferences.dart';

part 'language_providers.g.dart';

/// Provider for language preferences
@riverpod
class LanguagePreferencesNotifier extends _$LanguagePreferencesNotifier {
  static const String _prefsKey = 'language_preferences';

  @override
  Future<LanguagePreferences> build() async {
    return await _loadPreferences();
  }

  /// Load preferences from local storage
  Future<LanguagePreferences> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsJson = prefs.getString(_prefsKey);

      if (prefsJson != null) {
        final Map<String, dynamic> prefsMap =
            Map<String, dynamic>.from(Uri.splitQueryString(prefsJson));
        return LanguagePreferences.fromMap(prefsMap);
      }
    } catch (e) {
      // If loading fails, return default preferences
    }

    return LanguagePreferences.defaultPreferences();
  }

  /// Save preferences to local storage
  Future<void> _savePreferences(LanguagePreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsMap = preferences.toMap();
      final prefsJson = Uri(
          queryParameters: prefsMap.map(
        (key, value) => MapEntry(key, value.toString()),
      )).query;
      await prefs.setString(_prefsKey, prefsJson);
    } catch (e) {
      // Handle save error
    }
  }

  /// Update language code
  Future<void> updateLanguage(String languageCode) async {
    final currentPrefs = await future;
    final newPrefs = currentPrefs.copyWith(
      languageCode: languageCode,
      isAutoDetected: false,
    );
    state = AsyncValue.data(newPrefs);
    await _savePreferences(newPrefs);
  }

  /// Update country/region code
  Future<void> updateRegion(String countryCode) async {
    final currentPrefs = await future;
    final newPrefs = currentPrefs.copyWith(
      countryCode: countryCode,
      isAutoDetected: false,
    );
    state = AsyncValue.data(newPrefs);
    await _savePreferences(newPrefs);
  }

  /// Update timezone
  Future<void> updateTimezone(String timezone) async {
    final currentPrefs = await future;
    final newPrefs = currentPrefs.copyWith(timezone: timezone);
    state = AsyncValue.data(newPrefs);
    await _savePreferences(newPrefs);
  }

  /// Update date format
  Future<void> updateDateFormat(String dateFormat) async {
    final currentPrefs = await future;
    final newPrefs = currentPrefs.copyWith(dateFormat: dateFormat);
    state = AsyncValue.data(newPrefs);
    await _savePreferences(newPrefs);
  }

  /// Update time format
  Future<void> updateTimeFormat(String timeFormat) async {
    final currentPrefs = await future;
    final newPrefs = currentPrefs.copyWith(timeFormat: timeFormat);
    state = AsyncValue.data(newPrefs);
    await _savePreferences(newPrefs);
  }

  /// Enable auto-detection
  Future<void> enableAutoDetection() async {
    final currentPrefs = await future;
    final newPrefs = currentPrefs.copyWith(isAutoDetected: true);
    state = AsyncValue.data(newPrefs);
    await _savePreferences(newPrefs);
  }

  /// Reset to default preferences
  Future<void> resetToDefaults() async {
    final defaultPrefs = LanguagePreferences.defaultPreferences();
    state = AsyncValue.data(defaultPrefs);
    await _savePreferences(defaultPrefs);
  }
}

/// Provider for supported languages
@riverpod
List<SupportedLanguage> supportedLanguages(SupportedLanguagesRef ref) {
  return SupportedLanguage.values;
}

/// Provider for supported regions
@riverpod
List<SupportedRegion> supportedRegions(SupportedRegionsRef ref) {
  return SupportedRegion.values;
}
