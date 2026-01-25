import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:synclife_app/src/features/notifications/domain/models/notification_reaction.dart';
import 'package:synclife_app/src/features/notifications/domain/services/notification_reaction_service.dart';
import 'package:synclife_app/src/features/notifications/data/services/firebase_notification_reaction_service.dart';

// Generate mocks
@GenerateMocks([NotificationReactionService])
import 'notification_reactions_test.mocks.dart';

void main() {
  group('NotificationReaction Models', () {
    group('EmojiReaction', () {
      test('should have correct emoji and value mappings', () {
        expect(EmojiReaction.thumbsUp.emoji, equals('👍'));
        expect(EmojiReaction.thumbsUp.value, equals('thumbs_up'));

        expect(EmojiReaction.heart.emoji, equals('❤️'));
        expect(EmojiReaction.heart.value, equals('heart'));

        expect(EmojiReaction.fire.emoji, equals('🔥'));
        expect(EmojiReaction.fire.value, equals('fire'));
      });

      test('should convert from value correctly', () {
        expect(EmojiReaction.fromValue('thumbs_up'),
            equals(EmojiReaction.thumbsUp));
        expect(EmojiReaction.fromValue('heart'), equals(EmojiReaction.heart));
        expect(EmojiReaction.fromValue('fire'), equals(EmojiReaction.fire));
        expect(EmojiReaction.fromValue('invalid'),
            equals(EmojiReaction.thumbsUp)); // Default fallback
      });
    });

    group('NotificationReaction', () {
      test('should serialize and deserialize correctly', () {
        // Arrange
        final reaction = NotificationReaction(
          id: 'test_id',
          notificationId: 'notif_123',
          userId: 'user_456',
          reaction: EmojiReaction.heart,
          createdAt: DateTime(2024, 1, 15, 10, 30),
        );

        // Act
        final map = reaction.toMap();
        final deserialized = NotificationReaction.fromMap(map);

        // Assert
        expect(deserialized, equals(reaction));
        expect(deserialized.reaction, equals(EmojiReaction.heart));
        expect(deserialized.createdAt, equals(DateTime(2024, 1, 15, 10, 30)));
      });

      test('should support copyWith functionality', () {
        // Arrange
        final original = NotificationReaction(
          id: 'test_id',
          notificationId: 'notif_123',
          userId: 'user_456',
          reaction: EmojiReaction.thumbsUp,
          createdAt: DateTime(2024, 1, 15, 10, 30),
        );

        // Act
        final updated = original.copyWith(
          reaction: EmojiReaction.fire,
          createdAt: DateTime(2024, 1, 15, 11, 0),
        );

        // Assert
        expect(updated.id, equals(original.id)); // Unchanged
        expect(updated.notificationId,
            equals(original.notificationId)); // Unchanged
        expect(updated.userId, equals(original.userId)); // Unchanged
        expect(updated.reaction, equals(EmojiReaction.fire)); // Changed
        expect(
            updated.createdAt, equals(DateTime(2024, 1, 15, 11, 0))); // Changed
      });
    });

    group('NotificationReactionSummary', () {
      test('should calculate reaction counts correctly', () {
        // Arrange
        final summary = NotificationReactionSummary(
          notificationId: 'notif_123',
          reactionCounts: {
            EmojiReaction.thumbsUp: 5,
            EmojiReaction.heart: 3,
            EmojiReaction.fire: 1,
          },
          userReactions: {
            'user1': EmojiReaction.thumbsUp,
            'user2': EmojiReaction.heart,
            'user3': EmojiReaction.thumbsUp,
          },
          totalReactions: 9,
        );

        // Act & Assert
        expect(summary.getReactionCount(EmojiReaction.thumbsUp), equals(5));
        expect(summary.getReactionCount(EmojiReaction.heart), equals(3));
        expect(summary.getReactionCount(EmojiReaction.fire), equals(1));
        expect(summary.getReactionCount(EmojiReaction.clap),
            equals(0)); // Not present
      });

      test('should identify user reactions correctly', () {
        // Arrange
        final summary = NotificationReactionSummary(
          notificationId: 'notif_123',
          reactionCounts: {
            EmojiReaction.thumbsUp: 2,
            EmojiReaction.heart: 1,
          },
          userReactions: {
            'user1': EmojiReaction.thumbsUp,
            'user2': EmojiReaction.heart,
          },
          totalReactions: 3,
        );

        // Act & Assert
        expect(
            summary.getUserReaction('user1'), equals(EmojiReaction.thumbsUp));
        expect(summary.getUserReaction('user2'), equals(EmojiReaction.heart));
        expect(summary.getUserReaction('user3'), isNull); // No reaction

        expect(summary.hasUserReacted('user1', EmojiReaction.thumbsUp), isTrue);
        expect(summary.hasUserReacted('user1', EmojiReaction.heart), isFalse);
        expect(
            summary.hasUserReacted('user3', EmojiReaction.thumbsUp), isFalse);
      });

      test('should return top reactions in correct order', () {
        // Arrange
        final summary = NotificationReactionSummary(
          notificationId: 'notif_123',
          reactionCounts: {
            EmojiReaction.thumbsUp: 5,
            EmojiReaction.heart: 8,
            EmojiReaction.fire: 2,
            EmojiReaction.clap: 3,
          },
          userReactions: {},
          totalReactions: 18,
        );

        // Act
        final topReactions = summary.getTopReactions(limit: 3);

        // Assert
        expect(topReactions.length, equals(3));
        expect(topReactions[0].key,
            equals(EmojiReaction.heart)); // Highest count (8)
        expect(topReactions[0].value, equals(8));
        expect(topReactions[1].key,
            equals(EmojiReaction.thumbsUp)); // Second highest (5)
        expect(topReactions[1].value, equals(5));
        expect(topReactions[2].key,
            equals(EmojiReaction.clap)); // Third highest (3)
        expect(topReactions[2].value, equals(3));
      });

      test('should serialize and deserialize correctly', () {
        // Arrange
        final summary = NotificationReactionSummary(
          notificationId: 'notif_123',
          reactionCounts: {
            EmojiReaction.thumbsUp: 5,
            EmojiReaction.heart: 3,
          },
          userReactions: {
            'user1': EmojiReaction.thumbsUp,
            'user2': EmojiReaction.heart,
          },
          totalReactions: 8,
        );

        // Act
        final map = summary.toMap();
        final deserialized = NotificationReactionSummary.fromMap(map);

        // Assert
        expect(deserialized, equals(summary));
        expect(deserialized.reactionCounts[EmojiReaction.thumbsUp], equals(5));
        expect(deserialized.userReactions['user1'],
            equals(EmojiReaction.thumbsUp));
      });
    });
  });

  group('Property-Based Tests for Emoji Reactions', () {
    group('**Validates: Requirements 7.4**', () {
      test(
          'Feature: synclife-app, Property: Emoji reactions maintain consistency',
          () async {
        // Property: For any sequence of emoji reactions, the reaction counts
        // should always be consistent with the user reactions map

        final random = Random(42); // Fixed seed for reproducible tests

        for (int iteration = 0; iteration < 100; iteration++) {
          // Generate random reaction data
          final notificationId = 'notif_${iteration}';
          final userCount = 1 + random.nextInt(10); // 1-10 users
          final reactionTypes = EmojiReaction.values;

          final userReactions = <String, EmojiReaction>{};
          final reactionCounts = <EmojiReaction, int>{};

          // Generate random user reactions
          for (int i = 0; i < userCount; i++) {
            final userId = 'user_$i';
            final reaction =
                reactionTypes[random.nextInt(reactionTypes.length)];

            userReactions[userId] = reaction;
            reactionCounts[reaction] = (reactionCounts[reaction] ?? 0) + 1;
          }

          final totalReactions = userReactions.length;

          // Create summary
          final summary = NotificationReactionSummary(
            notificationId: notificationId,
            reactionCounts: reactionCounts,
            userReactions: userReactions,
            totalReactions: totalReactions,
          );

          // Verify consistency properties

          // Property 1: Total reactions should equal sum of all reaction counts
          final sumOfCounts =
              reactionCounts.values.fold<int>(0, (sum, count) => sum + count);
          expect(summary.totalReactions, equals(sumOfCounts),
              reason:
                  'Total reactions should equal sum of counts in iteration $iteration');

          // Property 2: Total reactions should equal number of unique users
          expect(summary.totalReactions, equals(userReactions.length),
              reason:
                  'Total reactions should equal number of users in iteration $iteration');

          // Property 3: Each reaction count should match actual user reactions
          for (final reaction in EmojiReaction.values) {
            final expectedCount = userReactions.values
                .where((userReaction) => userReaction == reaction)
                .length;
            final actualCount = summary.getReactionCount(reaction);

            expect(actualCount, equals(expectedCount),
                reason:
                    'Reaction count for ${reaction.value} should match user reactions in iteration $iteration');
          }

          // Property 4: User reaction lookup should be consistent
          for (final entry in userReactions.entries) {
            final userId = entry.key;
            final expectedReaction = entry.value;
            final actualReaction = summary.getUserReaction(userId);

            expect(actualReaction, equals(expectedReaction),
                reason:
                    'User reaction lookup should be consistent for $userId in iteration $iteration');

            expect(summary.hasUserReacted(userId, expectedReaction), isTrue,
                reason:
                    'hasUserReacted should return true for actual user reaction in iteration $iteration');
          }

          // Property 5: Top reactions should be sorted by count (descending)
          final topReactions = summary.getTopReactions();
          for (int i = 0; i < topReactions.length - 1; i++) {
            expect(topReactions[i].value,
                greaterThanOrEqualTo(topReactions[i + 1].value),
                reason:
                    'Top reactions should be sorted by count in iteration $iteration');
          }
        }
      });

      test(
          'Feature: synclife-app, Property: Reaction toggle behavior works correctly',
          () async {
        // Property: For any user and reaction, toggling the same reaction twice
        // should result in no reaction (toggle on/off behavior)

        final mockService = MockNotificationReactionService();
        final random = Random(123);

        for (int iteration = 0; iteration < 50; iteration++) {
          final notificationId = 'notif_${iteration}';
          final userId = 'user_${iteration}';
          final reaction =
              EmojiReaction.values[random.nextInt(EmojiReaction.values.length)];

          // Mock the toggle behavior
          var hasReaction = false;

          when(mockService.sendReaction(
            notificationId: notificationId,
            userId: userId,
            reaction: reaction,
          )).thenAnswer((_) async {
            if (hasReaction) {
              // If user already has this reaction, remove it (toggle off)
              hasReaction = false;
            } else {
              // If user doesn't have this reaction, add it (toggle on)
              hasReaction = true;
            }
          });

          when(mockService.getUserReaction(
            notificationId: notificationId,
            userId: userId,
          )).thenAnswer((_) async {
            return hasReaction
                ? NotificationReaction(
                    id: '${notificationId}_$userId',
                    notificationId: notificationId,
                    userId: userId,
                    reaction: reaction,
                    createdAt: DateTime.now(),
                  )
                : null;
          });

          // Test toggle behavior

          // Initially no reaction
          var userReaction = await mockService.getUserReaction(
            notificationId: notificationId,
            userId: userId,
          );
          expect(userReaction, isNull,
              reason:
                  'Initially should have no reaction in iteration $iteration');

          // First toggle - add reaction
          await mockService.sendReaction(
            notificationId: notificationId,
            userId: userId,
            reaction: reaction,
          );

          userReaction = await mockService.getUserReaction(
            notificationId: notificationId,
            userId: userId,
          );
          expect(userReaction?.reaction, equals(reaction),
              reason:
                  'After first toggle should have reaction in iteration $iteration');

          // Second toggle - remove reaction
          await mockService.sendReaction(
            notificationId: notificationId,
            userId: userId,
            reaction: reaction,
          );

          userReaction = await mockService.getUserReaction(
            notificationId: notificationId,
            userId: userId,
          );
          expect(userReaction, isNull,
              reason:
                  'After second toggle should have no reaction in iteration $iteration');
        }
      });

      test(
          'Feature: synclife-app, Property: Reaction changes update counts correctly',
          () async {
        // Property: For any reaction change (add/remove/change), the reaction counts
        // should be updated correctly and remain consistent

        final random = Random(456);

        for (int iteration = 0; iteration < 50; iteration++) {
          // Start with empty summary
          var summary = NotificationReactionSummary(
            notificationId: 'notif_$iteration',
            reactionCounts: {},
            userReactions: {},
            totalReactions: 0,
          );

          final userCount = 1 + random.nextInt(5); // 1-5 users
          final operations = <String>[];

          // Perform random operations
          for (int i = 0; i < userCount; i++) {
            final userId = 'user_$i';
            final reaction = EmojiReaction
                .values[random.nextInt(EmojiReaction.values.length)];

            // Simulate adding a reaction
            final newUserReactions =
                Map<String, EmojiReaction>.from(summary.userReactions);
            final newReactionCounts =
                Map<EmojiReaction, int>.from(summary.reactionCounts);

            final previousReaction = newUserReactions[userId];

            if (previousReaction != null) {
              // Remove previous reaction count
              final prevCount = newReactionCounts[previousReaction] ?? 0;
              if (prevCount > 1) {
                newReactionCounts[previousReaction] = prevCount - 1;
              } else {
                newReactionCounts.remove(previousReaction);
              }
            }

            // Add new reaction
            newUserReactions[userId] = reaction;
            newReactionCounts[reaction] =
                (newReactionCounts[reaction] ?? 0) + 1;

            summary = summary.copyWith(
              reactionCounts: newReactionCounts,
              userReactions: newUserReactions,
              totalReactions: newUserReactions.length,
            );

            operations.add('User $userId reacted with ${reaction.value}');

            // Verify consistency after each operation
            final sumOfCounts = summary.reactionCounts.values
                .fold<int>(0, (sum, count) => sum + count);
            expect(summary.totalReactions, equals(sumOfCounts),
                reason:
                    'Total should equal sum after operation in iteration $iteration: ${operations.join(', ')}');

            expect(summary.totalReactions, equals(summary.userReactions.length),
                reason:
                    'Total should equal user count after operation in iteration $iteration: ${operations.join(', ')}');

            // Verify specific user reaction
            expect(summary.getUserReaction(userId), equals(reaction),
                reason:
                    'User reaction should be correct after operation in iteration $iteration: ${operations.join(', ')}');
          }
        }
      });
    });
  });
}
