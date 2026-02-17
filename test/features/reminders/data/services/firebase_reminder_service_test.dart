import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:synclife_app/src/features/reminders/data/services/firebase_reminder_service.dart';
import 'package:synclife_app/src/features/reminders/data/services/limited_reminder_service.dart';
import 'package:synclife_app/src/features/reminders/domain/models/models.dart';
import 'package:synclife_app/src/features/monetization/domain/models/user_limitations.dart';

import 'firebase_reminder_service_test.mocks.dart';

@GenerateMocks([LimitedReminderService])
void main() {
  group('FirebaseReminderService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockLimitedReminderService mockLimitationService;
    late FirebaseReminderService reminderService;

    const testUserId = 'test-user-123';
    const testBoardId = 'test-board-456';
    const testContent = 'Test reminder content';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockLimitationService = MockLimitedReminderService();
      reminderService = FirebaseReminderService(
        firestore: fakeFirestore,
        limitationService: mockLimitationService,
      );

      // Default mock behavior - allow creation
      when(mockLimitationService.checkReminderLimit(any))
          .thenAnswer((_) async => {});
      when(mockLimitationService.incrementReminderCount(any))
          .thenAnswer((_) async => {});
      when(mockLimitationService.decrementReminderCount(any))
          .thenAnswer((_) async => {});
    });

    group('createReminder', () {
      test('should create reminder with all fields', () async {
        // Arrange
        const tags = ['tag1', 'tag2'];
        const priority = ReminderPriority.high;

        // Act
        final result = await reminderService.createReminder(
          content: testContent,
          userId: testUserId,
          boardId: testBoardId,
          tags: tags,
          priority: priority,
        );

        // Assert
        expect(result.id, isNotEmpty);
        expect(result.content, equals(testContent));
        expect(result.userId, equals(testUserId));
        expect(result.boardId, equals(testBoardId));
        expect(result.tags, equals(tags));
        expect(result.priority, equals(priority));
        expect(result.createdAt, isNotNull);
        expect(result.updatedAt, isNotNull);

        // Verify limitation checks
        verify(mockLimitationService.checkReminderLimit(testUserId)).called(1);
        verify(mockLimitationService.incrementReminderCount(testUserId))
            .called(1);
      });

      test('should create reminder with default values', () async {
        // Act
        final result = await reminderService.createReminder(
          content: testContent,
          userId: testUserId,
          boardId: testBoardId,
        );

        // Assert
        expect(result.tags, isEmpty);
        expect(result.priority, equals(ReminderPriority.medium));
      });

      test('should throw exception when limit exceeded', () async {
        // Arrange
        when(mockLimitationService.checkReminderLimit(any))
            .thenThrow(ReminderLimitExceededException(
          limitationType: LimitationType.reminders,
          currentCount: 30,
          maxCount: 30,
        ));

        // Act & Assert
        expect(
          () => reminderService.createReminder(
            content: testContent,
            userId: testUserId,
            boardId: testBoardId,
          ),
          throwsA(isA<ReminderLimitExceededException>()),
        );

        // Verify increment was not called
        verifyNever(mockLimitationService.incrementReminderCount(any));
      });

      test('should persist reminder to Firestore', () async {
        // Act
        final result = await reminderService.createReminder(
          content: testContent,
          userId: testUserId,
          boardId: testBoardId,
        );

        // Assert - verify in Firestore
        final doc = await fakeFirestore
            .collection('reminders')
            .doc(result.id)
            .get();
        expect(doc.exists, isTrue);
        expect(doc.data()?['content'], equals(testContent));
        expect(doc.data()?['userId'], equals(testUserId));
      });
    });

    group('getReminders', () {
      test('should return all reminders for user ordered by createdAt', () async {
        // Arrange - create multiple reminders
        final reminder1 = await reminderService.createReminder(
          content: 'First reminder',
          userId: testUserId,
          boardId: testBoardId,
        );
        
        // Wait a bit to ensure different timestamps
        await Future.delayed(const Duration(milliseconds: 10));
        
        final reminder2 = await reminderService.createReminder(
          content: 'Second reminder',
          userId: testUserId,
          boardId: testBoardId,
        );

        // Act
        final results = await reminderService.getReminders(testUserId);

        // Assert - should be ordered by createdAt descending (newest first)
        expect(results.length, equals(2));
        expect(results[0].id, equals(reminder2.id));
        expect(results[1].id, equals(reminder1.id));
      });

      test('should return empty list when no reminders exist', () async {
        // Act
        final results = await reminderService.getReminders(testUserId);

        // Assert
        expect(results, isEmpty);
      });

      test('should only return reminders for specified user', () async {
        // Arrange
        await reminderService.createReminder(
          content: 'User 1 reminder',
          userId: testUserId,
          boardId: testBoardId,
        );
        
        await reminderService.createReminder(
          content: 'User 2 reminder',
          userId: 'other-user',
          boardId: testBoardId,
        );

        // Act
        final results = await reminderService.getReminders(testUserId);

        // Assert
        expect(results.length, equals(1));
        expect(results[0].userId, equals(testUserId));
      });
    });

    group('getRemindersByBoard', () {
      test('should return reminders filtered by board', () async {
        // Arrange
        const board1 = 'board-1';
        const board2 = 'board-2';

        await reminderService.createReminder(
          content: 'Board 1 reminder',
          userId: testUserId,
          boardId: board1,
        );
        
        await reminderService.createReminder(
          content: 'Board 2 reminder',
          userId: testUserId,
          boardId: board2,
        );

        // Act
        final results = await reminderService.getRemindersByBoard(
          testUserId,
          board1,
        );

        // Assert
        expect(results.length, equals(1));
        expect(results[0].boardId, equals(board1));
      });

      test('should return empty list when no reminders in board', () async {
        // Act
        final results = await reminderService.getRemindersByBoard(
          testUserId,
          'non-existent-board',
        );

        // Assert
        expect(results, isEmpty);
      });
    });

    group('searchReminders', () {
      test('should find reminders with case-insensitive partial match', () async {
        // Arrange
        await reminderService.createReminder(
          content: 'Buy groceries',
          userId: testUserId,
          boardId: testBoardId,
        );
        
        await reminderService.createReminder(
          content: 'Call dentist',
          userId: testUserId,
          boardId: testBoardId,
        );

        // Act
        final results = await reminderService.searchReminders(
          testUserId,
          'GROCER',
        );

        // Assert
        expect(results.length, equals(1));
        expect(results[0].content, equals('Buy groceries'));
      });

      test('should return empty list when no matches found', () async {
        // Arrange
        await reminderService.createReminder(
          content: 'Buy groceries',
          userId: testUserId,
          boardId: testBoardId,
        );

        // Act
        final results = await reminderService.searchReminders(
          testUserId,
          'dentist',
        );

        // Assert
        expect(results, isEmpty);
      });

      test('should return all reminders when query is empty', () async {
        // Arrange
        await reminderService.createReminder(
          content: 'Reminder 1',
          userId: testUserId,
          boardId: testBoardId,
        );
        
        await reminderService.createReminder(
          content: 'Reminder 2',
          userId: testUserId,
          boardId: testBoardId,
        );

        // Act
        final results = await reminderService.searchReminders(testUserId, '');

        // Assert
        expect(results.length, equals(2));
      });
    });

    group('updateReminder', () {
      test('should update reminder content', () async {
        // Arrange
        final reminder = await reminderService.createReminder(
          content: 'Original content',
          userId: testUserId,
          boardId: testBoardId,
        );

        // Act
        final updated = await reminderService.updateReminder(
          reminder.id,
          content: 'Updated content',
        );

        // Assert
        expect(updated.content, equals('Updated content'));
        expect(updated.updatedAt.isAfter(reminder.updatedAt), isTrue);
      });

      test('should update reminder board', () async {
        // Arrange
        final reminder = await reminderService.createReminder(
          content: testContent,
          userId: testUserId,
          boardId: 'board-1',
        );

        // Act
        final updated = await reminderService.updateReminder(
          reminder.id,
          boardId: 'board-2',
        );

        // Assert
        expect(updated.boardId, equals('board-2'));
      });

      test('should update reminder tags', () async {
        // Arrange
        final reminder = await reminderService.createReminder(
          content: testContent,
          userId: testUserId,
          boardId: testBoardId,
          tags: ['old-tag'],
        );

        // Act
        final updated = await reminderService.updateReminder(
          reminder.id,
          tags: ['new-tag-1', 'new-tag-2'],
        );

        // Assert
        expect(updated.tags, equals(['new-tag-1', 'new-tag-2']));
      });

      test('should update reminder priority', () async {
        // Arrange
        final reminder = await reminderService.createReminder(
          content: testContent,
          userId: testUserId,
          boardId: testBoardId,
          priority: ReminderPriority.low,
        );

        // Act
        final updated = await reminderService.updateReminder(
          reminder.id,
          priority: ReminderPriority.high,
        );

        // Assert
        expect(updated.priority, equals(ReminderPriority.high));
      });

      test('should throw exception when reminder not found', () async {
        // Act & Assert
        expect(
          () => reminderService.updateReminder(
            'non-existent-id',
            content: 'New content',
          ),
          throwsException,
        );
      });

      test('should persist updates to Firestore', () async {
        // Arrange
        final reminder = await reminderService.createReminder(
          content: 'Original',
          userId: testUserId,
          boardId: testBoardId,
        );

        // Act
        await reminderService.updateReminder(
          reminder.id,
          content: 'Updated',
        );

        // Assert - verify in Firestore
        final doc = await fakeFirestore
            .collection('reminders')
            .doc(reminder.id)
            .get();
        expect(doc.data()?['content'], equals('Updated'));
      });
    });

    group('deleteReminder', () {
      test('should delete reminder from Firestore', () async {
        // Arrange
        final reminder = await reminderService.createReminder(
          content: testContent,
          userId: testUserId,
          boardId: testBoardId,
        );

        // Act
        await reminderService.deleteReminder(reminder.id, testUserId);

        // Assert - verify deleted from Firestore
        final doc = await fakeFirestore
            .collection('reminders')
            .doc(reminder.id)
            .get();
        expect(doc.exists, isFalse);
      });

      test('should decrement reminder count', () async {
        // Arrange
        final reminder = await reminderService.createReminder(
          content: testContent,
          userId: testUserId,
          boardId: testBoardId,
        );

        // Act
        await reminderService.deleteReminder(reminder.id, testUserId);

        // Assert
        verify(mockLimitationService.decrementReminderCount(testUserId))
            .called(1);
      });
    });

    group('watchReminders', () {
      test('should emit reminders stream', () async {
        // Arrange
        final stream = reminderService.watchReminders(testUserId);

        // Act - create a reminder
        await reminderService.createReminder(
          content: testContent,
          userId: testUserId,
          boardId: testBoardId,
        );

        // Assert
        await expectLater(
          stream,
          emits(predicate<List<Reminder>>((list) => list.length == 1)),
        );
      });

      test('should emit updates when reminders change', () async {
        // Arrange
        final stream = reminderService.watchReminders(testUserId);
        final emittedLists = <List<Reminder>>[];

        // Start listening
        final subscription = stream.listen(emittedLists.add);

        // Act - create reminders
        await reminderService.createReminder(
          content: 'First',
          userId: testUserId,
          boardId: testBoardId,
        );

        await Future.delayed(const Duration(milliseconds: 100));

        await reminderService.createReminder(
          content: 'Second',
          userId: testUserId,
          boardId: testBoardId,
        );

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(emittedLists.length, greaterThanOrEqualTo(2));
        expect(emittedLists.last.length, equals(2));

        await subscription.cancel();
      });
    });

    group('watchRemindersByBoard', () {
      test('should emit reminders filtered by board', () async {
        // Arrange
        const board1 = 'board-1';
        const board2 = 'board-2';
        final stream = reminderService.watchRemindersByBoard(testUserId, board1);

        // Act
        await reminderService.createReminder(
          content: 'Board 1 reminder',
          userId: testUserId,
          boardId: board1,
        );

        await reminderService.createReminder(
          content: 'Board 2 reminder',
          userId: testUserId,
          boardId: board2,
        );

        // Assert
        await expectLater(
          stream,
          emits(predicate<List<Reminder>>(
            (list) => list.length == 1 && list[0].boardId == board1,
          )),
        );
      });
    });

    group('getReminderCount', () {
      test('should return correct count of reminders', () async {
        // Arrange
        await reminderService.createReminder(
          content: 'Reminder 1',
          userId: testUserId,
          boardId: testBoardId,
        );
        
        await reminderService.createReminder(
          content: 'Reminder 2',
          userId: testUserId,
          boardId: testBoardId,
        );

        // Act
        final count = await reminderService.getReminderCount(testUserId);

        // Assert
        expect(count, equals(2));
      });

      test('should return 0 when no reminders exist', () async {
        // Act
        final count = await reminderService.getReminderCount(testUserId);

        // Assert
        expect(count, equals(0));
      });

      test('should only count reminders for specified user', () async {
        // Arrange
        await reminderService.createReminder(
          content: 'User 1 reminder',
          userId: testUserId,
          boardId: testBoardId,
        );
        
        await reminderService.createReminder(
          content: 'User 2 reminder',
          userId: 'other-user',
          boardId: testBoardId,
        );

        // Act
        final count = await reminderService.getReminderCount(testUserId);

        // Assert
        expect(count, equals(1));
      });
    });
  });
}
