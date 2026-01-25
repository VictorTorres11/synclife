import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:synclife_app/src/features/rewards/data/services/firebase_store_service.dart';
import 'package:synclife_app/src/features/rewards/data/services/firebase_invitation_service.dart';
import 'package:synclife_app/src/features/rewards/domain/models/models.dart';
import 'package:synclife_app/src/features/gamification/domain/models/models.dart';
import '../helpers/test_helpers.dart';
import '../helpers/mock_services.dart';

/// Property-based tests for rewards store functionality
void main() {
  group('Rewards Store Property Tests', () {
    late FirebaseStoreService storeService;
    late FirebaseInvitationService invitationService;
    late FakeFirebaseFirestore fakeFirestore;
    late MockGamificationService mockGamificationService;
    late MockAuthService mockAuthService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockGamificationService = MockGamificationService();
      mockAuthService = MockAuthService();
      storeService = FirebaseStoreService(
        firestore: fakeFirestore,
        gamificationService: mockGamificationService,
      );
      invitationService = FirebaseInvitationService(
        firestore: fakeFirestore,
        gamificationService: mockGamificationService,
        authService: mockAuthService,
      );
    });

    group('Feature: synclife-app, Property 15: Store purchase validation', () {
      test(
          'For any valid store purchase, the system should deduct the correct FluxoCoins amount and unlock the corresponding features or items',
          () async {
        // Validates: Requirements 5.2, 5.3, 5.4, 5.5

        await PropertyTestRunner.runAsyncProperty<Map<String, dynamic>>(
          description:
              'Store purchases should validate correctly and deduct proper FluxoCoins',
          generator: _generatePurchaseTestData,
          property: (testData) async {
            final userId = testData['userId'] as String;
            final storeItem = testData['storeItem'] as StoreItem;
            final initialFluxoCoins = testData['initialFluxoCoins'] as int;

            // Set up store item in database
            await fakeFirestore
                .collection('storeItems')
                .doc(storeItem.id)
                .set(storeItem.toMap());

            // Set up user stats with FluxoCoins
            final userStats = UserStats.initial(userId)
                .copyWith(fluxoCoins: initialFluxoCoins);
            mockGamificationService.setUserStats(userId, userStats);

            // Property 1: Purchase should succeed only if user has enough FluxoCoins
            final canPurchase =
                await storeService.canPurchaseItem(userId, storeItem.id);
            final hasEnoughCoins = initialFluxoCoins >= storeItem.price;
            expect(canPurchase, equals(hasEnoughCoins),
                reason:
                    'Purchase validation should match FluxoCoin availability');

            if (hasEnoughCoins) {
              // Property 2: Successful purchase should create a purchase record
              final purchase =
                  await storeService.purchaseItem(userId, storeItem.id);
              expect(purchase.userId, equals(userId),
                  reason: 'Purchase should be linked to correct user');
              expect(purchase.storeItemId, equals(storeItem.id),
                  reason: 'Purchase should reference correct item');
              expect(purchase.price, equals(storeItem.price),
                  reason: 'Purchase price should match item price');
              expect(purchase.status, equals(PurchaseStatus.completed),
                  reason: 'Purchase should be completed');

              // Property 3: FluxoCoins should be deducted correctly
              final expectedDeduction = storeItem.price;
              expect(mockGamificationService.lastDeductedAmount,
                  equals(expectedDeduction),
                  reason: 'Correct amount should be deducted from FluxoCoins');

              // Property 4: Item should be added to user inventory
              final inventory = await storeService.getUserInventory(userId);
              expect(inventory.ownsItem(storeItem.id), isTrue,
                  reason: 'Purchased item should appear in user inventory');

              // Property 5: Purchase should appear in user's purchase history
              final purchases = await storeService.getUserPurchases(userId);
              expect(purchases.any((p) => p.id == purchase.id), isTrue,
                  reason: 'Purchase should appear in user purchase history');

              // Property 6: Inventory item should have correct properties
              final inventoryItem = inventory.ownedItems
                  .firstWhere((item) => item.storeItemId == storeItem.id);
              expect(inventoryItem.purchaseId, equals(purchase.id),
                  reason: 'Inventory item should reference purchase');
              expect(inventoryItem.quantity, equals(1),
                  reason: 'New purchase should have quantity of 1');
              expect(inventoryItem.isStackable,
                  equals(storeItem.type == StoreItemType.consumable),
                  reason: 'Stackable property should match item type');
            } else {
              // Property 7: Insufficient funds should prevent purchase
              expect(() => storeService.purchaseItem(userId, storeItem.id),
                  throwsA(isA<Exception>()),
                  reason: 'Purchase should fail when insufficient FluxoCoins');
            }

            return true;
          },
        );
      });
    });

    group('Feature: synclife-app, Property 15a: Store item activation', () {
      test(
          'For any owned item, activation should work correctly for permanent items',
          () async {
        await PropertyTestRunner.runAsyncProperty<Map<String, dynamic>>(
          description: 'Item activation should work correctly for owned items',
          generator: _generateActivationTestData,
          property: (testData) async {
            final userId = testData['userId'] as String;
            final storeItem = testData['storeItem'] as StoreItem;

            // Set up user inventory with the item
            final inventoryItem = InventoryItem(
              storeItemId: storeItem.id,
              purchaseId: TestGenerators.randomUuid(),
              quantity: 1,
              purchaseDate: DateTime.now(),
              isStackable: false,
            );

            final inventory =
                UserInventory.initial(userId).addItem(inventoryItem);
            await fakeFirestore
                .collection('userInventories')
                .doc(userId)
                .set(inventory.toMap());

            // Property 1: User should be able to activate owned items
            final updatedInventory =
                await storeService.activateItem(userId, storeItem.id);
            expect(updatedInventory.activeItems.contains(storeItem.id), isTrue,
                reason: 'Item should be activated in inventory');

            // Property 2: Activation should not affect item quantity
            final itemQuantity = updatedInventory.getItemQuantity(storeItem.id);
            expect(itemQuantity, equals(1),
                reason: 'Activation should not change item quantity');

            return true;
          },
        );
      });
    });

    group('Feature: synclife-app, Property 15b: Store item consumption', () {
      test(
          'For any consumable item, consumption should reduce quantity correctly',
          () async {
        await PropertyTestRunner.runAsyncProperty<Map<String, dynamic>>(
          description: 'Consumable items should be consumed correctly',
          generator: _generateConsumptionTestData,
          property: (testData) async {
            final userId = testData['userId'] as String;
            final storeItem = testData['storeItem'] as StoreItem;
            final initialQuantity = testData['initialQuantity'] as int;

            // Set up user inventory with consumable item
            final inventoryItem = InventoryItem(
              storeItemId: storeItem.id,
              purchaseId: TestGenerators.randomUuid(),
              quantity: initialQuantity,
              purchaseDate: DateTime.now(),
              isStackable: true,
            );

            final inventory =
                UserInventory.initial(userId).addItem(inventoryItem);
            await fakeFirestore
                .collection('userInventories')
                .doc(userId)
                .set(inventory.toMap());

            // Property 1: Consumption should reduce quantity by 1
            final updatedInventory =
                await storeService.consumeItem(userId, storeItem.id);
            final newQuantity = updatedInventory.getItemQuantity(storeItem.id);

            if (initialQuantity > 1) {
              expect(newQuantity, equals(initialQuantity - 1),
                  reason: 'Consumption should reduce quantity by 1');
              expect(updatedInventory.ownsItem(storeItem.id), isTrue,
                  reason: 'Item should still be owned if quantity > 0');
            } else {
              expect(newQuantity, equals(0),
                  reason: 'Item should be removed when quantity reaches 0');
              expect(updatedInventory.ownsItem(storeItem.id), isFalse,
                  reason:
                      'Item should be removed from inventory when consumed completely');
            }

            return true;
          },
        );
      });
    });

    group('Feature: synclife-app, Property 15c: Store item pricing', () {
      test('For any store item, pricing should be consistent and accurate',
          () async {
        await PropertyTestRunner.runAsyncProperty<Map<String, dynamic>>(
          description: 'Store item pricing should be consistent',
          generator: _generatePricingTestData,
          property: (testData) async {
            final userId = testData['userId'] as String;
            final storeItem = testData['storeItem'] as StoreItem;

            // Set up store item
            await fakeFirestore
                .collection('storeItems')
                .doc(storeItem.id)
                .set(storeItem.toMap());

            // Property 1: Item price should match stored price
            final retrievedPrice =
                await storeService.getItemPrice(userId, storeItem.id);
            expect(retrievedPrice, equals(storeItem.price),
                reason: 'Retrieved price should match stored item price');

            // Property 2: Price should be positive
            expect(storeItem.price, greaterThan(0),
                reason: 'Store item price should be positive');

            // Property 3: Retrieved item should have same price
            final retrievedItem = await storeService.getStoreItem(storeItem.id);
            expect(retrievedItem?.price, equals(storeItem.price),
                reason: 'Retrieved item should have consistent price');

            return true;
          },
        );
      });
    });

    group('Feature: synclife-app, Property 16: Existing user invitation', () {
      test(
          'For any invitation sent to a user who already has an account, the system should connect them to the board but not award referral bonuses',
          () async {
        // Validates: Requirements 6.1

        await PropertyTestRunner.runAsyncProperty<Map<String, dynamic>>(
          description:
              'Existing user invitations should not award referral bonuses',
          generator: _generateExistingUserInvitationTestData,
          property: (testData) async {
            final inviterId = testData['inviterId'] as String;
            final inviterEmail = testData['inviterEmail'] as String;
            final inviteeEmail = testData['inviteeEmail'] as String;
            final isExistingUser = testData['isExistingUser'] as bool;

            // Set up existing user in database if needed
            if (isExistingUser) {
              await fakeFirestore
                  .collection('users')
                  .doc('existing-user-id')
                  .set({
                'email': inviteeEmail,
                'displayName': 'Existing User',
                'createdAt': DateTime.now().toIso8601String(),
              });
            }

            // Create invitation
            final invitation = await invitationService.createInvitation(
                inviterId, inviterEmail, inviteeEmail);

            // Property 1: Invitation should be created successfully
            expect(invitation.inviterId, equals(inviterId),
                reason: 'Invitation should be linked to correct inviter');
            expect(invitation.inviteeEmail, equals(inviteeEmail),
                reason: 'Invitation should target correct invitee');
            expect(invitation.status, equals(InvitationStatus.pending),
                reason: 'New invitation should be pending');

            // Property 2: Bonus amount should be 0 for existing users, positive for new users
            if (isExistingUser) {
              expect(invitation.bonusAmount, equals(0),
                  reason:
                      'Existing user invitations should not have referral bonus');
            } else {
              expect(invitation.bonusAmount, greaterThan(0),
                  reason: 'New user invitations should have referral bonus');
            }

            // Property 3: Invite code should be valid format
            expect(invitationService.isValidInviteCode(invitation.inviteCode),
                isTrue,
                reason: 'Generated invite code should be valid format');

            // Property 4: Invitation should be retrievable by code
            final retrievedInvitation = await invitationService
                .getInvitationByCode(invitation.inviteCode);
            expect(retrievedInvitation?.id, equals(invitation.id),
                reason: 'Invitation should be retrievable by invite code');

            return true;
          },
        );
      });
    });

    group('Feature: synclife-app, Property 17: New user referral bonus', () {
      test(
          'For any new user who completes 5 tasks after being invited, the system should award the referral bonus to their inviter',
          () async {
        // Validates: Requirements 6.2, 6.3

        await PropertyTestRunner.runAsyncProperty<Map<String, dynamic>>(
          description:
              'New user referral bonuses should be awarded after completing required tasks',
          generator: _generateNewUserReferralTestData,
          property: (testData) async {
            final inviterId = testData['inviterId'] as String;
            final inviterEmail = testData['inviterEmail'] as String;
            final inviteeEmail = testData['inviteeEmail'] as String;
            final inviteeId = testData['inviteeId'] as String;
            final tasksToComplete = testData['tasksToComplete'] as int;

            // Set up inviter stats
            final inviterStats =
                UserStats.initial(inviterId).copyWith(fluxoCoins: 100);
            mockGamificationService.setUserStats(inviterId, inviterStats);

            // Create invitation for new user (no existing user in database)
            final invitation = await invitationService.createInvitation(
                inviterId, inviterEmail, inviteeEmail);

            // Accept invitation
            final acceptedInvitation = await invitationService.acceptInvitation(
                invitation.inviteCode, inviteeId);
            expect(acceptedInvitation.status, equals(InvitationStatus.accepted),
                reason: 'Invitation should be accepted');

            // Property 1: Referral bonus should be created for new user invitations
            if (invitation.bonusAmount > 0) {
              final bonusStatus =
                  await invitationService.getReferralBonusStatus(inviteeId);
              expect(bonusStatus, isNotNull,
                  reason: 'Referral bonus should be created for new user');
              expect(bonusStatus!.status, equals(ReferralBonusStatus.pending),
                  reason: 'Initial bonus status should be pending');
              expect(bonusStatus.tasksCompleted, equals(0),
                  reason: 'Initial tasks completed should be 0');
            }

            // Simulate task completions
            for (int i = 0; i < tasksToComplete; i++) {
              await invitationService.trackTaskCompletion(inviteeId);
              // Small delay to ensure sequential processing
              await Future.delayed(const Duration(milliseconds: 10));
            }

            // Property 2: Task completion should be tracked correctly
            final updatedBonusStatus =
                await invitationService.getReferralBonusStatus(inviteeId);
            if (updatedBonusStatus != null) {
              // Task completion should be tracked up to the required amount (5)
              final expectedTaskCount = tasksToComplete >= 5 ? 5 : tasksToComplete;
              expect(updatedBonusStatus.tasksCompleted, equals(expectedTaskCount),
                  reason: 'Task completion count should be tracked correctly up to required amount');

              // Property 3: Bonus should be awarded when required tasks are completed
              if (tasksToComplete >= 5) {
                expect(updatedBonusStatus.status,
                    equals(ReferralBonusStatus.awarded),
                    reason: 'Bonus should be awarded when 5+ tasks completed');
                expect(updatedBonusStatus.awardedAt, isNotNull,
                    reason: 'Awarded date should be set when bonus is awarded');

                // Property 4: FluxoCoins should be awarded to inviter
                expect(mockGamificationService.lastAwardedAmount,
                    equals(invitation.bonusAmount),
                    reason:
                        'Correct bonus amount should be awarded to inviter');
              } else {
                expect(updatedBonusStatus.status,
                    equals(ReferralBonusStatus.pending),
                    reason:
                        'Bonus should remain pending when less than 5 tasks completed');
              }
            }

            return true;
          },
        );
      });
    });

    group('Feature: synclife-app, Property 17a: Invitation code validation',
        () {
      test(
          'For any generated invite code, it should follow the correct format and be unique',
          () async {
        await PropertyTestRunner.runAsyncProperty<Map<String, dynamic>>(
          description: 'Invite codes should be valid format and unique',
          generator: _generateInviteCodeTestData,
          property: (testData) async {
            final codeCount = testData['codeCount'] as int;

            // Generate multiple invite codes
            final codes = <String>{};
            for (int i = 0; i < codeCount; i++) {
              final code = invitationService.generateInviteCode();

              // Property 1: Code should be valid format
              expect(invitationService.isValidInviteCode(code), isTrue,
                  reason: 'Generated code should be valid format');

              // Property 2: Code should be 8 characters
              expect(code.length, equals(8),
                  reason: 'Invite code should be 8 characters long');

              // Property 3: Code should be alphanumeric uppercase
              expect(RegExp(r'^[A-Z0-9]+$').hasMatch(code), isTrue,
                  reason: 'Invite code should be alphanumeric uppercase');

              codes.add(code);
            }

            // Property 4: All codes should be unique (with high probability)
            expect(codes.length, equals(codeCount),
                reason: 'Generated codes should be unique');

            return true;
          },
        );
      });
    });
  });
}

