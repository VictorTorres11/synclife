import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:synclife_app/src/features/monetization/domain/models/models.dart';
import 'package:synclife_app/src/features/monetization/domain/services/services.dart';
import 'package:synclife_app/src/features/monetization/data/services/firebase_subscription_service.dart';

import 'subscription_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  DocumentReference,
  DocumentSnapshot,
  CollectionReference,
  InAppPurchase,
  ProductDetailsResponse,
])
void main() {
  group('FirebaseSubscriptionService', () {
    late FirebaseSubscriptionService subscriptionService;
    late MockFirebaseFirestore mockFirestore;
    late MockInAppPurchase mockInAppPurchase;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocument;
    late MockDocumentSnapshot mockSnapshot;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockInAppPurchase = MockInAppPurchase();
      mockCollection = MockCollectionReference();
      mockDocument = MockDocumentReference();
      mockSnapshot = MockDocumentSnapshot();

      subscriptionService = FirebaseSubscriptionService(
        firestore: mockFirestore,
        inAppPurchase: mockInAppPurchase,
      );

      // Setup default mocks
      when(mockFirestore.collection('subscriptions')).thenReturn(
          mockCollection as CollectionReference<Map<String, dynamic>>);
      when(mockFirestore.collection('user_limitations')).thenReturn(
          mockCollection as CollectionReference<Map<String, dynamic>>);
      when(mockCollection.doc(any)).thenReturn(mockDocument);
    });

    group('getUserSubscription', () {
      test('should return existing subscription when document exists',
          () async {
        // Arrange
        const userId = 'test-user-id';
        final subscriptionData = {
          'userId': userId,
          'status': 'active',
          'plan': 'premium',
          'productId': 'premium_monthly',
          'purchaseToken': 'test-token',
          'expiryDate':
              DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          'autoRenewing': true,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'metadata': <String, dynamic>{},
        };

        when(mockDocument.get()).thenAnswer((_) async => mockSnapshot);
        when(mockSnapshot.exists).thenReturn(true);
        when(mockSnapshot.data()).thenReturn(subscriptionData);

        // Act
        final result = await subscriptionService.getUserSubscription(userId);

        // Assert
        expect(result, isNotNull);
        expect(result!.userId, equals(userId));
        expect(result.status, equals(SubscriptionStatus.active));
        expect(result.plan, equals(SubscriptionPlan.premium));
        verify(mockDocument.get()).called(1);
      });

      test(
          'should create and return free subscription when document does not exist',
          () async {
        // Arrange
        const userId = 'test-user-id';

        when(mockDocument.get()).thenAnswer((_) async => mockSnapshot);
        when(mockSnapshot.exists).thenReturn(false);
        when(mockDocument.set(any)).thenAnswer((_) async {});

        // Act
        final result = await subscriptionService.getUserSubscription(userId);

        // Assert
        expect(result, isNotNull);
        expect(result!.userId, equals(userId));
        expect(result.status, equals(SubscriptionStatus.inactive));
        expect(result.plan, equals(SubscriptionPlan.free));
        verify(mockDocument.set(any)).called(1);
      });

      test('should throw exception when Firestore operation fails', () async {
        // Arrange
        const userId = 'test-user-id';
        when(mockDocument.get()).thenThrow(Exception('Firestore error'));

        // Act & Assert
        expect(
          () => subscriptionService.getUserSubscription(userId),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getUserLimitations', () {
      test('should return existing limitations when document exists', () async {
        // Arrange
        const userId = 'test-user-id';
        final limitationsData = {
          'userId': userId,
          'maxActiveTasks': 50,
          'maxBoards': 3,
          'maxBoardMembers': 5,
          'adsEnabled': true,
          'canUseCalendarIntegration': false,
          'canUseAdvancedBackup': false,
          'canUsePremiumThemes': false,
          'currentActiveTasks': 10,
          'currentBoards': 1,
          'updatedAt': DateTime.now().toIso8601String(),
        };

        when(mockDocument.get()).thenAnswer((_) async => mockSnapshot);
        when(mockSnapshot.exists).thenReturn(true);
        when(mockSnapshot.data()).thenReturn(limitationsData);

        // Act
        final result = await subscriptionService.getUserLimitations(userId);

        // Assert
        expect(result.userId, equals(userId));
        expect(result.maxActiveTasks, equals(50));
        expect(result.maxBoards, equals(3));
        expect(result.adsEnabled, isTrue);
        expect(result.canUseCalendarIntegration, isFalse);
      });

      test('should create default limitations when document does not exist',
          () async {
        // Arrange
        const userId = 'test-user-id';
        final subscriptionData = {
          'userId': userId,
          'status': 'inactive',
          'plan': 'free',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'metadata': <String, dynamic>{},
        };

        // Mock subscription lookup
        when(mockDocument.get()).thenReturn(Future.value(mockSnapshot));
        when(mockSnapshot.exists).thenReturn(false);
        when(mockSnapshot.data()).thenReturn(subscriptionData);
        when(mockDocument.set(any)).thenAnswer((_) async {});

        // Act
        final result = await subscriptionService.getUserLimitations(userId);

        // Assert
        expect(result.userId, equals(userId));
        expect(result.maxActiveTasks, equals(50)); // Default free limit
        expect(result.adsEnabled, isTrue);
        verify(mockDocument.set(any))
            .called(2); // Once for subscription, once for limitations
      });
    });

    group('canPerformAction', () {
      test('should return true when user can create more tasks', () async {
        // Arrange
        const userId = 'test-user-id';
        final limitationsData = {
          'userId': userId,
          'maxActiveTasks': 50,
          'maxBoards': 3,
          'maxBoardMembers': 5,
          'adsEnabled': true,
          'canUseCalendarIntegration': false,
          'canUseAdvancedBackup': false,
          'canUsePremiumThemes': false,
          'currentActiveTasks': 10, // Under limit
          'currentBoards': 1,
          'updatedAt': DateTime.now().toIso8601String(),
        };

        when(mockDocument.get()).thenAnswer((_) async => mockSnapshot);
        when(mockSnapshot.exists).thenReturn(true);
        when(mockSnapshot.data()).thenReturn(limitationsData);

        // Act
        final result = await subscriptionService.canPerformAction(
            userId, LimitationType.activeTasks);

        // Assert
        expect(result, isTrue);
      });

      test('should return false when user has reached task limit', () async {
        // Arrange
        const userId = 'test-user-id';
        final limitationsData = {
          'userId': userId,
          'maxActiveTasks': 50,
          'maxBoards': 3,
          'maxBoardMembers': 5,
          'adsEnabled': true,
          'canUseCalendarIntegration': false,
          'canUseAdvancedBackup': false,
          'canUsePremiumThemes': false,
          'currentActiveTasks': 50, // At limit
          'currentBoards': 1,
          'updatedAt': DateTime.now().toIso8601String(),
        };

        when(mockDocument.get()).thenAnswer((_) async => mockSnapshot);
        when(mockSnapshot.exists).thenReturn(true);
        when(mockSnapshot.data()).thenReturn(limitationsData);

        // Act
        final result = await subscriptionService.canPerformAction(
            userId, LimitationType.activeTasks);

        // Assert
        expect(result, isFalse);
      });

      test('should return true for premium users (unlimited)', () async {
        // Arrange
        const userId = 'test-user-id';
        final limitationsData = {
          'userId': userId,
          'maxActiveTasks': -1, // Unlimited
          'maxBoards': -1,
          'maxBoardMembers': -1,
          'adsEnabled': false,
          'canUseCalendarIntegration': true,
          'canUseAdvancedBackup': true,
          'canUsePremiumThemes': true,
          'currentActiveTasks': 100,
          'currentBoards': 10,
          'updatedAt': DateTime.now().toIso8601String(),
        };

        when(mockDocument.get()).thenAnswer((_) async => mockSnapshot);
        when(mockSnapshot.exists).thenReturn(true);
        when(mockSnapshot.data()).thenReturn(limitationsData);

        // Act
        final result = await subscriptionService.canPerformAction(
            userId, LimitationType.activeTasks);

        // Assert
        expect(result, isTrue);
      });
    });

    group('incrementUsage', () {
      test('should increment task count correctly', () async {
        // Arrange
        const userId = 'test-user-id';
        final limitationsData = {
          'userId': userId,
          'maxActiveTasks': 50,
          'maxBoards': 3,
          'maxBoardMembers': 5,
          'adsEnabled': true,
          'canUseCalendarIntegration': false,
          'canUseAdvancedBackup': false,
          'canUsePremiumThemes': false,
          'currentActiveTasks': 10,
          'currentBoards': 1,
          'updatedAt': DateTime.now().toIso8601String(),
        };

        when(mockDocument.get()).thenAnswer((_) async => mockSnapshot);
        when(mockSnapshot.exists).thenReturn(true);
        when(mockSnapshot.data()).thenReturn(limitationsData);
        when(mockDocument.update(any)).thenAnswer((_) async {});

        // Act
        await subscriptionService
            .incrementUsage(userId, LimitationType.activeTasks, count: 2);

        // Assert
        verify(
            mockDocument.update(argThat(predicate<Map<String, dynamic>>((data) {
          return data['currentActiveTasks'] == 12; // 10 + 2
        })))).called(1);
      });

      test('should increment board count correctly', () async {
        // Arrange
        const userId = 'test-user-id';
        final limitationsData = {
          'userId': userId,
          'maxActiveTasks': 50,
          'maxBoards': 3,
          'maxBoardMembers': 5,
          'adsEnabled': true,
          'canUseCalendarIntegration': false,
          'canUseAdvancedBackup': false,
          'canUsePremiumThemes': false,
          'currentActiveTasks': 10,
          'currentBoards': 1,
          'updatedAt': DateTime.now().toIso8601String(),
        };

        when(mockDocument.get()).thenAnswer((_) async => mockSnapshot);
        when(mockSnapshot.exists).thenReturn(true);
        when(mockSnapshot.data()).thenReturn(limitationsData);
        when(mockDocument.update(any)).thenAnswer((_) async {});

        // Act
        await subscriptionService.incrementUsage(userId, LimitationType.boards);

        // Assert
        verify(
            mockDocument.update(argThat(predicate<Map<String, dynamic>>((data) {
          return data['currentBoards'] == 2; // 1 + 1
        })))).called(1);
      });
    });

    group('decrementUsage', () {
      test('should decrement task count correctly', () async {
        // Arrange
        const userId = 'test-user-id';
        final limitationsData = {
          'userId': userId,
          'maxActiveTasks': 50,
          'maxBoards': 3,
          'maxBoardMembers': 5,
          'adsEnabled': true,
          'canUseCalendarIntegration': false,
          'canUseAdvancedBackup': false,
          'canUsePremiumThemes': false,
          'currentActiveTasks': 10,
          'currentBoards': 1,
          'updatedAt': DateTime.now().toIso8601String(),
        };

        when(mockDocument.get()).thenAnswer((_) async => mockSnapshot);
        when(mockSnapshot.exists).thenReturn(true);
        when(mockSnapshot.data()).thenReturn(limitationsData);
        when(mockDocument.update(any)).thenAnswer((_) async {});

        // Act
        await subscriptionService
            .decrementUsage(userId, LimitationType.activeTasks, count: 3);

        // Assert
        verify(
            mockDocument.update(argThat(predicate<Map<String, dynamic>>((data) {
          return data['currentActiveTasks'] == 7; // 10 - 3
        })))).called(1);
      });

      test('should not go below zero when decrementing', () async {
        // Arrange
        const userId = 'test-user-id';
        final limitationsData = {
          'userId': userId,
          'maxActiveTasks': 50,
          'maxBoards': 3,
          'maxBoardMembers': 5,
          'adsEnabled': true,
          'canUseCalendarIntegration': false,
          'canUseAdvancedBackup': false,
          'canUsePremiumThemes': false,
          'currentActiveTasks': 2,
          'currentBoards': 1,
          'updatedAt': DateTime.now().toIso8601String(),
        };

        when(mockDocument.get()).thenAnswer((_) async => mockSnapshot);
        when(mockSnapshot.exists).thenReturn(true);
        when(mockSnapshot.data()).thenReturn(limitationsData);
        when(mockDocument.update(any)).thenAnswer((_) async {});

        // Act
        await subscriptionService
            .decrementUsage(userId, LimitationType.activeTasks, count: 5);

        // Assert
        verify(
            mockDocument.update(argThat(predicate<Map<String, dynamic>>((data) {
          return data['currentActiveTasks'] == 0; // Clamped to 0
        })))).called(1);
      });
    });

    group('shouldShowAds', () {
      test('should return true for free users', () async {
        // Arrange
        const userId = 'test-user-id';
        final limitationsData = {
          'userId': userId,
          'maxActiveTasks': 50,
          'maxBoards': 3,
          'maxBoardMembers': 5,
          'adsEnabled': true, // Free user
          'canUseCalendarIntegration': false,
          'canUseAdvancedBackup': false,
          'canUsePremiumThemes': false,
          'currentActiveTasks': 10,
          'currentBoards': 1,
          'updatedAt': DateTime.now().toIso8601String(),
        };

        when(mockDocument.get()).thenAnswer((_) async => mockSnapshot);
        when(mockSnapshot.exists).thenReturn(true);
        when(mockSnapshot.data()).thenReturn(limitationsData);

        // Act
        final result = await subscriptionService.shouldShowAds(userId);

        // Assert
        expect(result, isTrue);
      });

      test('should return false for premium users', () async {
        // Arrange
        const userId = 'test-user-id';
        final limitationsData = {
          'userId': userId,
          'maxActiveTasks': -1,
          'maxBoards': -1,
          'maxBoardMembers': -1,
          'adsEnabled': false, // Premium user
          'canUseCalendarIntegration': true,
          'canUseAdvancedBackup': true,
          'canUsePremiumThemes': true,
          'currentActiveTasks': 100,
          'currentBoards': 10,
          'updatedAt': DateTime.now().toIso8601String(),
        };

        when(mockDocument.get()).thenAnswer((_) async => mockSnapshot);
        when(mockSnapshot.exists).thenReturn(true);
        when(mockSnapshot.data()).thenReturn(limitationsData);

        // Act
        final result = await subscriptionService.shouldShowAds(userId);

        // Assert
        expect(result, isFalse);
      });

      test('should return true when error occurs (default behavior)', () async {
        // Arrange
        const userId = 'test-user-id';
        when(mockDocument.get()).thenThrow(Exception('Firestore error'));

        // Act
        final result = await subscriptionService.shouldShowAds(userId);

        // Assert
        expect(result, isTrue); // Default to showing ads on error
      });
    });
  });
}
