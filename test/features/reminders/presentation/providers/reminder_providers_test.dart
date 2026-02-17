import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:synclife_app/src/features/auth/domain/models/user.dart';
import 'package:synclife_app/src/features/monetization/domain/services/subscription_service.dart';
import 'package:synclife_app/src/features/monetization/presentation/providers/monetization_providers.dart';
import 'package:synclife_app/src/features/reminders/data/services/firebase_reminder_service.dart';
import 'package:synclife_app/src/features/reminders/data/services/limited_reminder_service.dart';
import 'package:synclife_app/src/features/reminders/data/services/reminder_conversion_service.dart';
import 'package:synclife_app/src/features/reminders/domain/models/models.dart';
import 'package:synclife_app/src/features/reminders/domain/services/reminder_service.dart';
import 'package:synclife_app/src/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:synclife_app/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:synclife_app/src/features/tasks/domain/services/task_service.dart';
import 'package:synclife_app/src/features/tasks/presentation/providers/task_providers.dart';

import 'reminder_providers_test.mocks.dart';

@GenerateMocks([SubscriptionService, TaskService, ReminderService])
void main() {
  group('Reminder Providers Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockSubscriptionService mockSubscriptionService;
    late MockTaskService mockTaskService;
    late MockReminderService mockReminderService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockSubscriptionService = MockSubscriptionService();
      mockTaskService = MockTaskService();
      mockReminderService = MockReminderService();
    });

    group('Service Providers', () {
      test('reminderServiceProvider provides FirebaseReminderService instance', () {
        final container = ProviderContainer(
          overrides: [
            subscriptionServiceProvider.overrideWithValue(mockSubscriptionService),
          ],
        );
        
        final service = container.read(reminderServiceProvider);
        
        expect(service, isA<ReminderService>());
        expect(service, isA<FirebaseReminderService>());
        
        container.dispose();
      });

      test('limitedReminderServiceProvider provides LimitedReminderService instance', () {
        final container = ProviderContainer(
          overrides: [
            subscriptionServiceProvider.overrideWithValue(mockSubscriptionService),
          ],
        );
        
        final service = container.read(limitedReminderServiceProvider);
        
        expect(service, isA<LimitedReminderService>());
        
        container.dispose();
      });

      test('reminderConversionServiceProvider provides ReminderConversionService instance', () {
        final container = ProviderContainer(
          overrides: [
            subscriptionServiceProvider.overrideWithValue(mockSubscriptionService),
            taskServiceProvider.overrideWithValue(mockTaskService),
          ],
        );
        
        final service = container.read(reminderConversionServiceProvider);
        
        expect(service, isA<ReminderConversionService>());
        
        container.dispose();
      });
    });

    group('State Providers', () {
      test('selectedBoardFilterProvider initial value is null', () {
        final container = ProviderContainer();
        
        final selectedBoard = container.read(selectedBoardFilterProvider);
        
        expect(selectedBoard, isNull);
        
        container.dispose();
      });

      test('selectedBoardFilterProvider can be updated', () {
        final container = ProviderContainer();
        const testBoardId = 'board_123';
        
        container.read(selectedBoardFilterProvider.notifier).state = testBoardId;
        final selectedBoard = container.read(selectedBoardFilterProvider);
        
        expect(selectedBoard, equals(testBoardId));
        
        container.dispose();
      });

      test('reminderSearchQueryProvider initial value is empty string', () {
        final container = ProviderContainer();
        
        final searchQuery = container.read(reminderSearchQueryProvider);
        
        expect(searchQuery, equals(''));
        
        container.dispose();
      });

      test('reminderSearchQueryProvider can be updated', () {
        final container = ProviderContainer();
        const testQuery = 'test search';
        
        container.read(reminderSearchQueryProvider.notifier).state = testQuery;
        final searchQuery = container.read(reminderSearchQueryProvider);
        
        expect(searchQuery, equals(testQuery));
        
        container.dispose();
      });
    });

    group('Filtered Reminders Provider', () {
      test('filteredRemindersProvider returns empty list when no user is logged in', () {
        // Override currentUserProvider to return null
        final overrideContainer = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWithValue(null),
          ],
        );

        final filteredReminders = overrideContainer.read(filteredRemindersProvider);
        
        expect(filteredReminders, isA<AsyncData<List<Reminder>>>());
        expect(filteredReminders.value, isEmpty);

        overrideContainer.dispose();
      });

      test('filteredRemindersProvider filters by board when board is selected', () {
        const userId = 'user_123';
        const boardId1 = 'board_1';
        const boardId2 = 'board_2';
        final now = DateTime.now();

        final testUser = User(
          id: userId,
          email: 'test@example.com',
          displayName: 'Test User',
          createdAt: now,
          updatedAt: now,
        );

        final testReminders = [
          Reminder(
            id: '1',
            content: 'Reminder 1',
            userId: userId,
            boardId: boardId1,
            createdAt: now,
            updatedAt: now,
          ),
          Reminder(
            id: '2',
            content: 'Reminder 2',
            userId: userId,
            boardId: boardId2,
            createdAt: now,
            updatedAt: now,
          ),
          Reminder(
            id: '3',
            content: 'Reminder 3',
            userId: userId,
            boardId: boardId1,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final overrideContainer = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWithValue(testUser),
            remindersStreamProvider(userId).overrideWith(
              (ref) => Stream.value(testReminders),
            ),
            selectedBoardFilterProvider.overrideWith((ref) => boardId1),
          ],
        );

        final filteredReminders = overrideContainer.read(filteredRemindersProvider);
        
        expect(filteredReminders, isA<AsyncData<List<Reminder>>>());
        expect(filteredReminders.value?.length, equals(2));
        expect(filteredReminders.value?.every((r) => r.boardId == boardId1), isTrue);

        overrideContainer.dispose();
      });

      test('filteredRemindersProvider filters by search query (case-insensitive)', () {
        const userId = 'user_123';
        final now = DateTime.now();

        final testUser = User(
          id: userId,
          email: 'test@example.com',
          displayName: 'Test User',
          createdAt: now,
          updatedAt: now,
        );

        final testReminders = [
          Reminder(
            id: '1',
            content: 'Buy groceries',
            userId: userId,
            boardId: 'board_1',
            createdAt: now,
            updatedAt: now,
          ),
          Reminder(
            id: '2',
            content: 'Call dentist',
            userId: userId,
            boardId: 'board_1',
            createdAt: now,
            updatedAt: now,
          ),
          Reminder(
            id: '3',
            content: 'Buy birthday gift',
            userId: userId,
            boardId: 'board_1',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final overrideContainer = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWithValue(testUser),
            remindersStreamProvider(userId).overrideWith(
              (ref) => Stream.value(testReminders),
            ),
            reminderSearchQueryProvider.overrideWith((ref) => 'buy'),
          ],
        );

        final filteredReminders = overrideContainer.read(filteredRemindersProvider);
        
        expect(filteredReminders, isA<AsyncData<List<Reminder>>>());
        expect(filteredReminders.value?.length, equals(2));
        expect(
          filteredReminders.value?.every(
            (r) => r.content.toLowerCase().contains('buy'),
          ),
          isTrue,
        );

        overrideContainer.dispose();
      });

      test('filteredRemindersProvider applies both board and search filters', () {
        const userId = 'user_123';
        const boardId1 = 'board_1';
        const boardId2 = 'board_2';
        final now = DateTime.now();

        final testUser = User(
          id: userId,
          email: 'test@example.com',
          displayName: 'Test User',
          createdAt: now,
          updatedAt: now,
        );

        final testReminders = [
          Reminder(
            id: '1',
            content: 'Buy groceries',
            userId: userId,
            boardId: boardId1,
            createdAt: now,
            updatedAt: now,
          ),
          Reminder(
            id: '2',
            content: 'Buy gift',
            userId: userId,
            boardId: boardId2,
            createdAt: now,
            updatedAt: now,
          ),
          Reminder(
            id: '3',
            content: 'Call dentist',
            userId: userId,
            boardId: boardId1,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final overrideContainer = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWithValue(testUser),
            remindersStreamProvider(userId).overrideWith(
              (ref) => Stream.value(testReminders),
            ),
            selectedBoardFilterProvider.overrideWith((ref) => boardId1),
            reminderSearchQueryProvider.overrideWith((ref) => 'buy'),
          ],
        );

        final filteredReminders = overrideContainer.read(filteredRemindersProvider);
        
        expect(filteredReminders, isA<AsyncData<List<Reminder>>>());
        expect(filteredReminders.value?.length, equals(1));
        expect(filteredReminders.value?.first.id, equals('1'));
        expect(filteredReminders.value?.first.content, equals('Buy groceries'));

        overrideContainer.dispose();
      });
    });

    group('Provider Dependencies', () {
      test('reminderServiceProvider depends on limitedReminderServiceProvider', () {
        final container = ProviderContainer(
          overrides: [
            subscriptionServiceProvider.overrideWithValue(mockSubscriptionService),
          ],
        );
        
        final service = container.read(reminderServiceProvider);
        
        // Verify it's a FirebaseReminderService (which requires LimitedReminderService)
        expect(service, isA<FirebaseReminderService>());
        
        container.dispose();
      });

      test('reminderConversionServiceProvider depends on reminderServiceProvider and taskServiceProvider', () {
        final container = ProviderContainer(
          overrides: [
            subscriptionServiceProvider.overrideWithValue(mockSubscriptionService),
            taskServiceProvider.overrideWithValue(mockTaskService),
          ],
        );
        
        final service = container.read(reminderConversionServiceProvider);
        
        expect(service, isA<ReminderConversionService>());
        
        container.dispose();
      });

      test('limitedReminderServiceProvider depends on subscriptionServiceProvider', () {
        final container = ProviderContainer(
          overrides: [
            subscriptionServiceProvider.overrideWithValue(mockSubscriptionService),
          ],
        );
        
        final service = container.read(limitedReminderServiceProvider);
        
        expect(service, isA<LimitedReminderService>());
        
        container.dispose();
      });
    });
  });
}
