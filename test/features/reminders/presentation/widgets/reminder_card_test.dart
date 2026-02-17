import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synclife_app/src/features/reminders/domain/models/reminder.dart';
import 'package:synclife_app/src/features/reminders/domain/models/reminder_priority.dart';
import 'package:synclife_app/src/features/reminders/presentation/widgets/reminder_card.dart';

void main() {
  group('ReminderCard', () {
    late Reminder testReminder;
    late bool editCalled;
    late bool deleteCalled;
    late bool convertCalled;

    setUp(() {
      editCalled = false;
      deleteCalled = false;
      convertCalled = false;

      testReminder = Reminder(
        id: 'test-id',
        content: 'Test reminder content',
        userId: 'user-123',
        boardId: 'board-456',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        tags: ['tag1', 'tag2'],
        priority: ReminderPriority.high,
      );
    });

    Widget buildTestWidget(Reminder reminder) {
      return MaterialApp(
        home: Scaffold(
          body: ReminderCard(
            reminder: reminder,
            onEdit: () => editCalled = true,
            onDelete: () => deleteCalled = true,
            onConvert: () => convertCalled = true,
          ),
        ),
      );
    }

    testWidgets('displays reminder content', (tester) async {
      await tester.pumpWidget(buildTestWidget(testReminder));

      expect(find.text('Test reminder content'), findsOneWidget);
    });

    testWidgets('displays priority indicator', (tester) async {
      await tester.pumpWidget(buildTestWidget(testReminder));

      // Find the priority indicator container (now with icon)
      final priorityIndicator = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).borderRadius != null,
      );

      expect(priorityIndicator, findsWidgets);
      
      // Verify icon is present
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget); // High priority icon
    });

    testWidgets('displays tags as chips', (tester) async {
      await tester.pumpWidget(buildTestWidget(testReminder));

      expect(find.text('tag1'), findsOneWidget);
      expect(find.text('tag2'), findsOneWidget);
      expect(find.byType(Chip), findsNWidgets(2));
    });

    testWidgets('does not display tags section when no tags', (tester) async {
      final reminderNoTags = testReminder.copyWith(tags: []);
      await tester.pumpWidget(buildTestWidget(reminderNoTags));

      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('displays edit button', (tester) async {
      await tester.pumpWidget(buildTestWidget(testReminder));

      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byTooltip('Edit'), findsOneWidget);
    });

    testWidgets('displays delete button', (tester) async {
      await tester.pumpWidget(buildTestWidget(testReminder));

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(find.byTooltip('Delete'), findsOneWidget);
    });

    testWidgets('displays convert to task button', (tester) async {
      await tester.pumpWidget(buildTestWidget(testReminder));

      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.byTooltip('Convert to Task'), findsOneWidget);
    });

    testWidgets('calls onEdit when edit button is tapped', (tester) async {
      await tester.pumpWidget(buildTestWidget(testReminder));

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(editCalled, isTrue);
    });

    testWidgets('calls onDelete when delete button is tapped', (tester) async {
      await tester.pumpWidget(buildTestWidget(testReminder));

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(deleteCalled, isTrue);
    });

    testWidgets('calls onConvert when convert button is tapped',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(testReminder));

      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();

      expect(convertCalled, isTrue);
    });

    testWidgets('calls onEdit when card is tapped', (tester) async {
      await tester.pumpWidget(buildTestWidget(testReminder));

      // Tap on the card's InkWell (the first one, which is the card itself)
      await tester.tap(find.byType(Card));
      await tester.pumpAndSettle();

      expect(editCalled, isTrue);
    });

    testWidgets('has accessibility labels for priority', (tester) async {
      await tester.pumpWidget(buildTestWidget(testReminder));

      // Check for semantic label on priority indicator
      final semantics = tester.getSemantics(find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'High priority',
      ));

      expect(semantics, isNotNull);
    });

    testWidgets('has accessibility labels for action buttons', (tester) async {
      await tester.pumpWidget(buildTestWidget(testReminder));

      // Check for semantic labels
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Edit reminder',
        ),
        findsOneWidget,
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Delete reminder',
        ),
        findsOneWidget,
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Convert reminder to task',
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays correct color for high priority', (tester) async {
      final highPriorityReminder =
          testReminder.copyWith(priority: ReminderPriority.high);
      await tester.pumpWidget(buildTestWidget(highPriorityReminder));

      // Find the priority icon
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      
      // Verify the icon has the correct color
      final icon = tester.widget<Icon>(find.byIcon(Icons.arrow_upward));
      expect(icon.color, equals(Colors.red));
    });

    testWidgets('displays correct color for medium priority', (tester) async {
      final mediumPriorityReminder =
          testReminder.copyWith(priority: ReminderPriority.medium);
      await tester.pumpWidget(buildTestWidget(mediumPriorityReminder));

      // Find the priority icon
      expect(find.byIcon(Icons.remove), findsOneWidget);
      
      // Verify the icon has the correct color
      final icon = tester.widget<Icon>(find.byIcon(Icons.remove));
      expect(icon.color, equals(Colors.orange));
    });

    testWidgets('displays correct color for low priority', (tester) async {
      final lowPriorityReminder =
          testReminder.copyWith(priority: ReminderPriority.low);
      await tester.pumpWidget(buildTestWidget(lowPriorityReminder));

      // Find the priority icon
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
      
      // Verify the icon has the correct color
      final icon = tester.widget<Icon>(find.byIcon(Icons.arrow_downward));
      expect(icon.color, equals(Colors.green));
    });

    testWidgets('truncates long content with ellipsis', (tester) async {
      final longContentReminder = testReminder.copyWith(
        content: 'This is a very long reminder content that should be '
            'truncated with an ellipsis when it exceeds the maximum '
            'number of lines allowed in the card display',
      );
      await tester.pumpWidget(buildTestWidget(longContentReminder));

      final textWidget = tester.widget<Text>(
        find.text(longContentReminder.content),
      );

      expect(textWidget.maxLines, equals(3));
      expect(textWidget.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets('displays all fields correctly', (tester) async {
      // Create a reminder with all fields populated
      final completeReminder = Reminder(
        id: 'complete-id',
        content: 'Complete reminder with all fields',
        userId: 'user-999',
        boardId: 'board-888',
        createdAt: DateTime(2024, 2, 15),
        updatedAt: DateTime(2024, 2, 16),
        tags: ['work', 'urgent', 'important'],
        priority: ReminderPriority.high,
      );

      await tester.pumpWidget(buildTestWidget(completeReminder));

      // Verify content is displayed
      expect(find.text('Complete reminder with all fields'), findsOneWidget);

      // Verify priority indicator is displayed with correct icon and color
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      final priorityIcon = tester.widget<Icon>(find.byIcon(Icons.arrow_upward));
      expect(priorityIcon.color, equals(Colors.red));

      // Verify all tags are displayed as chips
      expect(find.text('work'), findsOneWidget);
      expect(find.text('urgent'), findsOneWidget);
      expect(find.text('important'), findsOneWidget);
      expect(find.byType(Chip), findsNWidgets(3));

      // Verify all action buttons are displayed
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);

      // Verify tooltips are present
      expect(find.byTooltip('Edit'), findsOneWidget);
      expect(find.byTooltip('Delete'), findsOneWidget);
      expect(find.byTooltip('Convert to Task'), findsOneWidget);

      // Verify the card itself is present
      expect(find.byType(Card), findsOneWidget);
    });
  });
}