/// Generates test data for purchase property tests
Map<String, dynamic> _generatePurchaseTestData() {
  final userId = TestGenerators.randomUuid();
  final storeItem = _generateRandomStoreItem();

  // Generate FluxoCoins amount that may or may not be sufficient
  final sufficientCoins = storeItem.price + TestGenerators.randomInt(max: 1000);
  final insufficientCoins = TestGenerators.randomInt(max: storeItem.price - 1);
  final initialFluxoCoins =
      TestGenerators.randomBool() ? sufficientCoins : insufficientCoins;

  return {
    'userId': userId,
    'storeItem': storeItem,
    'initialFluxoCoins': initialFluxoCoins,
  };
}

/// Generates test data for activation property tests
Map<String, dynamic> _generateActivationTestData() {
  final userId = TestGenerators.randomUuid();
  final storeItem = _generateRandomStoreItem(type: StoreItemType.permanent);

  return {
    'userId': userId,
    'storeItem': storeItem,
  };
}

/// Generates test data for consumption property tests
Map<String, dynamic> _generateConsumptionTestData() {
  final userId = TestGenerators.randomUuid();
  final storeItem = _generateRandomStoreItem(type: StoreItemType.consumable);
  final initialQuantity = TestGenerators.randomInt(min: 1, max: 5);

  return {
    'userId': userId,
    'storeItem': storeItem,
    'initialQuantity': initialQuantity,
  };
}

