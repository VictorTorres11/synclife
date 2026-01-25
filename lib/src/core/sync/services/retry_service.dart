import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Service for handling retry logic with exponential backoff
abstract class RetryService {
  /// Execute an operation with retry logic
  Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    RetryConfig? config,
  });

  /// Calculate the next retry delay
  Duration calculateDelay(int attemptNumber, RetryConfig config);

  /// Check if an exception is retryable
  bool isRetryableException(Exception exception);
}

/// Implementation of RetryService with exponential backoff
class RetryServiceImpl implements RetryService {
  RetryServiceImpl({
    RetryConfig? defaultConfig,
  }) : _defaultConfig = defaultConfig ?? const RetryConfig();

  final RetryConfig _defaultConfig;

  @override
  Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    RetryConfig? config,
  }) async {
    final retryConfig = config ?? _defaultConfig;
    Exception? lastException;

    for (int attempt = 0; attempt <= retryConfig.maxRetries; attempt++) {
      try {
        return await operation();
      } on Exception catch (e) {
        lastException = e;

        // Don't retry on the last attempt or if exception is not retryable
        if (attempt == retryConfig.maxRetries || !isRetryableException(e)) {
          rethrow;
        }

        // Calculate delay for next attempt
        final delay = calculateDelay(attempt, retryConfig);

        debugPrint(
          'Retry attempt ${attempt + 1}/${retryConfig.maxRetries} '
          'failed: $e. Retrying in ${delay.inMilliseconds}ms',
        );

        // Wait before next retry
        await Future.delayed(delay);
      }
    }

    // This should never be reached, but just in case
    throw lastException ?? Exception('Unknown retry error');
  }

  @override
  Duration calculateDelay(int attemptNumber, RetryConfig config) {
    // Exponential backoff: baseDelay * (backoffMultiplier ^ attemptNumber)
    final exponentialDelay = config.baseDelay.inMilliseconds *
        pow(config.backoffMultiplier, attemptNumber);

    // Add jitter to prevent thundering herd
    final jitter = config.jitterEnabled
        ? Random().nextDouble() * config.maxJitter.inMilliseconds
        : 0.0;

    final totalDelayMs = (exponentialDelay + jitter).round();

    // Cap at maximum delay
    final cappedDelayMs = min(totalDelayMs, config.maxDelay.inMilliseconds);

    return Duration(milliseconds: cappedDelayMs);
  }

  @override
  bool isRetryableException(Exception exception) {
    // Network-related exceptions are generally retryable
    final exceptionString = exception.toString().toLowerCase();

    final retryablePatterns = [
      'timeout',
      'connection',
      'network',
      'socket',
      'http',
      'server error',
      '500',
      '502',
      '503',
      '504',
    ];

    return retryablePatterns.any(
      (pattern) => exceptionString.contains(pattern),
    );
  }
}

/// Configuration for retry behavior
class RetryConfig {
  const RetryConfig({
    this.maxRetries = 3,
    this.baseDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(minutes: 5),
    this.backoffMultiplier = 2.0,
    this.jitterEnabled = true,
    this.maxJitter = const Duration(milliseconds: 500),
  });

  /// Maximum number of retry attempts
  final int maxRetries;

  /// Base delay before first retry
  final Duration baseDelay;

  /// Maximum delay between retries
  final Duration maxDelay;

  /// Multiplier for exponential backoff
  final double backoffMultiplier;

  /// Whether to add random jitter to delays
  final bool jitterEnabled;

  /// Maximum jitter to add to delays
  final Duration maxJitter;

  /// Create a config for high-priority operations (faster retries)
  factory RetryConfig.highPriority() => const RetryConfig(
        maxRetries: 5,
        baseDelay: Duration(milliseconds: 500),
        maxDelay: Duration(minutes: 2),
        backoffMultiplier: 1.5,
      );

  /// Create a config for low-priority operations (slower retries)
  factory RetryConfig.lowPriority() => const RetryConfig(
        maxRetries: 2,
        baseDelay: Duration(seconds: 5),
        maxDelay: Duration(minutes: 10),
        backoffMultiplier: 3.0,
      );

  /// Create a config for critical operations (aggressive retries)
  factory RetryConfig.critical() => const RetryConfig(
        maxRetries: 10,
        baseDelay: Duration(milliseconds: 100),
        maxDelay: Duration(minutes: 1),
        backoffMultiplier: 1.2,
      );

  RetryConfig copyWith({
    int? maxRetries,
    Duration? baseDelay,
    Duration? maxDelay,
    double? backoffMultiplier,
    bool? jitterEnabled,
    Duration? maxJitter,
  }) =>
      RetryConfig(
        maxRetries: maxRetries ?? this.maxRetries,
        baseDelay: baseDelay ?? this.baseDelay,
        maxDelay: maxDelay ?? this.maxDelay,
        backoffMultiplier: backoffMultiplier ?? this.backoffMultiplier,
        jitterEnabled: jitterEnabled ?? this.jitterEnabled,
        maxJitter: maxJitter ?? this.maxJitter,
      );
}
