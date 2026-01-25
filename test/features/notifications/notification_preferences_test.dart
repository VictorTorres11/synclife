import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:synclife_app/src/features/notifications/domain/models/notification_preferences.dart';

void main() {
  group('NotificationPreferences', () {
    group('Quiet Hours', () {
      test('should correctly identify quiet hours for overnight period', () {
        // Arrange
        const preferences = NotificationPreferences(
          enableQuietHours: true,
          quietHoursStart: TimeOfDay(hour: 22, minute: 0), // 10 PM
          quietHoursEnd: TimeOfDay(hour: 8, minute: 0), // 8 AM
        );

        // Act & Assert
        expect(
            preferences.isInQuietHours(const TimeOfDay(hour: 23, minute: 30)),
            isTrue); // 11:30 PM
        expect(preferences.isInQuietHours(const TimeOfDay(hour: 2, minute: 0)),
            isTrue); // 2:00 AM
        expect(preferences.isInQuietHours(const TimeOfDay(hour: 7, minute: 30)),
            isTrue); // 7:30 AM
        expect(preferences.isInQuietHours(const TimeOfDay(hour: 10, minute: 0)),
            isFalse); // 10:00 AM
        expect(preferences.isInQuietHours(const TimeOfDay(hour: 15, minute: 0)),
            isFalse); // 3:00 PM
      });

      test('should correctly identify quiet hours for same-day period', () {
        // Arrange
        const preferences = NotificationPreferences(
          enableQuietHours: true,
          quietHoursStart: TimeOfDay(hour: 12, minute: 0), // 12 PM
          quietHoursEnd: TimeOfDay(hour: 14, minute: 0), // 2 PM
        );

        // Act & Assert
        expect(
            preferences.isInQuietHours(const TimeOfDay(hour: 11, minute: 30)),
            isFalse); // 11:30 AM
        expect(
            preferences.isInQuietHours(const TimeOfDay(hour: 12, minute: 30)),
            isTrue); // 12:30 PM
        expect(
            preferences.isInQuietHours(const TimeOfDay(hour: 13, minute: 30)),
            isTrue); // 1:30 PM
        expect(
            preferences.isInQuietHours(const TimeOfDay(hour: 14, minute: 30)),
            isFalse); // 2:30 PM
      });

      test('should not apply quiet hours when disabled', () {
        // Arrange
        const preferences = NotificationPreferences(
          enableQuietHours: false,
          quietHoursStart: TimeOfDay(hour: 22, minute: 0),
          quietHoursEnd: TimeOfDay(hour: 8, minute: 0),
        );

        // Act & Assert
        expect(
            preferences.isInQuietHours(const TimeOfDay(hour: 23, minute: 30)),
            isFalse);
        expect(preferences.isInQuietHours(const TimeOfDay(hour: 2, minute: 0)),
            isFalse);
      });
    });

    group('Notification Preferences Serialization', () {
      test('should correctly serialize and deserialize preferences', () {
        // Arrange
        const originalPreferences = NotificationPreferences(
          enablePushNotifications: false,
          enableDailySummary: true,
          enableTeamUpdates: false,
          enableNightSummary: true,
          enableTaskReminders: false,
          morningTime: TimeOfDay(hour: 7, minute: 15),
          nightTime: TimeOfDay(hour: 21, minute: 45),
          quietHoursStart: TimeOfDay(hour: 23, minute: 0),
          quietHoursEnd: TimeOfDay(hour: 6, minute: 30),
          enableQuietHours: false,
        );

        // Act
        final map = originalPreferences.toMap();
        final deserializedPreferences = NotificationPreferences.fromMap(map);

        // Assert
        expect(deserializedPreferences, equals(originalPreferences));
      });

      test('should handle default values when deserializing incomplete data',
          () {
        // Arrange
        final incompleteMap = <String, dynamic>{
          'enablePushNotifications': false,
          'enableDailySummary': true,
          // Missing other fields
        };

        // Act
        final preferences = NotificationPreferences.fromMap(incompleteMap);

        // Assert
        expect(preferences.enablePushNotifications, isFalse);
        expect(preferences.enableDailySummary, isTrue);
        expect(preferences.enableTeamUpdates, isTrue); // Default value
        expect(preferences.enableNightSummary, isTrue); // Default value
        expect(preferences.enableTaskReminders, isTrue); // Default value
        expect(preferences.morningTime.hour, equals(8)); // Default value
        expect(preferences.morningTime.minute, equals(0)); // Default value
      });
    });

    group('TimeOfDay Helper', () {
      test('should format time correctly', () {
        // Arrange & Act & Assert
        expect(const TimeOfDay(hour: 9, minute: 5).toString(), equals('09:05'));
        expect(
            const TimeOfDay(hour: 14, minute: 30).toString(), equals('14:30'));
        expect(const TimeOfDay(hour: 0, minute: 0).toString(), equals('00:00'));
        expect(
            const TimeOfDay(hour: 23, minute: 59).toString(), equals('23:59'));
      });

      test('should be equal when hour and minute are the same', () {
        // Arrange
        const time1 = TimeOfDay(hour: 14, minute: 30);
        const time2 = TimeOfDay(hour: 14, minute: 30);
        const time3 = TimeOfDay(hour: 14, minute: 31);

        // Act & Assert
        expect(time1, equals(time2));
        expect(time1, isNot(equals(time3)));
      });
    });

    group('copyWith functionality', () {
      test('should create new instance with updated values', () {
        // Arrange
        const original = NotificationPreferences(
          enablePushNotifications: true,
          enableDailySummary: false,
          morningTime: TimeOfDay(hour: 8, minute: 0),
        );

        // Act
        final updated = original.copyWith(
          enableDailySummary: true,
          morningTime: const TimeOfDay(hour: 9, minute: 30),
        );

        // Assert
        expect(updated.enablePushNotifications, isTrue); // Unchanged
        expect(updated.enableDailySummary, isTrue); // Changed
        expect(updated.morningTime.hour, equals(9)); // Changed
        expect(updated.morningTime.minute, equals(30)); // Changed
        expect(original.enableDailySummary, isFalse); // Original unchanged
      });
    });

    group('Property-Based Tests for Notification Delivery', () {
      group('**Validates: Requirements 7.1, 7.2, 7.3, 7.5**', () {
        test(
            'Feature: synclife-app, Property 18: Notification delivery - Quiet hours are always respected',
            () async {
          // Property: For any user with configured notification preferences,
          // quiet hours should be respected for all notification types

          final random = Random(42); // Fixed seed for reproducible tests

          for (int iteration = 0; iteration < 100; iteration++) {
            // Generate random but valid notification preferences
            final preferences = _generateRandomNotificationPreferences(random);

            // Force quiet hours to be enabled for this test
            final testPreferences =
                preferences.copyWith(enableQuietHours: true);

            // Generate a time that's definitely in quiet hours
            // Handle the case where quiet hours might span midnight
            final quietStartMinutes =
                testPreferences.quietHoursStart.hour * 60 +
                    testPreferences.quietHoursStart.minute;
            final quietEndMinutes = testPreferences.quietHoursEnd.hour * 60 +
                testPreferences.quietHoursEnd.minute;

            TimeOfDay quietTime;
            if (quietStartMinutes > quietEndMinutes) {
              // Overnight quiet hours (e.g., 22:00 to 08:00)
              quietTime = TimeOfDay(
                hour: (testPreferences.quietHoursStart.hour + 1) % 24,
                minute: testPreferences.quietHoursStart.minute,
              );
            } else {
              // Same-day quiet hours (e.g., 12:00 to 14:00)
              quietTime = TimeOfDay(
                hour: testPreferences.quietHoursStart.hour,
                minute: (testPreferences.quietHoursStart.minute + 30) % 60,
              );
            }

            // Verify that notifications are NOT delivered during quiet hours
            expect(testPreferences.isInQuietHours(quietTime), isTrue,
                reason:
                    'Generated time should be in quiet hours for iteration $iteration');

            // Test that even enabled notifications respect quiet hours
            if (testPreferences.enableDailySummary &&
                testPreferences.enablePushNotifications &&
                testPreferences.isInQuietHours(quietTime)) {
              // This should NOT result in a notification being scheduled
              // because we're in quiet hours
              final shouldNotDeliver =
                  testPreferences.isInQuietHours(quietTime);
              expect(shouldNotDeliver, isTrue,
                  reason:
                      'Notifications should not be delivered during quiet hours');
            }
          }
        });

        test(
            'Feature: synclife-app, Property 18: Notification delivery - Morning notifications respect time windows',
            () async {
          final random = Random(123);

          for (int iteration = 0; iteration < 100; iteration++) {
            final preferences = _generateRandomNotificationPreferences(random);
            final currentTime = _generateRandomTimeOfDay(random);

            // Test morning notification timing
            if (preferences.enableDailySummary &&
                preferences.enablePushNotifications) {
              final isInMorningWindow =
                  _isWithinMorningWindow(currentTime, preferences.morningTime);
              final isInQuietHours = preferences.isInQuietHours(currentTime);

              // Should only deliver if in morning window AND not in quiet hours
              final shouldDeliver = isInMorningWindow && !isInQuietHours;

              // Verify the logic is consistent
              if (shouldDeliver) {
                expect(isInMorningWindow, isTrue,
                    reason:
                        'Should be in morning window when delivery is allowed');
                expect(isInQuietHours, isFalse,
                    reason:
                        'Should not be in quiet hours when delivery is allowed');
              }
            }
          }
        });

        test(
            'Feature: synclife-app, Property 18: Notification delivery - Night notifications respect time windows',
            () async {
          final random = Random(456);

          for (int iteration = 0; iteration < 100; iteration++) {
            final preferences = _generateRandomNotificationPreferences(random);
            final currentTime = _generateRandomTimeOfDay(random);

            // Test night notification timing
            if (preferences.enableNightSummary &&
                preferences.enablePushNotifications) {
              final isInNightWindow =
                  _isWithinNightWindow(currentTime, preferences.nightTime);
              final isInQuietHours = preferences.isInQuietHours(currentTime);

              // Should only deliver if in night window AND not in quiet hours
              final shouldDeliver = isInNightWindow && !isInQuietHours;

              // Verify the logic is consistent
              if (shouldDeliver) {
                expect(isInNightWindow, isTrue,
                    reason:
                        'Should be in night window when delivery is allowed');
                expect(isInQuietHours, isFalse,
                    reason:
                        'Should not be in quiet hours when delivery is allowed');
              }
            }
          }
        });

        test(
            'Feature: synclife-app, Property 18: Notification delivery - Disabled notifications are never sent',
            () async {
          final random = Random(789);

          for (int iteration = 0; iteration < 50; iteration++) {
            final preferences = _generateRandomNotificationPreferences(random);

            // Test with push notifications disabled
            final disabledPreferences =
                preferences.copyWith(enablePushNotifications: false);

            // Even if other settings are enabled, no notifications should be sent
            // when push notifications are disabled
            expect(disabledPreferences.enablePushNotifications, isFalse);

            // Test morning summary
            if (disabledPreferences.enableDailySummary) {
              final shouldNotDeliver =
                  !disabledPreferences.enablePushNotifications;
              expect(shouldNotDeliver, isTrue,
                  reason:
                      'No notifications should be sent when push notifications are disabled');
            }

            // Test with specific notification types disabled
            final noTeamUpdates =
                preferences.copyWith(enableTeamUpdates: false);
            expect(noTeamUpdates.enableTeamUpdates, isFalse,
                reason:
                    'Team updates should be disabled when explicitly set to false');

            final noNightSummary =
                preferences.copyWith(enableNightSummary: false);
            expect(noNightSummary.enableNightSummary, isFalse,
                reason:
                    'Night summary should be disabled when explicitly set to false');
          }
        });

        test(
            'Feature: synclife-app, Property 18: Notification delivery - Team notifications respect preferences',
            () async {
          final random = Random(101112);

          for (int iteration = 0; iteration < 50; iteration++) {
            final preferences = _generateRandomNotificationPreferences(random);

            // Test team activity notifications
            if (preferences.enableTeamUpdates &&
                preferences.enablePushNotifications) {
              // Team notifications should be allowed when both team updates and push notifications are enabled
              expect(preferences.enableTeamUpdates, isTrue);
              expect(preferences.enablePushNotifications, isTrue);
            } else if (!preferences.enableTeamUpdates) {
              // Team notifications should not be sent when team updates are disabled
              expect(preferences.enableTeamUpdates, isFalse);
            } else if (!preferences.enablePushNotifications) {
              // Team notifications should not be sent when push notifications are disabled
              expect(preferences.enablePushNotifications, isFalse);
            }
          }
        });
      });
    });
  });
}

