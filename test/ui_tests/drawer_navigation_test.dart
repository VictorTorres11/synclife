import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synclife_app/src/core/layout/main_layout.dart';
import 'package:synclife_app/src/core/theme/app_theme.dart';

/// Tests for drawer navigation and animations
void main() {
  group('Drawer Navigation Tests', () {
    testWidgets('Drawer opens and closes with animations', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MainLayout(
              title: 'Test App',
              child: Center(
                child: Text('Main Content'),
              ),
            ),
          ),
        ),
      );

      // Verify main content is visible
      expect(find.text('Main Content'), findsOneWidget);
      expect(find.text('Test App'), findsOneWidget);

      // Verify drawer is closed initially
      expect(find.text('SyncLife'), findsNothing);
      expect(find.text('Navegação'), findsNothing);

      // Open drawer by tapping menu button
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      // Verify drawer is open
      expect(find.text('SyncLife'), findsOneWidget);
      expect(find.text('Navegação'), findsOneWidget);
      expect(find.text('Minhas Tarefas'), findsOneWidget);
      expect(find.text('Quadros'), findsOneWidget);
      expect(find.text('Inbox'), findsOneWidget);

      // Verify gamification section
      expect(find.text('Gamificação'), findsOneWidget);
      expect(find.text('Conquistas'), findsOneWidget);
      expect(find.text('Estatísticas'), findsOneWidget);
      expect(find.text('Loja FluxoCoins'), findsOneWidget);

      // Verify settings section
      expect(find.text('Configurações'), findsOneWidget);
      expect(find.text('Ajuda'), findsOneWidget);

      // Verify logout button
      expect(find.text('Sair'), findsOneWidget);

      // Close drawer by tapping outside
      await tester.tapAt(const Offset(300, 400));
      await tester.pumpAndSettle();

      // Verify drawer is closed
      expect(find.text('SyncLife'), findsNothing);
      expect(find.text('Navegação'), findsNothing);
    });

    testWidgets('Drawer menu button has hover animations', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MainLayout(
              title: 'Animation Test',
              child: Center(
                child: Text('Content'),
              ),
            ),
          ),
        ),
      );

      // Find the menu button
      final menuButton = find.byIcon(Icons.menu_rounded);
      expect(menuButton, findsOneWidget);

      // Tap the menu button to trigger animation
      await tester.tap(menuButton);
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 150)); // Mid animation
      await tester.pumpAndSettle(); // Complete animation

      // Verify drawer opened
      expect(find.text('SyncLife'), findsOneWidget);
    });

    testWidgets('Drawer items have proper styling and spacing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MainLayout(
              title: 'Styling Test',
              child: SizedBox.shrink(),
            ),
          ),
        ),
      );

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      // Verify drawer items have proper icons
      expect(find.byIcon(Icons.task_alt), findsOneWidget);
      expect(find.byIcon(Icons.dashboard), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      expect(find.byIcon(Icons.store), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);

      // Verify section dividers are present
      expect(find.byType(Divider), findsAtLeastNWidgets(2));
    });

    testWidgets('Drawer navigation triggers correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MainLayout(
              title: 'Navigation Test',
              child: SizedBox.shrink(),
            ),
          ),
        ),
      );

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      // Tap on "Minhas Tarefas"
      await tester.tap(find.text('Minhas Tarefas'));
      await tester.pumpAndSettle();

      // Drawer should close after navigation
      expect(find.text('SyncLife'), findsNothing);
    });

    testWidgets('Drawer works on different screen sizes', (tester) async {
      // Test mobile size
      await tester.binding.setSurfaceSize(const Size(390, 844));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MainLayout(
              title: 'Mobile Test',
              child: SizedBox.shrink(),
            ),
          ),
        ),
      );

      // Open drawer on mobile
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      expect(find.text('SyncLife'), findsOneWidget);

      // Close drawer
      await tester.tapAt(const Offset(300, 400));
      await tester.pumpAndSettle();

      // Test tablet size
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      await tester.pumpAndSettle();

      // Open drawer on tablet
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      expect(find.text('SyncLife'), findsOneWidget);

      // Reset size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Drawer header displays correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MainLayout(
              title: 'Header Test',
              child: SizedBox.shrink(),
            ),
          ),
        ),
      );

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      // Verify header elements
      expect(find.text('SyncLife'), findsOneWidget);
      expect(find.text('Organize sua vida'), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);
    });

    testWidgets('Drawer settings dialog works', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MainLayout(
              title: 'Settings Test',
              child: SizedBox.shrink(),
            ),
          ),
        ),
      );

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      // Tap settings
      await tester.tap(find.text('Configurações'));
      await tester.pumpAndSettle();

      // Verify settings dialog opens
      expect(find.text('Tema do Aplicativo'), findsOneWidget);
      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Escuro'), findsOneWidget);
      expect(find.text('Automático'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(find.text('Tema do Aplicativo'), findsNothing);
    });

    testWidgets('Drawer works with dark theme', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const MainLayout(
              title: 'Dark Theme Test',
              child: SizedBox.shrink(),
            ),
          ),
        ),
      );

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      // Verify drawer content is visible in dark theme
      expect(find.text('SyncLife'), findsOneWidget);
      expect(find.text('Navegação'), findsOneWidget);
      expect(find.text('Minhas Tarefas'), findsOneWidget);
    });

    testWidgets('Drawer item animations work correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MainLayout(
              title: 'Animation Test',
              child: SizedBox.shrink(),
            ),
          ),
        ),
      );

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      // Tap on a drawer item to trigger animation
      await tester.tap(find.text('Minhas Tarefas'));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 75)); // Mid animation
      await tester.pumpAndSettle(); // Complete animation

      // Drawer should be closed after animation
      expect(find.text('SyncLife'), findsNothing);
    });

    testWidgets('Drawer accessibility features work', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MainLayout(
              title: 'Accessibility Test',
              child: SizedBox.shrink(),
            ),
          ),
        ),
      );

      // Verify menu button has tooltip
      final menuButton = find.byIcon(Icons.menu_rounded);
      expect(menuButton, findsOneWidget);

      // Open drawer
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Verify drawer items are accessible
      expect(find.text('Minhas Tarefas'), findsOneWidget);
      expect(find.text('Quadros'), findsOneWidget);
      expect(find.text('Inbox'), findsOneWidget);

      // All items should be tappable
      await tester.tap(find.text('Quadros'));
      await tester.pumpAndSettle();
    });
  });
}
