import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'mock_services.dart';

/// Property-based testing utilities for SyncLife
class PropertyTestRunner {
  static const int defaultIterations = 100;

  /// Runs a property test with the specified number of iterations
  static Future<void> runProperty<T>({
    required String description,
    required T Function() generator,
    required bool Function(T) property,
    int iterations = defaultIterations,
  }) async {
    for (int i = 0; i < iterations; i++) {
      final input = generator();
      final result = property(input);

      if (!result) {
        fail('Property failed on iteration $i with input: $input');
      }
    }
  }

  /// Runs an async property test
  static Future<void> runAsyncProperty<T>({
    required String description,
    required T Function() generator,
    required Future<bool> Function(T) property,
    int iterations = defaultIterations,
  }) async {
    for (int i = 0; i < iterations; i++) {
      final input = generator();
      final result = await property(input);

      if (!result) {
        fail('Property failed on iteration $i with input: $input');
      }
    }
  }
}

/// Test data generators
class TestGenerators {
  static final Random _random = Random();

  /// Generates random strings
  static String randomString({int minLength = 1, int maxLength = 50}) {
    final length = minLength + _random.nextInt(maxLength - minLength + 1);
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      Iterable.generate(
          length, (_) => chars.codeUnitAt(_random.nextInt(chars.length))),
    );
  }

  /// Generates random emails
  static String randomEmail() {
    final username = randomString(minLength: 3, maxLength: 15);
    final domain = randomString(minLength: 3, maxLength: 10);
    final tld = ['com', 'org', 'net', 'edu'][_random.nextInt(4)];
    return '$username@$domain.$tld';
  }

  /// Generates random UUIDs (simplified)
  static String randomUuid() {
    return '${randomString(minLength: 8, maxLength: 8)}-'
        '${randomString(minLength: 4, maxLength: 4)}-'
        '${randomString(minLength: 4, maxLength: 4)}-'
        '${randomString(minLength: 4, maxLength: 4)}-'
        '${randomString(minLength: 12, maxLength: 12)}';
  }

  /// Generates random integers within range
  static int randomInt({int min = 0, int max = 1000}) {
    return min + _random.nextInt(max - min + 1);
  }

  /// Generates random booleans
  static bool randomBool() {
    return _random.nextBool();
  }

  /// Generates random enum value
  static T randomEnumValue<T>(List<T> values) {
    return values[_random.nextInt(values.length)];
  }

  /// Generates random DateTime within a range
  static DateTime randomDateTime({
    DateTime? start,
    DateTime? end,
  }) {
    start ??= DateTime(2020);
    end ??= DateTime(2030);

    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;
    final randomMs = startMs + _random.nextInt(endMs - startMs);

    return DateTime.fromMillisecondsSinceEpoch(randomMs);
  }

  /// Generates random list of items
  static List<T> randomList<T>(
    T Function() generator, {
    int minLength = 0,
    int maxLength = 10,
  }) {
    final length = minLength + _random.nextInt(maxLength - minLength + 1);
    return List.generate(length, (_) => generator());
  }
}

/// Mock helpers
class MockHelpers {
  /// Creates a simple mock for testing
  static Map<String, dynamic> createMockData(String type) {
    switch (type) {
      case 'user':
        return MockData.mockUserData;
      case 'task':
        return MockData.mockTaskData;
      case 'board':
        return MockData.mockBoardData;
      default:
        return {};
    }
  }
}

/// Test assertions for property-based testing
class PropertyAssertions {
  /// Validates that a property holds for all generated inputs
  static Future<void> validateProperty<T>({
    required String description,
    required T Function() generator,
    required bool Function(T) property,
    int iterations = PropertyTestRunner.defaultIterations,
  }) async {
    await PropertyTestRunner.runProperty(
      description: description,
      generator: generator,
      property: property,
      iterations: iterations,
    );
  }

  /// Validates that an async property holds for all generated inputs
  static Future<void> validateAsyncProperty<T>({
    required String description,
    required T Function() generator,
    required Future<bool> Function(T) property,
    int iterations = PropertyTestRunner.defaultIterations,
  }) async {
    await PropertyTestRunner.runAsyncProperty(
      description: description,
      generator: generator,
      property: property,
      iterations: iterations,
    );
  }
}
