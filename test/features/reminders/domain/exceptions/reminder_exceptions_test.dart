import 'package:flutter_test/flutter_test.dart';
import 'package:synclife_app/src/features/reminders/domain/exceptions/reminder_exceptions.dart';
import 'package:synclife_app/src/features/reminders/domain/models/reminder.dart';
import 'package:synclife_app/src/features/reminders/domain/models/reminder_priority.dart';
import 'package:synclife_app/src/features/monetization/domain/models/user_limitations.dart';

void main() {
  group('LimitExceededException', () {
    test('should create exception with correct properties', () {
      // Arrange & Act
      const exception = LimitExceededException(
        limitationType: LimitationType.reminders,
        currentCount: 30,
        maxCount: 30,
      );

      // Assert
      expect(exception.limitationType, LimitationType.reminders);
      expect(exception.currentCount, 30);
      expect(exception.maxCount, 30);
    });

    test('should have correct toString representation', () {
      // Arrange
      const exception = LimitExceededException(
        limitationType: LimitationType.reminders,
        currentCount: 30,
        maxCount: 30,
      );

      // Act
      final result = exception.toString();

      // Assert
      expect(result, contains('Limit exceeded'));
      expect(result, contains('30/30'));
      expect(result, contains('reminders'));
    });

    test('should work with different limitation types', () {
      // Arrange & Act
      const exception = LimitExceededException(
        limitationType: LimitationType.activeTasks,
        currentCount: 50,
        maxCount: 50,
      );

      // Assert
      expect(exception.limitationType, LimitationType.activeTasks);
      expect(exception.currentCount, 50);
      expect(exception.maxCount, 50);
    });
  });

  group('ConversionException', () {
    test('should create exception with message only', () {
      // Arrange & Act
      const exception = ConversionException('Failed to create task');

      // Assert
      expect(exception.message, 'Failed to create task');
      expect(exception.originalReminder, isNull);
    });

    test('should create exception with message and original reminder', () {
      // Arrange
      final reminder = Reminder(
        id: 'reminder_1',
        content: 'Test reminder',
        userId: 'user_1',
        boardId: 'board_1',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        tags: ['test'],
        priority: ReminderPriority.high,
      );

      // Act
      final exception = ConversionException(
        'Failed to create task',
        originalReminder: reminder,
      );

      // Assert
      expect(exception.message, 'Failed to create task');
      expect(exception.originalReminder, reminder);
      expect(exception.originalReminder?.id, 'reminder_1');
      expect(exception.originalReminder?.content, 'Test reminder');
    });

    test('should have correct toString representation', () {
      // Arrange
      const exception = ConversionException('Task creation failed');

      // Act
      final result = exception.toString();

      // Assert
      expect(result, 'ConversionException: Task creation failed');
    });
  });

  group('ReminderException', () {
    test('should create exception with message', () {
      // Arrange & Act
      const exception = ReminderException('Something went wrong');

      // Assert
      expect(exception.message, 'Something went wrong');
    });

    test('should have correct toString representation', () {
      // Arrange
      const exception = ReminderException('Database error');

      // Act
      final result = exception.toString();

      // Assert
      expect(result, 'ReminderException: Database error');
    });

    test('should work with different error messages', () {
      // Arrange & Act
      const exception1 = ReminderException('Network error');
      const exception2 = ReminderException('Validation failed');
      const exception3 = ReminderException('Permission denied');

      // Assert
      expect(exception1.message, 'Network error');
      expect(exception2.message, 'Validation failed');
      expect(exception3.message, 'Permission denied');
    });
  });

  group('Exception type checks', () {
    test('all exceptions should implement Exception', () {
      // Arrange
      const limitException = LimitExceededException(
        limitationType: LimitationType.reminders,
        currentCount: 30,
        maxCount: 30,
      );
      const conversionException = ConversionException('Error');
      const reminderException = ReminderException('Error');

      // Assert
      expect(limitException, isA<Exception>());
      expect(conversionException, isA<Exception>());
      expect(reminderException, isA<Exception>());
    });
  });
}
