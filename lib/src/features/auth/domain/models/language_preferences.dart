import 'package:equatable/equatable.dart';

/// Represents user language and region preferences
class LanguagePreferences extends Equatable {
  const LanguagePreferences({
    required this.languageCode,
    required this.countryCode,
    required this.isAutoDetected,
    required this.timezone,
    required this.dateFormat,
    required this.timeFormat,
  });

  final String languageCode;
  final String countryCode;
  final bool isAutoDetected;
  final String timezone;
  final String dateFormat;
  final String timeFormat;

  /// Default preferences with auto-detection enabled
  factory LanguagePreferences.defaultPreferences() {
    return const LanguagePreferences(
      languageCode: 'en',
      countryCode: 'US',
      isAutoDetected: true,
      timezone: 'UTC',
      dateFormat: 'MM/dd/yyyy',
      timeFormat: '12h',
    );
  }

  /// Creates preferences from map (Firestore)
  factory LanguagePreferences.fromMap(Map<String, dynamic> map) {
    return LanguagePreferences(
      languageCode: map['languageCode'] as String? ?? 'en',
      countryCode: map['countryCode'] as String? ?? 'US',
      isAutoDetected: map['isAutoDetected'] as bool? ?? true,
      timezone: map['timezone'] as String? ?? 'UTC',
      dateFormat: map['dateFormat'] as String? ?? 'MM/dd/yyyy',
      timeFormat: map['timeFormat'] as String? ?? '12h',
    );
  }

  /// Converts to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'languageCode': languageCode,
      'countryCode': countryCode,
      'isAutoDetected': isAutoDetected,
      'timezone': timezone,
      'dateFormat': dateFormat,
      'timeFormat': timeFormat,
    };
  }

  LanguagePreferences copyWith({
    String? languageCode,
    String? countryCode,
    bool? isAutoDetected,
    String? timezone,
    String? dateFormat,
    String? timeFormat,
  }) {
    return LanguagePreferences(
      languageCode: languageCode ?? this.languageCode,
      countryCode: countryCode ?? this.countryCode,
      isAutoDetected: isAutoDetected ?? this.isAutoDetected,
      timezone: timezone ?? this.timezone,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
    );
  }

  @override
  List<Object?> get props => [
        languageCode,
        countryCode,
        isAutoDetected,
        timezone,
        dateFormat,
        timeFormat,
      ];
}

/// Supported languages in the app
enum SupportedLanguage {
  english('en', 'English'),
  portuguese('pt', 'Português'),
  spanish('es', 'Español'),
  french('fr', 'Français');

  const SupportedLanguage(this.code, this.displayName);

  final String code;
  final String displayName;
}

/// Supported regions/countries
enum SupportedRegion {
  unitedStates('US', 'United States'),
  brazil('BR', 'Brazil'),
  spain('ES', 'Spain'),
  france('FR', 'France'),
  unitedKingdom('GB', 'United Kingdom'),
  canada('CA', 'Canada');

  const SupportedRegion(this.code, this.displayName);

  final String code;
  final String displayName;
}
