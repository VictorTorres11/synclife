import 'package:flutter_test/flutter_test.dart';
import 'package:synclife_app/src/core/sync/services/retry_service.dart';

void main() {
  group('RetryService', () {
    late RetryService retryService;

    setUp(() {
      retryService = RetryServiceImpl();
    });

    group('executeWithRetry', () {
      test('should succeed on first attempt', () async {
        var callCount = 0;

        final result = await retryService.executeWithRetry(() async {
          callCount++;
          return 'success';
        });

        expect(result, equals('success'));
        expect(callCount, equals(1));
      });

      test('should retry on retryable exceptions', () async {
        var callCount = 0;

        final result = await retryService.executeWithRetry(() async {
          callCount++;
          if (callCount < 3) {
            throw Exception('Network timeout');
          }
          return 'success';
        }, config: const RetryConfig(maxRetries: 3, baseDelay: Duration.zero));

        expect(result, equals('success'));
        expect(callCount, equals(3));
      });

      test('should fail after max retries', () async {
        var callCount = 0;

        try {
          await retryService.executeWithRetry(() async {
            callCount++;
            throw Exception('Network timeout');
          },
              config:
                  const RetryConfig(maxRetries: 2, baseDelay: Duration.zero));
        } catch (e) {
          // Expected to throw
        }

        expect(callCount, equals(3)); // Initial attempt + 2 retries
      });

      test('should not retry non-retryable exceptions', () async {
        var callCount = 0;

        expect(
          () => retryService.executeWithRetry(() async {
            callCount++;
            throw Exception('Authentication failed');
          }),
          throwsException,
        );

        expect(callCount, equals(1)); // Should not retry
      });
    });

    group('calculateDelay', () {
      test('should calculate exponential backoff correctly', () {
        const config = RetryConfig(
          baseDelay: Duration(seconds: 1),
          backoffMultiplier: 2.0,
          jitterEnabled: false,
        );

        final delay0 = retryService.calculateDelay(0, config);
        final delay1 = retryService.calculateDelay(1, config);
        final delay2 = retryService.calculateDelay(2, config);

        expect(delay0.inSeconds, equals(1));
        expect(delay1.inSeconds, equals(2));
        expect(delay2.inSeconds, equals(4));
      });

      test('should respect maximum delay', () {
        const config = RetryConfig(
          baseDelay: Duration(seconds: 1),
          maxDelay: Duration(seconds: 5),
          backoffMultiplier: 10.0,
          jitterEnabled: false,
        );

        final delay = retryService.calculateDelay(5, config);
        expect(delay.inSeconds, lessThanOrEqualTo(5));
      });

      test('should add jitter when enabled', () {
        const config = RetryConfig(
          baseDelay: Duration(seconds: 1),
          backoffMultiplier: 2.0,
          jitterEnabled: true,
          maxJitter: Duration(milliseconds: 100),
        );

        final delays =
            List.generate(10, (i) => retryService.calculateDelay(1, config));

        // With jitter, delays should vary
        final uniqueDelays = delays.toSet();
        expect(uniqueDelays.length, greaterThan(1));
      });
    });

    group('isRetryableException', () {
      test('should identify retryable network exceptions', () {
        final retryableExceptions = [
          Exception('Connection timeout'),
          Exception('Network error'),
          Exception('Socket exception'),
          Exception('HTTP 500 server error'),
          Exception('HTTP 502 bad gateway'),
          Exception('HTTP 503 service unavailable'),
          Exception('HTTP 504 gateway timeout'),
        ];

        for (final exception in retryableExceptions) {
          expect(
            retryService.isRetryableException(exception),
            isTrue,
            reason: 'Should be retryable: $exception',
          );
        }
      });

      test('should identify non-retryable exceptions', () {
        final nonRetryableExceptions = [
          Exception('Authentication failed'),
          Exception('Invalid request'),
          Exception('Permission denied'),
          Exception('Not found'),
        ];

        for (final exception in nonRetryableExceptions) {
          expect(
            retryService.isRetryableException(exception),
            isFalse,
            reason: 'Should not be retryable: $exception',
          );
        }
      });
    });

    group('RetryConfig', () {
      test('should create high priority config', () {
        final config = RetryConfig.highPriority();

        expect(config.maxRetries, equals(5));
        expect(config.baseDelay, equals(const Duration(milliseconds: 500)));
        expect(config.backoffMultiplier, equals(1.5));
      });

      test('should create low priority config', () {
        final config = RetryConfig.lowPriority();

        expect(config.maxRetries, equals(2));
        expect(config.baseDelay, equals(const Duration(seconds: 5)));
        expect(config.backoffMultiplier, equals(3.0));
      });

      test('should create critical config', () {
        final config = RetryConfig.critical();

        expect(config.maxRetries, equals(10));
        expect(config.baseDelay, equals(const Duration(milliseconds: 100)));
        expect(config.backoffMultiplier, equals(1.2));
      });

      test('should support copyWith', () {
        const originalConfig = RetryConfig();
        final modifiedConfig = originalConfig.copyWith(
          maxRetries: 5,
          baseDelay: const Duration(seconds: 2),
        );

        expect(modifiedConfig.maxRetries, equals(5));
        expect(modifiedConfig.baseDelay, equals(const Duration(seconds: 2)));
        expect(modifiedConfig.backoffMultiplier,
            equals(originalConfig.backoffMultiplier));
      });
    });
  });
}