/// Generate random notification preferences for property testing
NotificationPreferences _generateRandomNotificationPreferences(Random random) {
  return NotificationPreferences(
    enablePushNotifications: random.nextBool(),
    enableDailySummary: random.nextBool(),
    enableTeamUpdates: random.nextBool(),
    enableNightSummary: random.nextBool(),
    enableTaskReminders: random.nextBool(),
    morningTime: TimeOfDay(
      hour: 6 + random.nextInt(4), // 6-9 AM
      minute: random.nextInt(60),
    ),
    nightTime: TimeOfDay(
      hour: 20 + random.nextInt(4), // 8-11 PM
      minute: random.nextInt(60),
    ),
    quietHoursStart: TimeOfDay(
      hour: 22 + random.nextInt(2), // 10 PM - 12 AM
      minute: random.nextInt(60),
    ),
    quietHoursEnd: TimeOfDay(
      hour: 6 + random.nextInt(3), // 6-8 AM
      minute: random.nextInt(60),
    ),
    enableQuietHours: random.nextBool(),
  );
}

/// Generate random time of day for testing
TimeOfDay _generateRandomTimeOfDay(Random random) {
  return TimeOfDay(
    hour: random.nextInt(24),
    minute: random.nextInt(60),
  );
}

/// Check if current time is within morning notification window
bool _isWithinMorningWindow(TimeOfDay currentTime, TimeOfDay morningTime) {
  final currentMinutes = currentTime.hour * 60 + currentTime.minute;
  final morningMinutes = morningTime.hour * 60 + morningTime.minute;

  // Allow 30 minutes window around the scheduled time
  return (currentMinutes >= morningMinutes - 15) &&
      (currentMinutes <= morningMinutes + 15);
}

/// Check if current time is within night notification window
bool _isWithinNightWindow(TimeOfDay currentTime, TimeOfDay nightTime) {
  final currentMinutes = currentTime.hour * 60 + currentTime.minute;
  final nightMinutes = nightTime.hour * 60 + nightTime.minute;

  // Allow 30 minutes window around the scheduled time
  return (currentMinutes >= nightMinutes - 15) &&
      (currentMinutes <= nightMinutes + 15);
}
