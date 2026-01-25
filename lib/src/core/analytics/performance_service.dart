import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Service for monitoring app performance
class PerformanceService {
  final FirebasePerformance _performance = FirebasePerformance.instance;

  /// Start monitoring a custom trace
  Future<PerformanceTrace> startTrace(String name) async {
    final trace = _performance.newTrace(name);
    await trace.start();
    return PerformanceTrace._(trace);
  }

  /// Monitor HTTP requests automatically
  Future<void> enableHttpMetricCollection() async {
    try {
      await _performance.setPerformanceCollectionEnabled(true);
    } catch (e) {
      debugPrint('Failed to enable HTTP metric collection: $e');
    }
  }

  /// Log custom metrics for app performance
  Future<void> logCustomMetric(String name, int value) async {
    try {
      final trace = _performance.newTrace('custom_metrics');
      await trace.start();
      trace.setMetric(name, value);
      await trace.stop();
    } catch (e) {
      debugPrint('Failed to log custom metric: $e');
    }
  }
}

/// Wrapper for Firebase Performance Trace
class PerformanceTrace {
  final Trace _trace;

  PerformanceTrace._(this._trace);

  /// Add a custom metric to the trace
  void setMetric(String name, int value) {
    _trace.setMetric(name, value);
  }

  /// Add an attribute to the trace
  void setAttribute(String name, String value) {
    _trace.putAttribute(name, value);
  }

  /// Stop the trace
  Future<void> stop() async {
    await _trace.stop();
  }
}

/// Common performance traces
class PerformanceTraces {
  static const String appStart = 'app_start';
  static const String userLogin = 'user_login';
  static const String taskSync = 'task_sync';
  static const String boardLoad = 'board_load';
  static const String taskCreation = 'task_creation';
  static const String dataSync = 'data_sync';
  static const String offlineSync = 'offline_sync';
  static const String notificationProcessing = 'notification_processing';
}

/// Performance metrics constants
class PerformanceMetrics {
  static const String syncDuration = 'sync_duration_ms';
  static const String taskCount = 'task_count';
  static const String boardCount = 'board_count';
  static const String offlineOperations = 'offline_operations';
  static const String networkRequests = 'network_requests';
  static const String cacheHits = 'cache_hits';
  static const String cacheMisses = 'cache_misses';
}
