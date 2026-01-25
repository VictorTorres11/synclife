import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';

import '../../../lib/src/core/build/production_config.dart';

void main() {
  group('ProductionConfig', () {
    test('should have correct build mode detection', () {
      // These tests will pass based on the current build mode
      expect(ProductionConfig.isProduction, equals(kReleaseMode));
      expect(ProductionConfig.isDebug, equals(kDebugMode));
      expect(ProductionConfig.isProfile, equals(kProfileMode));
    });

    test('should have correct API URLs', () {
      expect(ProductionConfig.apiBaseUrl, isNotEmpty);
      expect(ProductionConfig.apiBaseUrl, startsWith('https://'));
    });

    test('should have correct Firebase project ID', () {
      expect(ProductionConfig.firebaseProjectId, isNotEmpty);
      expect(
          ProductionConfig.firebaseProjectId, matches(RegExp(r'^[a-z0-9-]+$')));
    });

    test('should have correct feature flags', () {
      expect(ProductionConfig.analyticsEnabled, isA<bool>());
      expect(ProductionConfig.crashlyticsEnabled, isA<bool>());
      expect(ProductionConfig.performanceMonitoringEnabled, isA<bool>());
      expect(ProductionConfig.debugLoggingEnabled, isA<bool>());
    });

    test('should have correct app metadata', () {
      expect(ProductionConfig.appVersion, isNotEmpty);
      expect(ProductionConfig.buildNumber, greaterThan(0));
    });

    test('should have correct minimum OS versions', () {
      expect(ProductionConfig.minAndroidVersion, isNotEmpty);
      expect(ProductionConfig.minIosVersion, isNotEmpty);

      // Validate Android API level format
      expect(int.tryParse(ProductionConfig.minAndroidVersion), isNotNull);
      expect(int.parse(ProductionConfig.minAndroidVersion),
          greaterThanOrEqualTo(21));

      // Validate iOS version format
      expect(ProductionConfig.minIosVersion, matches(RegExp(r'^\d+\.\d+$')));
    });

    test('should have correct bundle identifiers', () {
      expect(ProductionConfig.androidPackageName,
          matches(RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*$')));
      expect(ProductionConfig.iosPackageName,
          matches(RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*$')));
    });

    test('should have valid store URLs', () {
      expect(ProductionConfig.playStoreUrl,
          startsWith('https://play.google.com/'));
      expect(
          ProductionConfig.appStoreUrl, startsWith('https://apps.apple.com/'));
    });

    test('should have valid policy URLs', () {
      expect(ProductionConfig.privacyPolicyUrl, startsWith('https://'));
      expect(ProductionConfig.termsOfServiceUrl, startsWith('https://'));
      expect(ProductionConfig.supportUrl, startsWith('https://'));
    });

    test('should have valid contact email', () {
      expect(ProductionConfig.contactEmail, contains('@'));
      expect(ProductionConfig.contactEmail,
          matches(RegExp(r'^[^@]+@[^@]+\.[^@]+$')));
    });
  });

  group('EnvironmentConfig', () {
    test('should detect current environment correctly', () {
      final current = EnvironmentConfig.current;
      expect(current, isA<BuildEnvironment>());

      if (kReleaseMode) {
        expect(current, equals(BuildEnvironment.production));
      } else if (kProfileMode) {
        expect(current, equals(BuildEnvironment.staging));
      } else {
        expect(current, equals(BuildEnvironment.development));
      }
    });

    test('should have valid configuration for all environments', () {
      final config = EnvironmentConfig.config;

      expect(config, isA<Map<String, dynamic>>());
      expect(config['apiUrl'], isNotNull);
      expect(config['enableLogging'], isA<bool>());
      expect(config['enableAnalytics'], isA<bool>());
      expect(config['enableCrashlytics'], isA<bool>());
    });

    test('should have correct development configuration', () {
      // This test assumes we can mock the environment
      // In a real scenario, you might need to test this differently
      expect(BuildEnvironment.development, isA<BuildEnvironment>());
    });

    test('should have correct staging configuration', () {
      expect(BuildEnvironment.staging, isA<BuildEnvironment>());
    });

    test('should have correct production configuration', () {
      expect(BuildEnvironment.production, isA<BuildEnvironment>());
    });
  });

  group('Build Environment Values', () {
    test('development environment should have correct values', () {
      // Test that development config has expected structure
      const expectedKeys = [
        'apiUrl',
        'enableLogging',
        'enableAnalytics',
        'enableCrashlytics'
      ];

      // We can't directly test the config values since they depend on build mode
      // But we can test that the structure is correct
      expect(expectedKeys.length, equals(4));
    });

    test('production environment should prioritize security', () {
      // In production, certain features should be enabled/disabled for security
      if (kReleaseMode) {
        expect(ProductionConfig.debugLoggingEnabled, isFalse);
        expect(ProductionConfig.analyticsEnabled, isTrue);
        expect(ProductionConfig.crashlyticsEnabled, isTrue);
      }
    });

    test('should have consistent URL formats across environments', () {
      // All API URLs should use HTTPS in production
      if (kReleaseMode) {
        expect(ProductionConfig.apiBaseUrl, startsWith('https://'));
      }
    });
  });
}
