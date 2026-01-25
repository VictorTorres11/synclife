import 'package:flutter/foundation.dart';

/// Production build configuration
class ProductionConfig {
  static const bool _isProduction = kReleaseMode;

  /// Whether the app is running in production mode
  static bool get isProduction => _isProduction;

  /// Whether the app is running in debug mode
  static bool get isDebug => kDebugMode;

  /// Whether the app is running in profile mode
  static bool get isProfile => kProfileMode;

  /// API base URL based on build mode
  static String get apiBaseUrl {
    if (_isProduction) {
      return 'https://api.synclife.app';
    } else {
      return 'https://api-dev.synclife.app';
    }
  }

  /// Firebase project ID based on build mode
  static String get firebaseProjectId {
    if (_isProduction) {
      return 'synclife-prod';
    } else {
      return 'synclife-dev';
    }
  }

  /// Analytics collection enabled
  static bool get analyticsEnabled => _isProduction;

  /// Crashlytics collection enabled
  static bool get crashlyticsEnabled => _isProduction;

  /// Performance monitoring enabled
  static bool get performanceMonitoringEnabled => _isProduction;

  /// Debug logging enabled
  static bool get debugLoggingEnabled => !_isProduction;

  /// App version for production builds
  static const String appVersion = '1.0.0';

  /// Build number for production builds
  static const int buildNumber = 1;

  /// Minimum supported OS versions
  static const String minAndroidVersion = '21'; // Android 5.0
  static const String minIosVersion = '12.0'; // iOS 12.0

  /// Bundle identifiers
  static const String androidPackageName = 'com.synclife.app';
  static const String iosPackageName = 'com.synclife.app';

  /// Store URLs
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.synclife.app';
  static const String appStoreUrl =
      'https://apps.apple.com/app/synclife/id123456789';

  /// Privacy policy and terms URLs
  static const String privacyPolicyUrl = 'https://synclife.app/privacy';
  static const String termsOfServiceUrl = 'https://synclife.app/terms';

  /// Support and contact URLs
  static const String supportUrl = 'https://synclife.app/support';
  static const String contactEmail = 'support@synclife.app';
}

/// Build environment configuration
enum BuildEnvironment {
  development,
  staging,
  production,
}

/// Environment-specific configuration
class EnvironmentConfig {
  static BuildEnvironment get current {
    if (kReleaseMode) {
      return BuildEnvironment.production;
    } else if (kProfileMode) {
      return BuildEnvironment.staging;
    } else {
      return BuildEnvironment.development;
    }
  }

  static Map<String, dynamic> get config {
    switch (current) {
      case BuildEnvironment.development:
        return {
          'apiUrl': 'http://localhost:3000',
          'enableLogging': true,
          'enableAnalytics': false,
          'enableCrashlytics': false,
        };
      case BuildEnvironment.staging:
        return {
          'apiUrl': 'https://api-staging.synclife.app',
          'enableLogging': true,
          'enableAnalytics': true,
          'enableCrashlytics': true,
        };
      case BuildEnvironment.production:
        return {
          'apiUrl': 'https://api.synclife.app',
          'enableLogging': false,
          'enableAnalytics': true,
          'enableCrashlytics': true,
        };
    }
  }
}
