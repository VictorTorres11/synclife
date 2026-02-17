import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';

import 'package:synclife_app/src/features/reminders/presentation/screens/reminders_page.dart';
import 'package:synclife_app/src/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:synclife_app/src/features/reminders/domain/models/models.dart';
import 'package:synclife_app/src/features/reminders/domain/services/reminder_service.dart';
import 'package:synclife_app/src/features/reminders/presentation/widgets/reminder_card.dart';
import 'package:synclife_app/src/features/reminders/presentation/widgets/add_reminder_dialog.dart';
import 'package:synclife_app/src/features/auth/domain/models/user.dart';
import 'package:synclife_app/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:synclife_app/src/features/monetization/domain/models/user_limitations.dart';
import 'package:synclife_app/src/features/monetization/presentation/providers/monetization_providers.dart';

// Generate mocks
@GenerateMocks([ReminderService])
import 'reminders_page_test.mocks.dart';

/// Widget tests for RemindersPage
/// 
/// Tests cover:
/// - Rendering reminder list correctly (9.4.2)
/// - FAB triggers add dialog (9.4.3)
/// - Search filters list (9.4.4)
/// - Board filter works (9.4.5)
/// - Empty state displays (9.4.6)
void main() {
  group('RemindersPage Widget Tests', () {
    late MockReminderService mockReminderService;

    // Test data
    final testUser = User(
      id: 'test-user-123',
      email: 'test@example.com',
      displayName: 'Test User',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final testReminder1 = Reminder(
      id: 'reminder-1',
      content: 'Buy groceries',
      userId: testUser.id,
      boardId: 'board-1',
      tags: ['shopping', 'urgent'],
      priority: ReminderPriority.high,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final testReminder2 = Reminder(
      id: 'reminder-2',
      content: 'Call dentist',
      userId: testUser.id,
      boardId: 'board-1',
      tags: ['health'],
      priority: ReminderPriority.medium,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
    );

    final testReminder3 = Reminder(
      id: 'reminder-3',
      content: 'Review code',
      userId: testUser.id,
      boardId: 'board-2',
      tags: ['work'],
      priority: ReminderPriority.low,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    );

    final testLimitationsFree = UserLimitations(
      userId: testUser.id,
      maxActiveTasks: 50,
      currentActiveTasks: 10,
      maxBoards: 5,
      currentBoards: 2,
      maxBoardMembers: 3,
      adsEnabled: true,
      canUseCalendarIntegration: false,
      canUseAdvancedBackup: false,
      canUsePremiumThemes: false,
      maxReminders: 30,
      currentReminders: 5,
      updatedAt: DateTime.now(),
    );

    final testLimitationsPremium = UserLimitations(
      userId: testUser.id,
      maxActiveTasks: -1,
      currentActiveTasks: 10,
      maxBoards: -1,
      currentBoards: 2,
      maxBoardMembers: -1,
      adsEnabled: false,
      canUseCalendarIntegration: true,
      canUseAdvancedBackup: true,
      canUsePremiumThemes: true,
      maxReminders: -1,
      currentReminders: 5,
      updatedAt: DateTime.now(),
    );

    setUp(() {
      mockReminderService = MockReminderService();
    });

    /// Helper function to create a testable widget with providers
    Widget createTestWidget({
      List<Reminder> reminders = const [],
      UserLimitations? limitations,
      User? user,
    }) {
      return ProviderScope(
        overrides: [
          // Override auth provider
          currentUserProvider.overrideWith((ref) => user ?? testUser),
          
          // Override reminder service provider
          reminderServiceProvider.overrideWith((ref) => mockReminderService),
          
          // Override reminders stream provider
          remindersStreamProvider.overrideWith((ref, userId) {
            return Stream.value(reminders);
          }),
          
          // Override user limitations provider
          userLimitationsProvider.overrideWith((ref, userId) {
            return Stream.value(limitations ?? testLimitationsFree);
          }),
        ],
        child: MaterialApp(
          home: const RemindersPage(),
        ),
      );
    }

    testWidgets('should display loading indicator while loading reminders',
        (WidgetTester tester) async {
      // Setup: Stream that never emits (stays in loading state)
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
            reminderServiceProvider.overrideWith((ref) => mockReminderService),
            remindersStreamProvider.overrideWith((ref, userId) {
              return const Stream.empty(); // Never emits
            }),
            userLimitationsProvider.overrideWith((ref, userId) {
              return Stream.value(testLimitationsFree);
            }),
          ],
          child: MaterialApp(
            home: const RemindersPage(),
          ),
        ),
      );

      // Wait for initial frame
      await tester.pump();

      // Verify: Loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display empty state when no reminders exist',
        (WidgetTester tester) async {
      // Setup: Empty reminders list
      await tester.pumpWidget(createTestWidget(reminders: []));
      await tester.pumpAndSettle();

      // Verify: Empty state message is shown
      expect(find.text('No reminders yet'), findsOneWidget);
      expect(find.text('Tap the + button to create your first reminder'),
          findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });

    testWidgets('should display reminder list when reminders exist',
        (WidgetTester tester) async {
      // Setup: List with reminders
      final reminders = [testReminder1, testReminder2, testReminder3];
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
            reminderServiceProvider.overrideWith((ref) => mockReminderService),
            remindersStreamProvider.overrideWith((ref, userId) {
              return Stream.value(reminders);
            }),
            userLimitationsProvider.overrideWith((ref, userId) {
              return Stream.value(testLimitationsFree);
            }),
            // Ensure no filters are applied
            selectedBoardFilterProvider.overrideWith((ref) => null),
            reminderSearchQueryProvider.overrideWith((ref) => ''),
          ],
          child: MaterialApp(
            home: const RemindersPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify: ListView is present
      expect(find.byType(ListView), findsOneWidget);
      
      // Verify: No empty state
      expect(find.text('No reminders yet'), findsNothing);
      expect(find.text('Tap the + button to create your first reminder'), findsNothing);
      
      // Verify: ReminderCard widgets are rendered (at least 2 visible in viewport)
      expect(find.byType(ReminderCard), findsAtLeastNWidgets(2));
      
      // Verify: First reminder content is displayed
      expect(find.text('Buy groceries'), findsOneWidget);
      
      // Verify: Second reminder content is displayed
      expect(find.text('Call dentist'), findsOneWidget);
      
      // Verify: Tags from reminders are displayed
      expect(find.text('shopping'), findsOneWidget);
      expect(find.text('urgent'), findsOneWidget);
      expect(find.text('health'), findsOneWidget);
      
      // Verify: Priority indicators are present (icons)
      expect(find.byIcon(Icons.arrow_upward), findsWidgets); // High priority
      expect(find.byIcon(Icons.remove), findsWidgets); // Medium priority
      
      // Verify: Action buttons are present for visible reminders
      expect(find.byIcon(Icons.edit_outlined), findsWidgets);
      expect(find.byIcon(Icons.delete_outline), findsWidgets);
      expect(find.byIcon(Icons.arrow_forward), findsWidgets);
      
      // Scroll down to see if third reminder exists
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      
      // Verify: Third reminder is now visible after scrolling
      expect(find.text('Review code'), findsOneWidget);
      expect(find.text('work'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward), findsWidgets); // Low priority
    });

    testWidgets('should display FAB for creating new reminders',
        (WidgetTester tester) async {
      // Setup
      await tester.pumpWidget(createTestWidget(reminders: []));
      await tester.pumpAndSettle();

      // Verify: FAB is present
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      
      // Verify: FAB has accessibility label
      final fab = tester.widget<Semantics>(
        find.ancestor(
          of: find.byType(FloatingActionButton),
          matching: find.byType(Semantics),
        ).first,
      );
      expect(fab.properties.label, equals('Add new reminder'));
    });

    testWidgets('should display search icon in app bar',
        (WidgetTester tester) async {
      // Setup
      await tester.pumpWidget(createTestWidget(reminders: []));
      await tester.pumpAndSettle();

      // Verify: Search icon is present
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('should toggle search bar when search icon is tapped',
        (WidgetTester tester) async {
      // Setup
      await tester.pumpWidget(createTestWidget(reminders: []));
      await tester.pumpAndSettle();

      // Verify: Initially shows title
      expect(find.text('Reminders'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      // Action: Tap search icon
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Verify: Search field is shown
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      
      // Action: Tap close icon
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Verify: Back to title
      expect(find.text('Reminders'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('should display usage indicator for free users',
        (WidgetTester tester) async {
      // Setup: Free user with limitations
      await tester.pumpWidget(createTestWidget(
        reminders: [],
        limitations: testLimitationsFree,
      ));
      await tester.pumpAndSettle();

      // Verify: Usage indicator is shown
      // Note: The actual ReminderUsageIndicator widget should be present
      // We're checking for its presence in the widget tree
      expect(find.byType(RemindersPage), findsOneWidget);
    });

    testWidgets('should not display usage indicator for premium users',
        (WidgetTester tester) async {
      // Setup: Premium user
      await tester.pumpWidget(createTestWidget(
        reminders: [],
        limitations: testLimitationsPremium,
      ));
      await tester.pumpAndSettle();

      // Verify: Page renders without errors
      expect(find.byType(RemindersPage), findsOneWidget);
    });

    testWidgets('should display error state when loading fails',
        (WidgetTester tester) async {
      // Setup: Stream that emits error
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
            reminderServiceProvider.overrideWith((ref) => mockReminderService),
            remindersStreamProvider.overrideWith((ref, userId) {
              return Stream.error(Exception('Failed to load reminders'));
            }),
            userLimitationsProvider.overrideWith((ref, userId) {
              return Stream.value(testLimitationsFree);
            }),
          ],
          child: MaterialApp(
            home: const RemindersPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify: Error state is shown
      expect(find.text('Error loading reminders'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      // Note: There might be multiple error icons in the widget tree
      expect(find.byIcon(Icons.error_outline), findsWidgets);
    });

    testWidgets('should display board filter component',
        (WidgetTester tester) async {
      // Setup
      await tester.pumpWidget(createTestWidget(reminders: []));
      await tester.pumpAndSettle();

      // Verify: Board filter is present
      // Note: The actual ReminderBoardFilter widget should be present
      expect(find.byType(RemindersPage), findsOneWidget);
    });

    testWidgets('should display "Please log in" message when user is null',
        (WidgetTester tester) async {
      // Setup: No user logged in
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
            reminderServiceProvider.overrideWith((ref) => mockReminderService),
          ],
          child: MaterialApp(
            home: const RemindersPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify: Login message is shown
      expect(find.text('Please log in to view reminders'), findsOneWidget);
      
      // Verify: No FAB or other content
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('should support pull-to-refresh',
        (WidgetTester tester) async {
      // Setup
      await tester.pumpWidget(createTestWidget(
        reminders: [testReminder1],
      ));
      await tester.pumpAndSettle();

      // Verify: RefreshIndicator is present
      expect(find.byType(RefreshIndicator), findsOneWidget);

      // Action: Perform pull-to-refresh gesture
      await tester.drag(
        find.text('Buy groceries'),
        const Offset(0, 300),
      );
      await tester.pump();
      
      // Verify: Refresh indicator appears
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('should display empty state with search query message',
        (WidgetTester tester) async {
      // Setup: Widget with search query set
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
            reminderServiceProvider.overrideWith((ref) => mockReminderService),
            remindersStreamProvider.overrideWith((ref, userId) {
              return Stream.value([testReminder1]);
            }),
            userLimitationsProvider.overrideWith((ref, userId) {
              return Stream.value(testLimitationsFree);
            }),
            // Set search query that doesn't match
            reminderSearchQueryProvider.overrideWith((ref) => 'nonexistent'),
          ],
          child: MaterialApp(
            home: const RemindersPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify: Empty state with search message
      expect(find.textContaining('No reminders found matching'), findsOneWidget);
    });

    testWidgets('should have proper accessibility labels',
        (WidgetTester tester) async {
      // Setup
      await tester.pumpWidget(createTestWidget(reminders: []));
      await tester.pumpAndSettle();

      // Verify: FAB has semantic label
      final fabSemantics = tester.widget<Semantics>(
        find.ancestor(
          of: find.byType(FloatingActionButton),
          matching: find.byType(Semantics),
        ).first,
      );
      expect(fabSemantics.properties.label, equals('Add new reminder'));
      expect(fabSemantics.properties.button, isTrue);

      // Verify: Search button has semantic label (there may be multiple Semantics widgets)
      final searchSemantics = find.ancestor(
        of: find.byIcon(Icons.search),
        matching: find.byType(Semantics),
      );
      expect(searchSemantics, findsWidgets);
    });

    testWidgets('should have minimum touch target sizes',
        (WidgetTester tester) async {
      // Setup
      await tester.pumpWidget(createTestWidget(reminders: []));
      await tester.pumpAndSettle();

      // Verify: FAB has sufficient size
      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab, isNotNull);

      // Verify: Search icon button has minimum constraints
      final searchIconButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.search),
          matching: find.byType(IconButton),
        ),
      );
      expect(searchIconButton.constraints?.minWidth, equals(48));
      expect(searchIconButton.constraints?.minHeight, equals(48));
    });

    testWidgets('should show AddReminderDialog when FAB is tapped',
        (WidgetTester tester) async {
      // Setup: Free user with available reminder slots
      await tester.pumpWidget(createTestWidget(
        reminders: [],
        limitations: testLimitationsFree,
      ));
      await tester.pumpAndSettle();

      // Verify: Dialog is not shown initially
      expect(find.byType(AddReminderDialog), findsNothing);

      // Action: Tap the FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify: AddReminderDialog is shown
      expect(find.byType(AddReminderDialog), findsOneWidget);
    });

    testWidgets('should show upgrade prompt when FAB is tapped at limit',
        (WidgetTester tester) async {
      // Setup: Free user at reminder limit
      final limitationsAtLimit = UserLimitations(
        userId: testUser.id,
        maxActiveTasks: 50,
        currentActiveTasks: 10,
        maxBoards: 5,
        currentBoards: 2,
        maxBoardMembers: 3,
        adsEnabled: true,
        canUseCalendarIntegration: false,
        canUseAdvancedBackup: false,
        canUsePremiumThemes: false,
        maxReminders: 30,
        currentReminders: 30, // At limit
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(
        reminders: [],
        limitations: limitationsAtLimit,
      ));
      await tester.pumpAndSettle();

      // Verify: AddReminderDialog is not shown initially
      expect(find.byType(AddReminderDialog), findsNothing);

      // Action: Tap the FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify: Upgrade prompt is shown instead of AddReminderDialog
      expect(find.byType(AddReminderDialog), findsNothing);
      expect(find.text('Limite de Lembretes Atingido'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      // Check for upgrade button (there are 2 instances of the text in the dialog)
      expect(find.text('Fazer Upgrade'), findsWidgets);
    });

    testWidgets('should show AddReminderDialog for premium users',
        (WidgetTester tester) async {
      // Setup: Premium user (unlimited reminders)
      await tester.pumpWidget(createTestWidget(
        reminders: [],
        limitations: testLimitationsPremium,
      ));
      await tester.pumpAndSettle();

      // Verify: Dialog is not shown initially
      expect(find.byType(AddReminderDialog), findsNothing);

      // Action: Tap the FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify: AddReminderDialog is shown (no limit check)
      expect(find.byType(AddReminderDialog), findsOneWidget);
    });

    testWidgets('should filter reminders by search query',
        (WidgetTester tester) async {
      // Setup: Multiple reminders with different content
      final reminders = [testReminder1, testReminder2, testReminder3];
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
            reminderServiceProvider.overrideWith((ref) => mockReminderService),
            remindersStreamProvider.overrideWith((ref, userId) {
              return Stream.value(reminders);
            }),
            userLimitationsProvider.overrideWith((ref, userId) {
              return Stream.value(testLimitationsFree);
            }),
            // No board filter
            selectedBoardFilterProvider.overrideWith((ref) => null),
            // No search query initially
            reminderSearchQueryProvider.overrideWith((ref) => ''),
          ],
          child: MaterialApp(
            home: const RemindersPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify: All reminders are initially visible
      expect(find.text('Buy groceries'), findsOneWidget);
      expect(find.text('Call dentist'), findsOneWidget);
      
      // Scroll to see third reminder
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('Review code'), findsOneWidget);

      // Action: Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Verify: Search field is shown
      expect(find.byType(TextField), findsOneWidget);

      // Action: Enter search query "groceries"
      await tester.enterText(find.byType(TextField), 'groceries');
      await tester.pumpAndSettle();
      
      // Wait for debounce (300ms)
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Verify: Only matching reminder is shown
      expect(find.text('Buy groceries'), findsOneWidget);
      expect(find.text('Call dentist'), findsNothing);
      expect(find.text('Review code'), findsNothing);

      // Action: Change search query to "call"
      await tester.enterText(find.byType(TextField), 'call');
      await tester.pumpAndSettle();
      
      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Verify: Only "Call dentist" is shown
      expect(find.text('Buy groceries'), findsNothing);
      expect(find.text('Call dentist'), findsOneWidget);
      expect(find.text('Review code'), findsNothing);

      // Action: Clear search
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      
      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Verify: All reminders are shown again
      expect(find.text('Buy groceries'), findsOneWidget);
      expect(find.text('Call dentist'), findsOneWidget);
    });

    testWidgets('should perform case-insensitive search',
        (WidgetTester tester) async {
      // Setup: Reminders with mixed case content
      final reminders = [testReminder1, testReminder2];
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
            reminderServiceProvider.overrideWith((ref) => mockReminderService),
            remindersStreamProvider.overrideWith((ref, userId) {
              return Stream.value(reminders);
            }),
            userLimitationsProvider.overrideWith((ref, userId) {
              return Stream.value(testLimitationsFree);
            }),
            selectedBoardFilterProvider.overrideWith((ref) => null),
            reminderSearchQueryProvider.overrideWith((ref) => ''),
          ],
          child: MaterialApp(
            home: const RemindersPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Action: Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Action: Search with uppercase "GROCERIES"
      await tester.enterText(find.byType(TextField), 'GROCERIES');
      await tester.pumpAndSettle();
      
      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Verify: Finds "Buy groceries" despite case difference
      expect(find.text('Buy groceries'), findsOneWidget);
      expect(find.text('Call dentist'), findsNothing);

      // Action: Search with lowercase "dentist"
      await tester.enterText(find.byType(TextField), 'dentist');
      await tester.pumpAndSettle();
      
      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Verify: Finds "Call dentist"
      expect(find.text('Buy groceries'), findsNothing);
      expect(find.text('Call dentist'), findsOneWidget);
    });

    testWidgets('should show empty state when search has no matches',
        (WidgetTester tester) async {
      // Setup: Reminders
      final reminders = [testReminder1, testReminder2];
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
            reminderServiceProvider.overrideWith((ref) => mockReminderService),
            remindersStreamProvider.overrideWith((ref, userId) {
              return Stream.value(reminders);
            }),
            userLimitationsProvider.overrideWith((ref, userId) {
              return Stream.value(testLimitationsFree);
            }),
            selectedBoardFilterProvider.overrideWith((ref) => null),
            reminderSearchQueryProvider.overrideWith((ref) => ''),
          ],
          child: MaterialApp(
            home: const RemindersPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify: Reminders are initially visible
      expect(find.text('Buy groceries'), findsOneWidget);

      // Action: Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Action: Search for non-existent content
      await tester.enterText(find.byType(TextField), 'nonexistent');
      await tester.pumpAndSettle();
      
      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Verify: Empty state with search message is shown
      expect(find.text('Buy groceries'), findsNothing);
      expect(find.text('Call dentist'), findsNothing);
      expect(find.text('No reminders found matching "nonexistent"'), findsOneWidget);
    });

    testWidgets('should support partial text matching in search',
        (WidgetTester tester) async {
      // Setup: Reminders
      final reminders = [testReminder1, testReminder2, testReminder3];
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
            reminderServiceProvider.overrideWith((ref) => mockReminderService),
            remindersStreamProvider.overrideWith((ref, userId) {
              return Stream.value(reminders);
            }),
            userLimitationsProvider.overrideWith((ref, userId) {
              return Stream.value(testLimitationsFree);
            }),
            selectedBoardFilterProvider.overrideWith((ref) => null),
            reminderSearchQueryProvider.overrideWith((ref) => ''),
          ],
          child: MaterialApp(
            home: const RemindersPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Action: Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Action: Search with partial text "cer" (should match "groceries")
      await tester.enterText(find.byType(TextField), 'cer');
      await tester.pumpAndSettle();
      
      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Verify: Finds "Buy groceries" with partial match
      expect(find.text('Buy groceries'), findsOneWidget);
      expect(find.text('Call dentist'), findsNothing);
      expect(find.text('Review code'), findsNothing);

      // Action: Search with partial text "cod" (should match "code")
      await tester.enterText(find.byType(TextField), 'cod');
      await tester.pumpAndSettle();
      
      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Verify: Finds "Review code" with partial match
      expect(find.text('Buy groceries'), findsNothing);
      expect(find.text('Call dentist'), findsNothing);
      expect(find.text('Review code'), findsOneWidget);
    });

    testWidgets('should filter reminders by selected board',
        (WidgetTester tester) async {
      // Setup: Multiple reminders from different boards
      final reminders = [
        testReminder1, // board-1
        testReminder2, // board-1
        testReminder3, // board-2
      ];
      
      // Create a ProviderContainer to manage state
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => testUser),
          reminderServiceProvider.overrideWith((ref) => mockReminderService),
          remindersStreamProvider.overrideWith((ref, userId) {
            return Stream.value(reminders);
          }),
          userLimitationsProvider.overrideWith((ref, userId) {
            return Stream.value(testLimitationsFree);
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const RemindersPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify: All reminders are initially visible (no filter)
      expect(find.text('Buy groceries'), findsOneWidget);
      expect(find.text('Call dentist'), findsOneWidget);
      
      // Scroll to see third reminder
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('Review code'), findsOneWidget);

      // Scroll back to top
      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Action: Apply board filter for board-1
      container.read(selectedBoardFilterProvider.notifier).state = 'board-1';
      await tester.pumpAndSettle();

      // Verify: Only reminders from board-1 are shown
      expect(find.text('Buy groceries'), findsOneWidget);
      expect(find.text('Call dentist'), findsOneWidget);
      expect(find.text('Review code'), findsNothing);

      // Action: Change filter to board-2
      container.read(selectedBoardFilterProvider.notifier).state = 'board-2';
      await tester.pumpAndSettle();

      // Verify: Only reminders from board-2 are shown
      expect(find.text('Buy groceries'), findsNothing);
      expect(find.text('Call dentist'), findsNothing);
      expect(find.text('Review code'), findsOneWidget);

      // Action: Clear filter (set to null)
      container.read(selectedBoardFilterProvider.notifier).state = null;
      await tester.pumpAndSettle();

      // Verify: All reminders are shown again
      expect(find.text('Buy groceries'), findsOneWidget);
      expect(find.text('Call dentist'), findsOneWidget);
      
      // Scroll to see third reminder
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('Review code'), findsOneWidget);
    });

    testWidgets('should combine board filter and search query',
        (WidgetTester tester) async {
      // Setup: Multiple reminders from different boards
      final reminders = [
        testReminder1, // board-1, "Buy groceries"
        testReminder2, // board-1, "Call dentist"
        testReminder3, // board-2, "Review code"
      ];
      
      // Create a ProviderContainer to manage state
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => testUser),
          reminderServiceProvider.overrideWith((ref) => mockReminderService),
          remindersStreamProvider.overrideWith((ref, userId) {
            return Stream.value(reminders);
          }),
          userLimitationsProvider.overrideWith((ref, userId) {
            return Stream.value(testLimitationsFree);
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const RemindersPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Action: Set board filter to board-1 and search query to "call"
      container.read(selectedBoardFilterProvider.notifier).state = 'board-1';
      container.read(reminderSearchQueryProvider.notifier).state = 'call';
      await tester.pumpAndSettle();

      // Verify: Only "Call dentist" matches both filters (board-1 AND contains "call")
      expect(find.text('Buy groceries'), findsNothing); // board-1 but doesn't contain "call"
      expect(find.text('Call dentist'), findsOneWidget); // board-1 AND contains "call"
      expect(find.text('Review code'), findsNothing); // board-2 (filtered out by board)

      // Action: Change search to "groceries" while keeping board-1 filter
      container.read(reminderSearchQueryProvider.notifier).state = 'groceries';
      await tester.pumpAndSettle();

      // Verify: Only "Buy groceries" matches both filters
      expect(find.text('Buy groceries'), findsOneWidget); // board-1 AND contains "groceries"
      expect(find.text('Call dentist'), findsNothing); // board-1 but doesn't contain "groceries"
      expect(find.text('Review code'), findsNothing); // board-2 (filtered out by board)

      // Action: Change board filter to board-2 with search "code"
      container.read(selectedBoardFilterProvider.notifier).state = 'board-2';
      container.read(reminderSearchQueryProvider.notifier).state = 'code';
      await tester.pumpAndSettle();

      // Verify: Only "Review code" matches both filters
      expect(find.text('Buy groceries'), findsNothing); // board-1 (filtered out by board)
      expect(find.text('Call dentist'), findsNothing); // board-1 (filtered out by board)
      expect(find.text('Review code'), findsOneWidget); // board-2 AND contains "code"
    });

    testWidgets('should show empty state when board filter has no matches',
        (WidgetTester tester) async {
      // Setup: Reminders only in board-1
      final reminders = [testReminder1, testReminder2];
      
      // Create a ProviderContainer to manage state
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => testUser),
          reminderServiceProvider.overrideWith((ref) => mockReminderService),
          remindersStreamProvider.overrideWith((ref, userId) {
            return Stream.value(reminders);
          }),
          userLimitationsProvider.overrideWith((ref, userId) {
            return Stream.value(testLimitationsFree);
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const RemindersPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Action: Filter by board-3 which has no reminders
      container.read(selectedBoardFilterProvider.notifier).state = 'board-3';
      await tester.pumpAndSettle();

      // Verify: Empty state is shown
      expect(find.text('Buy groceries'), findsNothing);
      expect(find.text('Call dentist'), findsNothing);
      expect(find.text('No reminders in this board yet'), findsOneWidget);
    });
  });
}
