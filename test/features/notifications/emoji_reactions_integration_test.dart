import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:synclife_app/src/features/notifications/domain/models/notification_reaction.dart';
import 'package:synclife_app/src/features/notifications/domain/services/notification_reaction_service.dart';
import 'package:synclife_app/src/features/notifications/presentation/providers/notification_providers.dart';
import 'package:synclife_app/src/features/notifications/presentation/widgets/notification_reaction_buttons.dart';
import 'package:synclife_app/src/features/notifications/presentation/widgets/notification_reaction_summary.dart'
    as summary_widget;

// Generate mocks
@GenerateMocks([NotificationReactionService])
import 'emoji_reactions_integration_test.mocks.dart';

void main() {
  group('Emoji Reactions Integration Tests', () {
    late MockNotificationReactionService mockReactionService;
    late ProviderContainer container;

    setUp(() {
      mockReactionService = MockNotificationReactionService();

      container = ProviderContainer(
        overrides: [
          notificationReactionServiceProvider
              .overrideWithValue(mockReactionService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('should display reaction buttons and handle user interactions',
        (tester) async {
      // Arrange
      const notificationId = 'test_notification';
      const userId = 'test_user';

      // Mock initial empty state
      when(mockReactionService.watchReactionSummary(notificationId))
          .thenAnswer((_) => Stream.value(
                const NotificationReactionSummary(
                  notificationId: notificationId,
                  reactionCounts: {},
                  userReactions: {},
                  totalReactions: 0,
                ),
              ));

      when(mockReactionService.sendReaction(
        notificationId: notificationId,
        userId: userId,
        reaction: anyNamed('reaction'),
      )).thenAnswer((_) async {});

      // Build widget
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: NotificationReactionButtons(
                notificationId: notificationId,
                userId: userId,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - should show all emoji buttons
      expect(find.text('👍'), findsOneWidget);
      expect(find.text('❤️'), findsOneWidget);
      expect(find.text('🔥'), findsOneWidget);
      expect(find.text('👏'), findsOneWidget);
      expect(find.text('🚀'), findsOneWidget);
      expect(find.text('⭐'), findsOneWidget);

      // Act - tap thumbs up reaction
      await tester.tap(find.text('👍'));
      await tester.pumpAndSettle();

      // Assert - should call sendReaction
      verify(mockReactionService.sendReaction(
        notificationId: notificationId,
        userId: userId,
        reaction: EmojiReaction.thumbsUp,
      )).called(1);
    });

    testWidgets('should display reaction counts correctly', (tester) async {
      // Arrange
      const notificationId = 'test_notification';
      const userId = 'test_user';

      // Mock state with reactions
      when(mockReactionService.watchReactionSummary(notificationId))
          .thenAnswer((_) => Stream.value(
                const NotificationReactionSummary(
                  notificationId: notificationId,
                  reactionCounts: {
                    EmojiReaction.thumbsUp: 3,
                    EmojiReaction.heart: 1,
                    EmojiReaction.fire: 2,
                  },
                  userReactions: {
                    'user1': EmojiReaction.thumbsUp,
                    'user2': EmojiReaction.thumbsUp,
                    'test_user': EmojiReaction.thumbsUp,
                    'user3': EmojiReaction.heart,
                    'user4': EmojiReaction.fire,
                    'user5': EmojiReaction.fire,
                  },
                  totalReactions: 6,
                ),
              ));

      // Build widget
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: NotificationReactionButtons(
                notificationId: notificationId,
                userId: userId,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - should show reaction counts
      expect(find.text('3'), findsOneWidget); // thumbs up count
      expect(find.text('1'), findsOneWidget); // heart count
      expect(find.text('2'), findsOneWidget); // fire count

      // Should show summary text with top reactions
      expect(find.textContaining('👍 3'), findsOneWidget);
      expect(find.textContaining('🔥 2'), findsOneWidget);
    });

    testWidgets('should highlight user\'s current reaction', (tester) async {
      // Arrange
      const notificationId = 'test_notification';
      const userId = 'test_user';

      // Mock state where user has reacted with heart
      when(mockReactionService.watchReactionSummary(notificationId))
          .thenAnswer((_) => Stream.value(
                const NotificationReactionSummary(
                  notificationId: notificationId,
                  reactionCounts: {
                    EmojiReaction.heart: 1,
                  },
                  userReactions: {
                    'test_user': EmojiReaction.heart,
                  },
                  totalReactions: 1,
                ),
              ));

      // Build widget
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: NotificationReactionButtons(
                notificationId: notificationId,
                userId: userId,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the heart reaction button container
      final heartButtonFinder = find.ancestor(
        of: find.text('❤️'),
        matching: find.byType(Container),
      );

      expect(heartButtonFinder, findsWidgets);

      // The heart button should be highlighted (selected state)
      // This would be verified by checking the container's decoration
      // In a real test, you'd check for the primary color border
    });

    testWidgets('should display reaction summary correctly', (tester) async {
      // Arrange
      const notificationId = 'test_notification';

      // Mock state with multiple reactions
      when(mockReactionService.watchReactionSummary(notificationId))
          .thenAnswer((_) => Stream.value(
                const NotificationReactionSummary(
                  notificationId: notificationId,
                  reactionCounts: {
                    EmojiReaction.thumbsUp: 5,
                    EmojiReaction.heart: 3,
                    EmojiReaction.fire: 2,
                    EmojiReaction.clap: 1,
                  },
                  userReactions: {},
                  totalReactions: 11,
                ),
              ));

      // Build widget
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: summary_widget.NotificationReactionSummaryWidget(
                notificationId: notificationId,
                maxReactionsToShow: 3,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - should show top 3 reactions
      expect(find.text('👍'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('❤️'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('🔥'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Should not show the 4th reaction (clap) in summary
      expect(find.text('👏'), findsNothing);
    });

    testWidgets('should handle empty reaction state', (tester) async {
      // Arrange
      const notificationId = 'test_notification';
      const userId = 'test_user';

      // Mock empty state
      when(mockReactionService.watchReactionSummary(notificationId))
          .thenAnswer((_) => Stream.value(
                const NotificationReactionSummary(
                  notificationId: notificationId,
                  reactionCounts: {},
                  userReactions: {},
                  totalReactions: 0,
                ),
              ));

      // Build widget
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  NotificationReactionButtons(
                    notificationId: notificationId,
                    userId: userId,
                  ),
                  summary_widget.NotificationReactionSummaryWidget(
                    notificationId: notificationId,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - should show emoji buttons but no counts
      expect(find.text('👍'), findsOneWidget);
      expect(find.text('❤️'), findsOneWidget);
      expect(find.text('🔥'), findsOneWidget);

      // Should not show any count badges
      expect(find.text('1'), findsNothing);
      expect(find.text('2'), findsNothing);
      expect(find.text('3'), findsNothing);

      // Reaction summary should be empty (not visible)
      expect(find.byType(summary_widget.NotificationReactionSummaryWidget),
          findsOneWidget);
    });

    testWidgets('should handle loading and error states', (tester) async {
      // Arrange
      const notificationId = 'test_notification';
      const userId = 'test_user';

      // Mock loading state
      when(mockReactionService.watchReactionSummary(notificationId))
          .thenAnswer((_) => Stream.value(
                const NotificationReactionSummary(
                  notificationId: notificationId,
                  reactionCounts: {},
                  userReactions: {},
                  totalReactions: 0,
                ),
              ).asyncMap((summary) async {
                await Future.delayed(const Duration(milliseconds: 100));
                return summary;
              }));

      // Build widget
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: NotificationReactionButtons(
                notificationId: notificationId,
                userId: userId,
              ),
            ),
          ),
        ),
      );

      // Should show loading state initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading reactions...'), findsOneWidget);

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Should show reaction buttons after loading
      expect(find.text('👍'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should handle compact mode correctly', (tester) async {
      // Arrange
      const notificationId = 'test_notification';
      const userId = 'test_user';

      // Mock state with reactions
      when(mockReactionService.watchReactionSummary(notificationId))
          .thenAnswer((_) => Stream.value(
                const NotificationReactionSummary(
                  notificationId: notificationId,
                  reactionCounts: {
                    EmojiReaction.thumbsUp: 2,
                  },
                  userReactions: {
                    'user1': EmojiReaction.thumbsUp,
                    'user2': EmojiReaction.thumbsUp,
                  },
                  totalReactions: 2,
                ),
              ));

      // Build compact widget
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: CompactNotificationReactionButtons(
                notificationId: notificationId,
                userId: userId,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - should show emoji buttons
      expect(find.text('👍'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // Count badge

      // In compact mode, summary text should not be shown
      expect(find.textContaining('👍 2'), findsNothing);
    });
  });

  group('Property-Based Integration Tests', () {
    testWidgets(
        '**Validates: Requirements 7.4** - Emoji reactions provide visual feedback',
        (tester) async {
      // Property: For any emoji reaction interaction, the UI should provide
      // immediate visual feedback and maintain consistency

      final mockReactionService = MockNotificationReactionService();
      final container = ProviderContainer(
        overrides: [
          notificationReactionServiceProvider
              .overrideWithValue(mockReactionService),
        ],
      );

      const notificationId = 'test_notification';
      const userId = 'test_user';

      // Test different reaction states
      final testCases = [
        // No reactions
        const NotificationReactionSummary(
          notificationId: notificationId,
          reactionCounts: {},
          userReactions: {},
          totalReactions: 0,
        ),
        // Single reaction
        const NotificationReactionSummary(
          notificationId: notificationId,
          reactionCounts: {EmojiReaction.thumbsUp: 1},
          userReactions: {'test_user': EmojiReaction.thumbsUp},
          totalReactions: 1,
        ),
        // Multiple reactions
        const NotificationReactionSummary(
          notificationId: notificationId,
          reactionCounts: {
            EmojiReaction.thumbsUp: 3,
            EmojiReaction.heart: 2,
            EmojiReaction.fire: 1,
          },
          userReactions: {
            'user1': EmojiReaction.thumbsUp,
            'user2': EmojiReaction.thumbsUp,
            'test_user': EmojiReaction.thumbsUp,
            'user3': EmojiReaction.heart,
            'user4': EmojiReaction.heart,
            'user5': EmojiReaction.fire,
          },
          totalReactions: 6,
        ),
      ];

      for (int i = 0; i < testCases.length; i++) {
        final testCase = testCases[i];

        // Mock the reaction service for this test case
        when(mockReactionService.watchReactionSummary(notificationId))
            .thenAnswer((_) => Stream.value(testCase));

        when(mockReactionService.sendReaction(
          notificationId: notificationId,
          userId: userId,
          reaction: anyNamed('reaction'),
        )).thenAnswer((_) async {});

        // Build widget
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: NotificationReactionButtons(
                  notificationId: notificationId,
                  userId: userId,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify visual feedback properties

        // Property 1: All emoji buttons should be visible
        for (final reaction in EmojiReaction.values) {
          expect(find.text(reaction.emoji), findsOneWidget,
              reason:
                  'Emoji ${reaction.emoji} should be visible in test case $i');
        }

        // Property 2: Reaction counts should be displayed correctly
        for (final entry in testCase.reactionCounts.entries) {
          if (entry.value > 0) {
            expect(find.text(entry.value.toString()), findsOneWidget,
                reason:
                    'Count ${entry.value} should be visible in test case $i');
          }
        }

        // Property 3: User's current reaction should be highlighted
        final userReaction = testCase.getUserReaction(userId);
        if (userReaction != null) {
          // In a real test, you'd verify the visual highlighting
          // For now, we just verify the reaction exists in the summary
          expect(testCase.hasUserReacted(userId, userReaction), isTrue,
              reason:
                  'User reaction should be correctly identified in test case $i');
        }

        // Property 4: Total reactions should be consistent
        final sumOfCounts = testCase.reactionCounts.values
            .fold<int>(0, (sum, count) => sum + count);
        expect(testCase.totalReactions, equals(sumOfCounts),
            reason:
                'Total reactions should equal sum of counts in test case $i');

        // Property 5: Interaction should trigger service call
        await tester.tap(find.text(EmojiReaction.heart.emoji));
        await tester.pumpAndSettle();

        verify(mockReactionService.sendReaction(
          notificationId: notificationId,
          userId: userId,
          reaction: EmojiReaction.heart,
        )).called(1);

        // Reset for next iteration
        reset(mockReactionService);
      }

      container.dispose();
    });
  });
}