/// Generates test data for pricing property tests
Map<String, dynamic> _generatePricingTestData() {
  final userId = TestGenerators.randomUuid();
  final storeItem = _generateRandomStoreItem();

  return {
    'userId': userId,
    'storeItem': storeItem,
  };
}

/// Generates a random store item for testing
StoreItem _generateRandomStoreItem({StoreItemType? type}) {
  const categories = StoreItemCategory.values;
  const types = StoreItemType.values;

  return StoreItem(
    id: TestGenerators.randomUuid(),
    name: TestGenerators.randomString(minLength: 5, maxLength: 30),
    description: TestGenerators.randomString(minLength: 10, maxLength: 100),
    category: categories[TestGenerators.randomInt(max: categories.length - 1)],
    price: TestGenerators.randomInt(min: 10, max: 1000),
    type: type ?? types[TestGenerators.randomInt(max: types.length - 1)],
    iconPath:
        'assets/store/${TestGenerators.randomString(minLength: 5, maxLength: 15)}.png',
    isAvailable: true,
  );
}

/// Generates test data for existing user invitation property tests
Map<String, dynamic> _generateExistingUserInvitationTestData() {
  final inviterId = TestGenerators.randomUuid();
  final inviterEmail = TestGenerators.randomEmail();
  final inviteeEmail = TestGenerators.randomEmail();
  final isExistingUser = TestGenerators.randomBool();

  return {
    'inviterId': inviterId,
    'inviterEmail': inviterEmail,
    'inviteeEmail': inviteeEmail,
    'isExistingUser': isExistingUser,
  };
}

/// Generates test data for new user referral bonus property tests
Map<String, dynamic> _generateNewUserReferralTestData() {
  final inviterId = TestGenerators.randomUuid();
  final inviterEmail = TestGenerators.randomEmail();
  final inviteeEmail = TestGenerators.randomEmail();
  final inviteeId = TestGenerators.randomUuid();
  final tasksToComplete = TestGenerators.randomInt(min: 0, max: 10);

  return {
    'inviterId': inviterId,
    'inviterEmail': inviterEmail,
    'inviteeEmail': inviteeEmail,
    'inviteeId': inviteeId,
    'tasksToComplete': tasksToComplete,
  };
}

/// Generates test data for invite code validation property tests
Map<String, dynamic> _generateInviteCodeTestData() {
  final codeCount = TestGenerators.randomInt(min: 5, max: 20);

  return {
    'codeCount': codeCount,
  };
}
