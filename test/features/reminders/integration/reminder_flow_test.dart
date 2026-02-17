import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:synclife_app/src/features/reminders/domain/models/models.dart';
import 'package:synclife_app/src/features/reminders/domain/exceptions/exceptions.dart';
import 'package:synclife_app/src/features/reminders/data/services/firebase_reminder_service.dart';
import 'package:synclife_app/src/features/reminders/data/services/limited_reminder_service.dart';
import 'package:synclife_app/src/features/reminders/data/services/reminder_conversion_service.dart';
import 'package:synclife_app/src/features/tasks/domain/models/models.dart';
import 'package:synclife_app/src/features/tasks/domain/services/task_service.dart';
import 'package:synclife_app/src/features/monetization/domain/models/user_limitations.dart';

// Generate mocks
@GenerateMocks([
  LimitedReminderService,
  TaskService,
])
import 'reminder_flow_test.mocks.dart';

/// Integration tests for reminder flows
/// 
/// These tests validate end-to-end functionality including:
/// - Complete CRUD operations (10.1.2)
/// - Reminder to task conversion (10.1.3)
/// - Limitation enforcement (10.1.4)
/// - Board filtering (10.1.5)
/// - Search functionality (10.1.6)
void main() {
  group('Reminder Integration Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockLimitedReminderService mockLimitationService;
    late FirebaseReminderService reminderService;

    const testUserId = 'test-user-123';
    const testBoardId = 'test-board-456';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockLimitationService = MockLimitedReminderService();

      // Default mock behavior - allow creation
      when(mockLimitationService.checkReminderLimit(any))
          .thenAnswer((_) async => {});
      when(mockLimitationService.incrementReminderCount(any))
          .thenAnswer((_) async => {});
      when(mockLimitationService.decrementReminderCount(any))
          .thenAnswer((_) async => {});

      reminderService = FirebaseReminderService(
        firestore: fakeFirestore,
        limitationService: mockLimitationService,
      );
    });

    group('10.1.2 Complete CRUD Flow', () {
      test('should create, read, update, and delete a reminder successfully',
          () async {
        // CREATE: Create a new reminder
        final createdReminder = await reminderService.createReminder(
          content: 'Buy groceries',
          userId: testUserId,
          boardId: testBoardId,
          tags: ['shopping', 'urgent'],
          priority: ReminderPriority.high,
        );

        expect(createdReminder.id, isNotEmpty);
        expect(createdReminder.content, equals('Buy groceries'));
        expect(createdReminder.userId, equals(testUserId));
        expect(createdReminder.boardId, equals(testBoardId));
        expect(createdReminder.tags, equals(['shopping', 'urgent']));
        expect(createdReminder.priority, equals(ReminderPriority.high));
        verify(mockLimitationService.checkReminderLimit(testUserId)).called(1);
        verify(mockLimitationService.incrementReminderCount(testUserId))
            .called(1);

        // READ: Get all reminders
        final reminders = await reminderService.getReminders(testUserId);

        expect(reminders.length, equals(1));
        expect(reminders.first.id, equals(createdReminder.id));
        expect(reminders.first.content, equals('Buy groceries'));

        // UPDATE: Update the reminder
        final updatedReminder = await reminderService.updateReminder(
          createdReminder.id,
          content: 'Buy groceries and milk',
          priority: ReminderPriority.medium,
        );

        expect(updatedReminder.content, equals('Buy groceries and milk'));
        expect(updatedReminder.priority, equals(ReminderPriority.medium));
        expect(updatedReminder.id, equals(createdReminder.id));

        // Verify update persisted
        final remindersAfterUpdate =
            await reminderService.getReminders(testUserId);
        expect(remindersAfterUpdate.first.content,
            equals('Buy groceries and milk'));

        // DELETE: Delete the reminder
        await reminderService.deleteReminder(createdReminder.id, testUserId);

        verify(mockLimitationService.decrementReminderCount(testUserId))
            .called(1);

        // Verify deletion
        final remindersAfterDelete =
            await reminderService.getReminders(testUserId);
        expect(remindersAfterDelete, isEmpty);
      });

      test('should handle multiple reminders correctly', () async {
        // Create multiple reminders
        final reminder1 = await reminderService.createReminder(
          content: 'First reminder',
          userId: testUserId,
          boardId: testBoardId,
        );
        final reminder2 = await reminderService.createReminder(
          content: 'Second reminder',
          userId: testUserId,
          boardId: testBoardId,
        );
        final reminder3 = await reminderService.createReminder(
          content: 'Third reminder',
          userId: testUserId,
          boardId: testBoardId,
        );

        expect(reminder1.id, isNotEmpty);
        expect(reminder2.id, isNotEmpty);
        expect(reminder3.id, isNotEmpty);

        // Read all reminders
        final allReminders = await reminderService.getReminders(testUserId);

        expect(allReminders.length, equals(3));
        // Verify all reminders are present (order may vary in fake firestore)
        final contents = allReminders.map((r) => r.content).toSet();
        expect(contents, contains('First reminder'));
        expect(contents, contains('Second reminder'));
        expect(contents, contains('Third reminder'));
      });
    });

    group('10.1.3 Reminder to Task Conversion Flow', () {
      late MockTaskService mockTaskService;
      late ReminderConversionService conversionService;

      setUp(() {
        mockTaskService = MockTaskService();
        conversionService = ReminderConversionService(
          reminderService: reminderService,
          taskService: mockTaskService,
        );
      });

      test('should convert reminder to task successfully', () async {
        // Create a reminder first
        final reminder = await reminderService.createReminder(
          content: 'Important meeting notes',
          userId: testUserId,
          boardId: testBoardId,
          tags: ['work', 'meeting'],
          priority: ReminderPriority.high,
        );

        // Setup task creation mock
        final expectedTask = Task(
          id: 'task-123',
          title: 'Important meeting notes',
          boardId: testBoardId,
          recurrence: TaskRecurrence.none,
          isCompleted: false,
          tags: ['work', 'meeting'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: testUserId,
        );

        when(mockTaskService.createTask(any))
            .thenAnswer((_) async => expectedTask);

        // Convert reminder to task
        final task = await conversionService.convertToTask(
          reminder: reminder,
          targetBoardId: testBoardId,
        );

        // Verify task was created with correct data
        expect(task.id, equals('task-123'));
        expect(task.title, equals('Important meeting notes'));
        expect(task.tags, equals(['work', 'meeting']));
        expect(task.boardId, equals(testBoardId));

        // Verify reminder was deleted
        verify(mockLimitationService.decrementReminderCount(testUserId))
            .called(1);

        // Verify reminder no longer exists
        final reminders = await reminderService.getReminders(testUserId);
        expect(reminders, isEmpty);
      });

      test('should handle conversion failure gracefully', () async {
        // Create a reminder
        final reminder = await reminderService.createReminder(
          content: 'Test reminder',
          userId: testUserId,
          boardId: testBoardId,
        );

        // Setup task creation to fail
        when(mockTaskService.createTask(any))
            .thenThrow(Exception('Task creation failed'));

        // Attempt conversion
        expect(
          () => conversionService.convertToTask(
            reminder: reminder,
            targetBoardId: testBoardId,
          ),
          throwsA(isA<ConversionException>()),
        );

        // Verify reminder was NOT deleted (since task creation failed)
        verifyNever(mockLimitationService.decrementReminderCount(testUserId));

        // Verify reminder still exists
        final reminders = await reminderService.getReminders(testUserId);
        expect(reminders.length, equals(1));
      });

      test('should convert reminder to different board', () async {
        const targetBoardId = 'different-board-789';

        // Create a reminder
        final reminder = await reminderService.createReminder(
          content: 'Move to different board',
          userId: testUserId,
          boardId: testBoardId,
        );

        // Setup task creation mock
        final expectedTask = Task(
          id: 'task-456',
          title: 'Move to different board',
          boardId: targetBoardId,
          recurrence: TaskRecurrence.none,
          isCompleted: false,
          tags: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: testUserId,
        );

        when(mockTaskService.createTask(any))
            .thenAnswer((_) async => expectedTask);

        // Convert to different board
        final task = await conversionService.convertToTask(
          reminder: reminder,
          targetBoardId: targetBoardId,
        );

        expect(task.boardId, equals(targetBoardId));
      });
    });

    group('10.1.4 Limitation Enforcement Flow', () {
      test('should enforce reminder limit for free users', () async {
        // Setup limitation service to throw exception
        when(mockLimitationService.checkReminderLimit(testUserId))
            .thenThrow(ReminderLimitExceededException(
          limitationType: LimitationType.reminders,
          currentCount: 30,
          maxCount: 30,
        ));

        // Attempt to create reminder when at limit
        expect(
          () => reminderService.createReminder(
            content: 'This should fail',
            userId: testUserId,
            boardId: testBoardId,
          ),
          throwsA(isA<ReminderLimitExceededException>()),
        );

        // Verify counter was NOT incremented
        verifyNever(mockLimitationService.incrementReminderCount(testUserId));
      });

      test('should allow reminder creation when under limit', () async {
        // Create reminder (default mock allows creation)
        final reminder = await reminderService.createReminder(
          content: 'Under limit',
          userId: testUserId,
          boardId: testBoardId,
        );

        expect(reminder.content, equals('Under limit'));
        verify(mockLimitationService.checkReminderLimit(testUserId)).called(1);
        verify(mockLimitationService.incrementReminderCount(testUserId))
            .called(1);
      });

      test('should decrement counter when reminder is deleted', () async {
        // Create a reminder
        final reminder = await reminderService.createReminder(
          content: 'To be deleted',
          userId: testUserId,
          boardId: testBoardId,
        );

        // Delete reminder
        await reminderService.deleteReminder(reminder.id, testUserId);

        // Verify counter was decremented
        verify(mockLimitationService.decrementReminderCount(testUserId))
            .called(1);
      });

      test('should handle limitation check for premium users', () async {
        // Premium users should not hit limits (default mock allows creation)
        final reminder = await reminderService.createReminder(
          content: 'Premium user reminder',
          userId: testUserId,
          boardId: testBoardId,
        );

        expect(reminder.content, equals('Premium user reminder'));
        verify(mockLimitationService.checkReminderLimit(testUserId)).called(1);
      });
    });

    group('10.1.5 Board Filtering Flow', () {
      test('should filter reminders by board correctly', () async {
        const board1Id = 'board-1';
        const board2Id = 'board-2';

        // Create reminders in different boards
        final reminder1 = await reminderService.createReminder(
          content: 'Board 1 reminder A',
          userId: testUserId,
          boardId: board1Id,
        );
        final reminder2 = await reminderService.createReminder(
          content: 'Board 2 reminder',
          userId: testUserId,
          boardId: board2Id,
        );
        final reminder3 = await reminderService.createReminder(
          content: 'Board 1 reminder B',
          userId: testUserId,
          boardId: board1Id,
        );

        // Get reminders for board 1
        final board1Reminders =
            await reminderService.getRemindersByBoard(testUserId, board1Id);

        expect(board1Reminders.length, equals(2));
        expect(board1Reminders[0].content, equals('Board 1 reminder B'));
        expect(board1Reminders[1].content, equals('Board 1 reminder A'));
        expect(board1Reminders.every((r) => r.boardId == board1Id), isTrue);

        // Get reminders for board 2
        final board2Reminders =
            await reminderService.getRemindersByBoard(testUserId, board2Id);

        expect(board2Reminders.length, equals(1));
        expect(board2Reminders.first.content, equals('Board 2 reminder'));
        expect(board2Reminders.first.boardId, equals(board2Id));
      });

      test('should return empty list when board has no reminders', () async {
        const emptyBoardId = 'empty-board';

        // Get reminders for empty board
        final reminders = await reminderService.getRemindersByBoard(
            testUserId, emptyBoardId);

        expect(reminders, isEmpty);
      });
    });

    group('10.1.6 Search Functionality Flow', () {
      test('should search reminders by content (case-insensitive)', () async {
        // Create reminders with different content
        await reminderService.createReminder(
          content: 'Buy groceries at the store',
          userId: testUserId,
          boardId: testBoardId,
        );
        await reminderService.createReminder(
          content: 'Call dentist for appointment',
          userId: testUserId,
          boardId: testBoardId,
        );
        await reminderService.createReminder(
          content: 'Buy birthday gift',
          userId: testUserId,
          boardId: testBoardId,
        );

        // Search for "buy" (case-insensitive)
        final searchResults =
            await reminderService.searchReminders(testUserId, 'buy');

        expect(searchResults.length, equals(2));
        expect(searchResults.every((r) => r.content.toLowerCase().contains('buy')), isTrue);
      });

      test('should handle case-insensitive search correctly', () async {
        // Create a reminder
        await reminderService.createReminder(
          content: 'Important Meeting Notes',
          userId: testUserId,
          boardId: testBoardId,
        );

        // Search with different cases
        final resultsLower =
            await reminderService.searchReminders(testUserId, 'meeting');
        final resultsUpper =
            await reminderService.searchReminders(testUserId, 'MEETING');
        final resultsMixed =
            await reminderService.searchReminders(testUserId, 'MeEtInG');

        expect(resultsLower.length, equals(1));
        expect(resultsUpper.length, equals(1));
        expect(resultsMixed.length, equals(1));
        expect(resultsLower.first.content, equals('Important Meeting Notes'));
      });

      test('should return empty list when no matches found', () async {
        // Create a reminder
        await reminderService.createReminder(
          content: 'Buy groceries',
          userId: testUserId,
          boardId: testBoardId,
        );

        // Search for non-existent content
        final results =
            await reminderService.searchReminders(testUserId, 'dentist');

        expect(results, isEmpty);
      });

      test('should support partial content matching', () async {
        // Create a reminder
        await reminderService.createReminder(
          content: 'Remember to call the dentist tomorrow',
          userId: testUserId,
          boardId: testBoardId,
        );

        // Search with partial matches
        final resultsCall =
            await reminderService.searchReminders(testUserId, 'call');
        final resultsDentist =
            await reminderService.searchReminders(testUserId, 'dentist');
        final resultsTomorrow =
            await reminderService.searchReminders(testUserId, 'tomorrow');

        expect(resultsCall.length, equals(1));
        expect(resultsDentist.length, equals(1));
        expect(resultsTomorrow.length, equals(1));
      });
    });
  });
}
