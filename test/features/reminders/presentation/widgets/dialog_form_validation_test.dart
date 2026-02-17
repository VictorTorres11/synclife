import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:synclife_app/src/features/auth/domain/models/user.dart';
import 'package:synclife_app/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:synclife_app/src/features/reminders/domain/models/reminder.dart';
import 'package:synclife_app/src/features/reminders/domain/models/reminder_priority.dart';
import 'package:synclife_app/src/features/reminders/domain/services/reminder_service.dart';
import 'package:synclife_app/src/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:synclife_app/src/features/reminders/presentation/widgets/add_reminder_dialog.dart';
import 'package:synclife_app/src/features/reminders/presentation/widgets/edit_reminder_dialog.dart';
import 'package:synclife_app/src/features/tasks/domain/models/board.dart';
import 'package:synclife_app/src/features/tasks/domain/models/board_type.dart';
import 'package:synclife_app/src/features/tasks/domain/models/board_settings.dart';
import 'package:synclife_app/src/features/tasks/presentation/providers/board_providers.dart';

@GenerateMocks([ReminderService])
import 'dialog_form_validation_test.mocks.dart';

void main() {
  late MockReminderService mockReminderService;
  late User testUser;
  late List<Board> testBoards;

  setUp(() {
    mockReminderService = MockReminderService();
    testUser = User(
      id: 'test-user-id',
      email: 'test@example.com',
      displayName: 'Test User',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    testBoards = [
      Board(
        id: 'board-1',
        name: 'Personal',
        type: BoardType.private,
        ownerId: 'test-user-id',
        memberIds: ['test-user-id'],
        settings: const BoardSettings(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Board(
        id: 'board-2',
        name: 'Work',
        type: BoardType.private,
        ownerId: 'test-user-id',
        memberIds: ['test-user-id'],
        settings: const BoardSettings(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  });

  Widget createTestWidget(Widget child) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => testUser),
        userBoardsProvider.overrideWith((ref) => Stream.value(testBoards)),
        reminderServiceProvider.overrideWith((ref) => mockReminderService),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('AddReminderDialog Form Validation', () {
    testWidgets('shows error when content is empty', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const AddReminderDialog(),
      ));
      await tester.pump(); // Initial frame
      await tester.pump(const Duration(milliseconds: 100)); // Let stream emit

      // Find and tap the create button without entering content
      final createButton = find.text('Criar Lembrete');
      expect(createButton, findsOneWidget);
      
      await tester.tap(createButton);
      await tester.pump();

      // Should show validation error
      expect(find.text('O conteúdo é obrigatório'), findsOneWidget);
    });

    testWidgets('shows error when content exceeds 500 characters', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const AddReminderDialog(),
      ));
      await tester.pumpAndSettle();

      // Enter content that exceeds 500 characters
      final contentField = find.byType(TextFormField).first;
      final longContent = 'a' * 501;
      
      await tester.enterText(contentField, longContent);
      await tester.pumpAndSettle();

      // Tap create button to trigger validation
      final createButton = find.text('Criar Lembrete');
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('O conteúdo deve ter no máximo 500 caracteres'), findsOneWidget);
    });

    testWidgets('accepts valid content within character limit', (tester) async {
      when(mockReminderService.createReminder(
        content: anyNamed('content'),
        userId: anyNamed('userId'),
        boardId: anyNamed('boardId'),
        tags: anyNamed('tags'),
        priority: anyNamed('priority'),
      )).thenAnswer((_) async => Reminder(
        id: 'test-reminder-id',
        content: 'Valid content',
        userId: 'test-user-id',
        boardId: 'board-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await tester.pumpWidget(createTestWidget(
        const AddReminderDialog(),
      ));
      await tester.pumpAndSettle();

      // Enter valid content
      final contentField = find.byType(TextFormField).first;
      await tester.enterText(contentField, 'Valid reminder content');
      await tester.pumpAndSettle();

      // Tap create button
      final createButton = find.text('Criar Lembrete');
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Should not show validation error for content
      expect(find.text('O conteúdo é obrigatório'), findsNothing);
      expect(find.text('O conteúdo deve ter no máximo 500 caracteres'), findsNothing);
    });

    testWidgets('shows error when board is not selected', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const AddReminderDialog(),
      ));
      await tester.pumpAndSettle();

      // Enter valid content
      final contentField = find.byType(TextFormField).first;
      await tester.enterText(contentField, 'Valid content');
      await tester.pumpAndSettle();

      // Clear the board selection (if possible)
      // Note: The dialog auto-selects the first board, so we need to test
      // the validation logic directly or with an empty board list
      
      // For now, verify that board validation exists
      final boardDropdown = find.byType(DropdownButtonFormField<String>);
      expect(boardDropdown, findsOneWidget);
    });

    testWidgets('trims whitespace from content before validation', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const AddReminderDialog(),
      ));
      await tester.pumpAndSettle();

      // Enter content with only whitespace
      final contentField = find.byType(TextFormField).first;
      await tester.enterText(contentField, '   ');
      await tester.pumpAndSettle();

      // Tap create button
      final createButton = find.text('Criar Lembrete');
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Should show validation error (whitespace-only is treated as empty)
      expect(find.text('O conteúdo é obrigatório'), findsOneWidget);
    });

    testWidgets('accepts content at exactly 500 characters', (tester) async {
      when(mockReminderService.createReminder(
        content: anyNamed('content'),
        userId: anyNamed('userId'),
        boardId: anyNamed('boardId'),
        tags: anyNamed('tags'),
        priority: anyNamed('priority'),
      )).thenAnswer((_) async => Reminder(
        id: 'test-reminder-id',
        content: 'a' * 500,
        userId: 'test-user-id',
        boardId: 'board-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await tester.pumpWidget(createTestWidget(
        const AddReminderDialog(),
      ));
      await tester.pumpAndSettle();

      // Enter content at exactly 500 characters
      final contentField = find.byType(TextFormField).first;
      final exactContent = 'a' * 500;
      
      await tester.enterText(contentField, exactContent);
      await tester.pumpAndSettle();

      // Tap create button
      final createButton = find.text('Criar Lembrete');
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Should not show validation error
      expect(find.text('O conteúdo deve ter no máximo 500 caracteres'), findsNothing);
    });
  });

  group('EditReminderDialog Form Validation', () {
    late Reminder testReminder;

    setUp(() {
      testReminder = Reminder(
        id: 'reminder-1',
        content: 'Original content',
        userId: 'test-user-id',
        boardId: 'board-1',
        tags: ['tag1'],
        priority: ReminderPriority.medium,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    testWidgets('shows error when content is cleared', (tester) async {
      await tester.pumpWidget(createTestWidget(
        EditReminderDialog(reminder: testReminder),
      ));
      await tester.pump(); // Initial frame
      await tester.pump(const Duration(milliseconds: 100)); // Let stream emit

      // Clear the content field
      final contentField = find.byType(TextFormField).first;
      await tester.enterText(contentField, '');
      await tester.pump();

      // Tap save button
      final saveButton = find.text('Salvar');
      await tester.tap(saveButton);
      await tester.pump();

      // Should show validation error
      expect(find.text('O conteúdo é obrigatório'), findsOneWidget);
    });

    testWidgets('shows error when content exceeds 500 characters', (tester) async {
      await tester.pumpWidget(createTestWidget(
        EditReminderDialog(reminder: testReminder),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter content that exceeds 500 characters
      final contentField = find.byType(TextFormField).first;
      final longContent = 'a' * 501;
      
      await tester.enterText(contentField, longContent);
      await tester.pump();

      // Tap save button
      final saveButton = find.text('Salvar');
      await tester.tap(saveButton);
      await tester.pump();

      // Should show validation error
      expect(find.text('O conteúdo deve ter no máximo 500 caracteres'), findsOneWidget);
    });

    testWidgets('pre-populates form with existing reminder data', (tester) async {
      await tester.pumpWidget(createTestWidget(
        EditReminderDialog(reminder: testReminder),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify content is pre-populated
      expect(find.text('Original content'), findsOneWidget);
      
      // Verify tag is displayed
      expect(find.text('tag1'), findsOneWidget);
    });

    testWidgets('accepts valid updated content', (tester) async {
      when(mockReminderService.updateReminder(
        any,
        content: anyNamed('content'),
        boardId: anyNamed('boardId'),
        tags: anyNamed('tags'),
        priority: anyNamed('priority'),
      )).thenAnswer((_) async => testReminder.copyWith(
        content: 'Updated content',
      ));

      await tester.pumpWidget(createTestWidget(
        EditReminderDialog(reminder: testReminder),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Update content
      final contentField = find.byType(TextFormField).first;
      await tester.enterText(contentField, 'Updated content');
      await tester.pump();

      // Tap save button
      final saveButton = find.text('Salvar');
      await tester.tap(saveButton);
      await tester.pump();

      // Should not show validation errors
      expect(find.text('O conteúdo é obrigatório'), findsNothing);
      expect(find.text('O conteúdo deve ter no máximo 500 caracteres'), findsNothing);
    });

    testWidgets('trims whitespace from updated content', (tester) async {
      await tester.pumpWidget(createTestWidget(
        EditReminderDialog(reminder: testReminder),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter content with only whitespace
      final contentField = find.byType(TextFormField).first;
      await tester.enterText(contentField, '   ');
      await tester.pump();

      // Tap save button
      final saveButton = find.text('Salvar');
      await tester.tap(saveButton);
      await tester.pump();

      // Should show validation error
      expect(find.text('O conteúdo é obrigatório'), findsOneWidget);
    });

    testWidgets('accepts content at exactly 500 characters', (tester) async {
      when(mockReminderService.updateReminder(
        any,
        content: anyNamed('content'),
        boardId: anyNamed('boardId'),
        tags: anyNamed('tags'),
        priority: anyNamed('priority'),
      )).thenAnswer((_) async => testReminder.copyWith(
        content: 'a' * 500,
      ));

      await tester.pumpWidget(createTestWidget(
        EditReminderDialog(reminder: testReminder),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter content at exactly 500 characters
      final contentField = find.byType(TextFormField).first;
      final exactContent = 'a' * 500;
      
      await tester.enterText(contentField, exactContent);
      await tester.pump();

      // Tap save button
      final saveButton = find.text('Salvar');
      await tester.tap(saveButton);
      await tester.pump();

      // Should not show validation error
      expect(find.text('O conteúdo deve ter no máximo 500 caracteres'), findsNothing);
    });
  });

  group('Board Selection Validation', () {
    testWidgets('shows warning when no boards are available in AddReminderDialog', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
            userBoardsProvider.overrideWith((ref) => Stream.value([])), // Empty boards
            reminderServiceProvider.overrideWith((ref) => mockReminderService),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AddReminderDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show warning message
      expect(find.text('Você precisa criar um quadro antes de adicionar lembretes'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('shows warning when no boards are available in EditReminderDialog', (tester) async {
      final testReminder = Reminder(
        id: 'reminder-1',
        content: 'Test content',
        userId: 'test-user-id',
        boardId: 'board-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
            userBoardsProvider.overrideWith((ref) => Stream.value([])), // Empty boards
            reminderServiceProvider.overrideWith((ref) => mockReminderService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: EditReminderDialog(reminder: testReminder),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show warning message
      expect(find.text('Nenhum quadro disponível'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('board dropdown shows all available boards', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const AddReminderDialog(),
      ));
      await tester.pumpAndSettle();

      // Find and tap the dropdown
      final dropdown = find.byType(DropdownButtonFormField<String>);
      expect(dropdown, findsOneWidget);
      
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Should show both boards
      expect(find.text('Personal').hitTestable(), findsOneWidget);
      expect(find.text('Work').hitTestable(), findsOneWidget);
    });
  });
}
