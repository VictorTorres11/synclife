import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:synclife_app/src/features/reminders/data/services/reminder_conversion_service.dart';
import 'package:synclife_app/src/features/reminders/domain/models/models.dart';
import 'package:synclife_app/src/features/reminders/domain/services/services.dart';
import 'package:synclife_app/src/features/reminders/domain/exceptions/exceptions.dart';
import 'package:synclife_app/src/features/tasks/domain/models/task.dart';
import 'package:synclife_app/src/features/tasks/domain/models/create_task_request.dart';
import 'package:synclife_app/src/features/tasks/domain/models/task_recurrence.dart';
import 'package:synclife_app/src/features/tasks/domain/services/task_service.dart';

import 'reminder_conversion_service_test.mocks.dart';

@GenerateMocks([ReminderService, TaskService])
void main() {
  late ReminderConversionService conversionService;
  late MockReminderService mockReminderService;
  late MockTaskService mockTaskService;

  setUp(() {
    mockReminderService = MockReminderService();
    mockTaskService = MockTaskService();
    conversionService = ReminderConversionService(
      reminderService: mockReminderService,
      taskService: mockTaskService,
    );
  });

  group('ReminderConversionService', () {
    group('convertToTask', () {
      test('should successfully convert reminder to task', () async {
        // Arrange
        final reminder = Reminder(
          id: 'reminder_1',
          content: 'Buy groceries',
          userId: 'user_1',
          boardId: 'board_1',
          tags: ['shopping', 'urgent'],
          priority: ReminderPriority.high,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        final expectedTask = Task(
          id: 'task_1',
          title: 'Buy groceries',
          boardId: 'board_2',
          tags: ['shopping', 'urgent'],
          createdBy: 'user_1',
          recurrence: TaskRecurrence.none,
          isCompleted: false,
          createdAt: DateTime(2024, 1, 2),
          updatedAt: DateTime(2024, 1, 2),
        );

        when(mockTaskService.createTask(any))
            .thenAnswer((_) async => expectedTask);
        when(mockReminderService.deleteReminder(any, any))
            .thenAnswer((_) async => {});

        // Act
        final result = await conversionService.convertToTask(
          reminder: reminder,
          targetBoardId: 'board_2',
        );

        // Assert
        expect(result, equals(expectedTask));
        
        // Verify task was created with correct data
        final captured = verify(mockTaskService.createTask(captureAny))
            .captured.single as CreateTaskRequest;
        expect(captured.title, equals('Buy groceries'));
        expect(captured.boardId, equals('board_2'));
        expect(captured.tags, equals(['shopping', 'urgent']));
        expect(captured.createdBy, equals('user_1'));
        expect(captured.recurrence, equals(TaskRecurrence.none));

        // Verify reminder was deleted
        verify(mockReminderService.deleteReminder('reminder_1', 'user_1'))
            .called(1);
      });

      test('should copy tags from reminder to task', () async {
        // Arrange
        final reminder = Reminder(
          id: 'reminder_1',
          content: 'Test reminder',
          userId: 'user_1',
          boardId: 'board_1',
          tags: ['tag1', 'tag2', 'tag3'],
          priority: ReminderPriority.medium,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        final task = Task(
          id: 'task_1',
          title: 'Test reminder',
          boardId: 'board_1',
          tags: ['tag1', 'tag2', 'tag3'],
          createdBy: 'user_1',
          recurrence: TaskRecurrence.none,
          isCompleted: false,
          createdAt: DateTime(2024, 1, 2),
          updatedAt: DateTime(2024, 1, 2),
        );

        when(mockTaskService.createTask(any)).thenAnswer((_) async => task);
        when(mockReminderService.deleteReminder(any, any))
            .thenAnswer((_) async => {});

        // Act
        await conversionService.convertToTask(
          reminder: reminder,
          targetBoardId: 'board_1',
        );

        // Assert
        final captured = verify(mockTaskService.createTask(captureAny))
            .captured.single as CreateTaskRequest;
        expect(captured.tags, equals(['tag1', 'tag2', 'tag3']));
      });

      test('should use reminder content as task title', () async {
        // Arrange
        final reminder = Reminder(
          id: 'reminder_1',
          content: 'This is the reminder content',
          userId: 'user_1',
          boardId: 'board_1',
          tags: [],
          priority: ReminderPriority.low,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        final task = Task(
          id: 'task_1',
          title: 'This is the reminder content',
          boardId: 'board_1',
          tags: [],
          createdBy: 'user_1',
          recurrence: TaskRecurrence.none,
          isCompleted: false,
          createdAt: DateTime(2024, 1, 2),
          updatedAt: DateTime(2024, 1, 2),
        );

        when(mockTaskService.createTask(any)).thenAnswer((_) async => task);
        when(mockReminderService.deleteReminder(any, any))
            .thenAnswer((_) async => {});

        // Act
        await conversionService.convertToTask(
          reminder: reminder,
          targetBoardId: 'board_1',
        );

        // Assert
        final captured = verify(mockTaskService.createTask(captureAny))
            .captured.single as CreateTaskRequest;
        expect(captured.title, equals('This is the reminder content'));
      });

      test('should throw ConversionException when task creation fails',
          () async {
        // Arrange
        final reminder = Reminder(
          id: 'reminder_1',
          content: 'Test reminder',
          userId: 'user_1',
          boardId: 'board_1',
          tags: [],
          priority: ReminderPriority.medium,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        when(mockTaskService.createTask(any))
            .thenThrow(Exception('Task creation failed'));

        // Act & Assert
        expect(
          () => conversionService.convertToTask(
            reminder: reminder,
            targetBoardId: 'board_1',
          ),
          throwsA(isA<ConversionException>()),
        );

        // Verify reminder was NOT deleted
        verifyNever(mockReminderService.deleteReminder(any, any));
      });

      test('should include original reminder in ConversionException', () async {
        // Arrange
        final reminder = Reminder(
          id: 'reminder_1',
          content: 'Test reminder',
          userId: 'user_1',
          boardId: 'board_1',
          tags: [],
          priority: ReminderPriority.medium,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        when(mockTaskService.createTask(any))
            .thenThrow(Exception('Task creation failed'));

        // Act & Assert
        try {
          await conversionService.convertToTask(
            reminder: reminder,
            targetBoardId: 'board_1',
          );
          fail('Should have thrown ConversionException');
        } catch (e) {
          expect(e, isA<ConversionException>());
          final exception = e as ConversionException;
          expect(exception.originalReminder, equals(reminder));
          expect(exception.message, contains('Task creation failed'));
        }
      });

      test('should throw ConversionException when reminder deletion fails',
          () async {
        // Arrange
        final reminder = Reminder(
          id: 'reminder_1',
          content: 'Test reminder',
          userId: 'user_1',
          boardId: 'board_1',
          tags: [],
          priority: ReminderPriority.medium,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        final task = Task(
          id: 'task_1',
          title: 'Test reminder',
          boardId: 'board_1',
          tags: [],
          createdBy: 'user_1',
          recurrence: TaskRecurrence.none,
          isCompleted: false,
          createdAt: DateTime(2024, 1, 2),
          updatedAt: DateTime(2024, 1, 2),
        );

        when(mockTaskService.createTask(any)).thenAnswer((_) async => task);
        when(mockReminderService.deleteReminder(any, any))
            .thenThrow(Exception('Deletion failed'));

        // Act & Assert
        expect(
          () => conversionService.convertToTask(
            reminder: reminder,
            targetBoardId: 'board_1',
          ),
          throwsA(isA<ConversionException>()),
        );
      });

      test('should use target board ID for task creation', () async {
        // Arrange
        final reminder = Reminder(
          id: 'reminder_1',
          content: 'Test reminder',
          userId: 'user_1',
          boardId: 'board_1', // Original board
          tags: [],
          priority: ReminderPriority.medium,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        final task = Task(
          id: 'task_1',
          title: 'Test reminder',
          boardId: 'board_2', // Target board
          tags: [],
          createdBy: 'user_1',
          recurrence: TaskRecurrence.none,
          isCompleted: false,
          createdAt: DateTime(2024, 1, 2),
          updatedAt: DateTime(2024, 1, 2),
        );

        when(mockTaskService.createTask(any)).thenAnswer((_) async => task);
        when(mockReminderService.deleteReminder(any, any))
            .thenAnswer((_) async => {});

        // Act
        await conversionService.convertToTask(
          reminder: reminder,
          targetBoardId: 'board_2', // Different from reminder's board
        );

        // Assert
        final captured = verify(mockTaskService.createTask(captureAny))
            .captured.single as CreateTaskRequest;
        expect(captured.boardId, equals('board_2'));
      });

      test('should handle empty tags list', () async {
        // Arrange
        final reminder = Reminder(
          id: 'reminder_1',
          content: 'Test reminder',
          userId: 'user_1',
          boardId: 'board_1',
          tags: [], // Empty tags
          priority: ReminderPriority.medium,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        final task = Task(
          id: 'task_1',
          title: 'Test reminder',
          boardId: 'board_1',
          tags: [],
          createdBy: 'user_1',
          recurrence: TaskRecurrence.none,
          isCompleted: false,
          createdAt: DateTime(2024, 1, 2),
          updatedAt: DateTime(2024, 1, 2),
        );

        when(mockTaskService.createTask(any)).thenAnswer((_) async => task);
        when(mockReminderService.deleteReminder(any, any))
            .thenAnswer((_) async => {});

        // Act
        final result = await conversionService.convertToTask(
          reminder: reminder,
          targetBoardId: 'board_1',
        );

        // Assert
        expect(result.tags, isEmpty);
      });
    });
  });
}
