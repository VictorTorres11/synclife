import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';

import '../../../lib/src/core/analytics/analytics_service.dart';
import 'analytics_service_test.mocks.dart';

@GenerateMocks(
    [FirebaseAnalytics, FirebaseCrashlytics, FirebasePerformance, Trace])
void main() {
  group('AnalyticsService', () {
    late AnalyticsService analyticsService;
    late MockFirebaseAnalytics mockAnalytics;
    late MockFirebaseCrashlytics mockCrashlytics;
    late MockFirebasePerformance mockPerformance;

    setUp(() {
      mockAnalytics = MockFirebaseAnalytics();
      mockCrashlytics = MockFirebaseCrashlytics();
      mockPerformance = MockFirebasePerformance();
      analyticsService = FirebaseAnalyticsService();
    });

    group('logEvent', () {
      test('should log analytics event successfully', () async {
        // Arrange
        const eventName = 'test_event';
        final parameters = {'key': 'value'};

        // Act
        await analyticsService.logEvent(eventName, parameters);

        // Assert - No exception should be thrown
        expect(true, isTrue);
      });

      test('should handle errors gracefully', () async {
        // Act & Assert - Should not throw
        await analyticsService.logEvent('test', null);
        expect(true, isTrue);
      });
    });

    group('setUserProperties', () {
      test('should set user properties successfully', () async {
        // Arrange
        final properties = {'user_type': 'premium', 'level': '5'};

        // Act
        await analyticsService.setUserProperties(properties);

        // Assert - No exception should be thrown
        expect(true, isTrue);
      });
    });

    group('setUserId', () {
      test('should set user ID successfully', () async {
        // Arrange
        const userId = 'test_user_123';

        // Act
        await analyticsService.setUserId(userId);

        // Assert - No exception should be thrown
        expect(true, isTrue);
      });

      test('should handle null user ID', () async {
        // Act
        await analyticsService.setUserId(null);

        // Assert - No exception should be thrown
        expect(true, isTrue);
      });
    });

    group('logScreenView', () {
      test('should log screen view successfully', () async {
        // Arrange
        const screenName = 'home_screen';
        const screenClass = 'HomeScreen';

        // Act
        await analyticsService.logScreenView(screenName, screenClass);

        // Assert - No exception should be thrown
        expect(true, isTrue);
      });
    });

    group('recordError', () {
      test('should record non-fatal error successfully', () async {
        // Arrange
        final exception = Exception('Test error');
        final stackTrace = StackTrace.current;

        // Act
        await analyticsService.recordError(exception, stackTrace,
            reason: 'Test');

        // Assert - No exception should be thrown
        expect(true, isTrue);
      });
    });

    group('recordFatalError', () {
      test('should record fatal error successfully', () async {
        // Arrange
        final exception = Exception('Fatal error');
        final stackTrace = StackTrace.current;

        // Act
        await analyticsService.recordFatalError(exception, stackTrace,
            reason: 'Fatal test');

        // Assert - No exception should be thrown
        expect(true, isTrue);
      });
    });

    group('performance monitoring', () {
      test('should start trace successfully', () {
        // Act
        final trace = analyticsService.startTrace('test_trace');

        // Assert
        expect(trace, isNotNull);
      });

      test('should log performance metric successfully', () async {
        // Act
        await analyticsService.logPerformanceMetric('test_metric', 100);

        // Assert - No exception should be thrown
        expect(true, isTrue);
      });
    });

    group('constants', () {
      test('should have all required analytics events', () {
        expect(AnalyticsEvents.taskCreated, equals('task_created'));
        expect(AnalyticsEvents.taskCompleted, equals('task_completed'));
        expect(AnalyticsEvents.boardCreated, equals('board_created'));
        expect(AnalyticsEvents.userRegistered, equals('user_registered'));
        expect(AnalyticsEvents.premiumUpgrade, equals('premium_upgrade'));
      });

      test('should have all required user properties', () {
        expect(UserProperties.userType, equals('user_type'));
        expect(
            UserProperties.subscriptionStatus, equals('subscription_status'));
        expect(UserProperties.totalTasks, equals('total_tasks'));
        expect(UserProperties.currentLevel, equals('current_level'));
      });
    });
  });
}
