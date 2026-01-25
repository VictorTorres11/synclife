import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Service for handling analytics, crash reporting, and performance monitoring
abstract class AnalyticsService {
  /// Log a custom event
  Future<void> logEvent(String name, Map<String, Object>? parameters);

  /// Set user properties
  Future<void> setUserProperties(Map<String, String> properties);

  /// Set user ID for analytics
  Future<void> setUserId(String? userId);

  /// Log screen view
  Future<void> logScreenView(String screenName, String screenClass);

  /// Record error for crash reporting
  Future<void> recordError(dynamic exception, StackTrace? stackTrace,
      {String? reason});

  /// Record fatal error
  Future<void> recordFatalError(dynamic exception, StackTrace stackTrace,
      {String? reason});

  /// Start performance trace
  Trace startTrace(String name);

  /// Log app performance metrics
  Future<void> logPerformanceMetric(String name, int value);
}

/// Firebase implementation of AnalyticsService
class FirebaseAnalyticsService implements AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  final FirebasePerformance _performance = FirebasePerformance.instance;

  @override
  Future<void> logEvent(String name, Map<String, Object>? parameters) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Failed to log analytics event: $e');
    }
  }

  @override
  Future<void> setUserProperties(Map<String, String> properties) async {
    try {
      for (final entry in properties.entries) {
        await _analytics.setUserProperty(name: entry.key, value: entry.value);
      }
    } catch (e) {
      debugPrint('Failed to set user properties: $e');
    }
  }

  @override
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
      await _crashlytics.setUserIdentifier(userId ?? '');
    } catch (e) {
      debugPrint('Failed to set user ID: $e');
    }
  }

  @override
  Future<void> logScreenView(String screenName, String screenClass) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      debugPrint('Failed to log screen view: $e');
    }
  }

  @override
  Future<void> recordError(dynamic exception, StackTrace? stackTrace,
      {String? reason}) async {
    try {
      await _crashlytics.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: false,
      );
    } catch (e) {
      debugPrint('Failed to record error: $e');
    }
  }

  @override
  Future<void> recordFatalError(dynamic exception, StackTrace stackTrace,
      {String? reason}) async {
    try {
      await _crashlytics.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: true,
      );
    } catch (e) {
      debugPrint('Failed to record fatal error: $e');
    }
  }

  @override
  Trace startTrace(String name) {
    return _performance.newTrace(name);
  }

  @override
  Future<void> logPerformanceMetric(String name, int value) async {
    try {
      final trace = startTrace(name);
      await trace.start();
      trace.setMetric(name, value);
      await trace.stop();
    } catch (e) {
      debugPrint('Failed to log performance metric: $e');
    }
  }
}

/// Analytics events constants
class AnalyticsEvents {
  static const String taskCreated = 'task_created';
  static const String taskCompleted = 'task_completed';
  static const String boardCreated = 'board_created';
  static const String boardJoined = 'board_joined';
  static const String userRegistered = 'user_registered';
  static const String userLogin = 'user_login';
  static const String premiumUpgrade = 'premium_upgrade';
  static const String storeItemPurchased = 'store_item_purchased';
  static const String inviteSent = 'invite_sent';
  static const String notificationReceived = 'notification_received';
  static const String syncCompleted = 'sync_completed';
  static const String syncFailed = 'sync_failed';
}

/// User properties constants
class UserProperties {
  static const String userType = 'user_type';
  static const String subscriptionStatus = 'subscription_status';
  static const String totalTasks = 'total_tasks';
  static const String totalBoards = 'total_boards';
  static const String currentLevel = 'current_level';
  static const String streakCount = 'streak_count';
}
