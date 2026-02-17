import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:synclife_app/src/features/reminders/data/services/limited_reminder_service.dart';
import 'package:synclife_app/src/features/monetization/domain/services/subscription_service.dart';
import 'package:synclife_app/src/features/monetization/domain/models/user_limitations.dart';

import 'limited_reminder_service_test.mocks.dart';

@GenerateMocks([SubscriptionService])
void main() {
  group('LimitedReminderService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockSubscriptionService mockSubscriptionService;
    late LimitedReminderService limitedReminderService;

    const testUserId = 'test-user-123';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockSubscriptionService = MockSubscriptionService();
      limitedReminderService = LimitedReminderService(
        subscriptionService: mockSubscriptionService,
        firestore: fakeFirestore,
      );
    });

    group('checkReminderLimit', () {
      test('should not throw exception when user can create more reminders', () async {
        // Arrange
        when(mockSubscriptionService.canPerformAction(
          testUserId,
          LimitationType.reminders,
        )).thenAnswer((_) async => true);

        // Act & Assert
        await expectLater(
          limitedReminderService.checkReminderLimit(testUserId),
          completes,
        );
      });

      test('should throw ReminderLimitExceededException when limit reached', () async {
        // Arrange - create user limitations document
        await fakeFirestore
            .collection('userLimitations')
            .doc(testUserId)
            .set({
          'userId': testUserId,
          'maxReminders': 30,
          'currentReminders': 30,
          'maxActiveTasks': 50,
          'currentActiveTasks': 10,
          'maxBoards': 5,
          'currentBoards': 2,
          'maxBoardMembers': 3,
          'adsEnabled': true,
          'canUseCalendarIntegration': false,
          'canUseAdvancedBackup': false,
          'canUsePremiumThemes': false,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        when(mockSubscriptionService.canPerformAction(
          testUserId,
          LimitationType.reminders,
        )).thenAnswer((_) async => false);

        // Act & Assert
        expect(
          () => limitedReminderService.checkReminderLimit(testUserId),
          throwsA(isA<ReminderLimitExceededException>()
              .having((e) => e.limitationType, 'limitationType', LimitationType.reminders)
              .having((e) => e.currentCount, 'currentCount', 30)
              .having((e) => e.maxCount, 'maxCount', 30)),
        );
      });

      test('should throw exception when free user at limit', () async {
        // Arrange - create free user at limit
        await fakeFirestore
            .collection('userLimitations')
            .doc(testUserId)
            .set({
          'userId': testUserId,
          'maxReminders': 30,
          'currentReminders': 30,
          'maxActiveTasks': 50,
          'currentActiveTasks': 10,
          'maxBoards': 5,
          'currentBoards': 2,
          'maxBoardMembers': 3,
          'adsEnabled': true,
          'canUseCalendarIntegration': false,
          'canUseAdvancedBackup': false,
          'canUsePremiumThemes': false,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        when(mockSubscriptionService.canPerformAction(
          testUserId,
          LimitationType.reminders,
        )).thenAnswer((_) async => false);

        // Act & Assert
        expect(
          () => limitedReminderService.checkReminderLimit(testUserId),
          throwsA(isA<ReminderLimitExceededException>()),
        );
      });

      test('should use default free limitations when document does not exist', () async {
        // Arrange - no document exists
        when(mockSubscriptionService.canPerformAction(
          testUserId,
          LimitationType.reminders,
        )).thenAnswer((_) async => false);

        // Act & Assert - should throw with default free user limits
        expect(
          () => limitedReminderService.checkReminderLimit(testUserId),
          throwsA(isA<ReminderLimitExceededException>()
              .having((e) => e.maxCount, 'maxCount', 30)),
        );
      });
    });

    group('incrementReminderCount', () {
      test('should call incrementUsage on subscription service', () async {
        // Arrange
        when(mockSubscriptionService.incrementUsage(
          testUserId,
          LimitationType.reminders,
          count: anyNamed('count'),
        )).thenAnswer((_) async => {});

        // Act
        await limitedReminderService.incrementReminderCount(testUserId);

        // Assert
        verify(mockSubscriptionService.incrementUsage(
          testUserId,
          LimitationType.reminders,
          count: 1,
        )).called(1);
      });

      test('should increment count atomically', () async {
        // Arrange
        when(mockSubscriptionService.incrementUsage(
          any,
          any,
          count: anyNamed('count'),
        )).thenAnswer((_) async => {});

        // Act - call multiple times
        await Future.wait([
          limitedReminderService.incrementReminderCount(testUserId),
          limitedReminderService.incrementReminderCount(testUserId),
          limitedReminderService.incrementReminderCount(testUserId),
        ]);

        // Assert - should be called 3 times
        verify(mockSubscriptionService.incrementUsage(
          testUserId,
          LimitationType.reminders,
          count: 1,
        )).called(3);
      });
    });

    group('decrementReminderCount', () {
      test('should call decrementUsage on subscription service', () async {
        // Arrange
        when(mockSubscriptionService.decrementUsage(
          testUserId,
          LimitationType.reminders,
          count: anyNamed('count'),
        )).thenAnswer((_) async => {});

        // Act
        await limitedReminderService.decrementReminderCount(testUserId);

        // Assert
        verify(mockSubscriptionService.decrementUsage(
          testUserId,
          LimitationType.reminders,
          count: 1,
        )).called(1);
      });

      test('should decrement count atomically', () async {
        // Arrange
        when(mockSubscriptionService.decrementUsage(
          any,
          any,
          count: anyNamed('count'),
        )).thenAnswer((_) async => {});

        // Act - call multiple times
        await Future.wait([
          limitedReminderService.decrementReminderCount(testUserId),
          limitedReminderService.decrementReminderCount(testUserId),
        ]);

        // Assert - should be called 2 times
        verify(mockSubscriptionService.decrementUsage(
          testUserId,
          LimitationType.reminders,
          count: 1,
        )).called(2);
      });
    });

    group('premium user unlimited access', () {
      test('should allow premium user to create reminders without limit', () async {
        // Arrange - create premium user limitations
        await fakeFirestore
            .collection('userLimitations')
            .doc(testUserId)
            .set({
          'userId': testUserId,
          'maxReminders': -1, // unlimited
          'currentReminders': 100, // already has many reminders
          'maxActiveTasks': -1,
          'currentActiveTasks': 50,
          'maxBoards': -1,
          'currentBoards': 10,
          'maxBoardMembers': -1,
          'adsEnabled': false,
          'canUseCalendarIntegration': true,
          'canUseAdvancedBackup': true,
          'canUsePremiumThemes': true,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        when(mockSubscriptionService.canPerformAction(
          testUserId,
          LimitationType.reminders,
        )).thenAnswer((_) async => true);

        // Act & Assert - should not throw
        await expectLater(
          limitedReminderService.checkReminderLimit(testUserId),
          completes,
        );
      });

      test('should not enforce limit for premium users', () async {
        // Arrange - premium user with many reminders
        await fakeFirestore
            .collection('userLimitations')
            .doc(testUserId)
            .set({
          'userId': testUserId,
          'maxReminders': -1,
          'currentReminders': 1000,
          'maxActiveTasks': -1,
          'currentActiveTasks': 100,
          'maxBoards': -1,
          'currentBoards': 20,
          'maxBoardMembers': -1,
          'adsEnabled': false,
          'canUseCalendarIntegration': true,
          'canUseAdvancedBackup': true,
          'canUsePremiumThemes': true,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        when(mockSubscriptionService.canPerformAction(
          testUserId,
          LimitationType.reminders,
        )).thenAnswer((_) async => true);

        // Act & Assert
        await expectLater(
          limitedReminderService.checkReminderLimit(testUserId),
          completes,
        );
      });
    });
  });
}
