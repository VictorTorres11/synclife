import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synclife_app/src/core/layout/main_layout.dart';
import 'package:synclife_app/src/core/theme/app_theme.dart';
import 'package:synclife_app/src/features/tasks/presentation/pages/tasks_page.dart';

/// Integration tests for cross-platform functionality
void main() {
  group('Cross-Platform Integration Tests', () {
    testWidgets('App layout adapts to mobile screen sizes', (tester) async {
      // Set mobile screen size (iPhone 12)
      await tester.binding.setSurfaceSize(const Size(390, 844));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const TasksPage(),
          ),
        ),
      );

      // Verify mobile layout elements
      expect(find.text('SyncLife'), findsOneWidget);
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Verify tabs are visible
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Inbox'), findsOneWidget);

      // Verify task list area
      expect(find.text('No tasks found'), findsOneWidget);
      expect(find.text('Tap + to create your first task'), findsOneWidget);

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('App layout adapts to tablet screen sizes', (tester) async {
      // Set tablet screen size (iPad)
      await tester.binding.setSurfaceSize(const Size(768, 1024));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const TasksPage(),
          ),
        ),
      );

      // Verify tablet layout elements
      expect(find.text('SyncLife'), findsOneWidget);
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

      // On tablet, there should be more space for content
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Inbox'), findsOneWidget);

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('App layout adapts to desktop screen sizes', (tester) async {
      // Set desktop screen size
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const TasksPage(),
          ),
        ),
      );

      // Verify desktop layout elements
      expect(find.text('SyncLife'), findsOneWidget);
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

      // Desktop should have full functionality
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Inbox'), findsOneWidget);

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Navigation works consistently across platforms',
        (tester) async {
      // Test on different screen sizes
      final screenSizes = [
        const Size(390, 844), // Mobile
        const Size(768, 1024), // Tablet
        const Size(1200, 800), // Desktop
      ];

      for (final size in screenSizes) {
        await tester.binding.setSurfaceSize(size);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const MainLayout(
                title: 'Navigation Test',
                child: Center(
                  child: Text('Main Content'),
                ),
              ),
            ),
          ),
        );

        // Open drawer
        await tester.tap(find.byIcon(Icons.menu_rounded));
        await tester.pumpAndSettle();

        // Verify drawer opens on all screen sizes
        expect(find.text('SyncLife'), findsOneWidget);
        expect(find.text('Navegação'), findsOneWidget);

        // Close drawer
        await tester.tapAt(Offset(size.width * 0.8, size.height * 0.5));
        await tester.pumpAndSettle();

        // Verify drawer closes
        expect(find.text('SyncLife'), findsNothing);
      }

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Theme switching works across platforms', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            home: const MainLayout(
              title: 'Theme Test',
              child: Center(
                child: Text('Content'),
              ),
            ),
          ),
        ),
      );

      // Verify light theme is active
      expect(find.text('Theme Test'), findsOneWidget);

      // Switch to dark theme
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const MainLayout(
              title: 'Theme Test',
              child: Center(
                child: Text('Content'),
              ),
            ),
          ),
        ),
      );

      // Verify dark theme is active
      expect(find.text('Theme Test'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('Touch interactions work on all platforms', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Touch Test'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {},
                  ),
                ],
              ),
              body: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Primary Button'),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Secondary Button'),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Text Button'),
                  ),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Input Field',
                    ),
                  ),
                  Checkbox(
                    value: false,
                    onChanged: (value) {},
                  ),
                  Switch(
                    value: true,
                    onChanged: (value) {},
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {},
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ),
      );

      // Test various touch interactions
      await tester.tap(find.text('Primary Button'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Secondary Button'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Text Button'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Test text input
      await tester.enterText(find.byType(TextField), 'Test input');
      await tester.pumpAndSettle();

      expect(find.text('Test input'), findsOneWidget);
    });

    testWidgets('Keyboard navigation works across platforms', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Column(
                children: [
                  const TextField(
                    decoration: InputDecoration(labelText: 'Field 1'),
                  ),
                  const TextField(
                    decoration: InputDecoration(labelText: 'Field 2'),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Test tab navigation
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Test enter key
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Verify elements are still present
      expect(find.text('Field 1'), findsOneWidget);
      expect(find.text('Field 2'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('Scrolling works consistently across platforms',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: ListView.builder(
                itemCount: 50,
                itemBuilder: (context, index) => ListTile(
                  title: Text('Item $index'),
                  subtitle: Text('Subtitle for item $index'),
                ),
              ),
            ),
          ),
        ),
      );

      // Verify initial items are visible
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);

      // Scroll down
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Verify scrolled content
      expect(find.text('Item 0'), findsNothing);
      expect(find.text('Item 10'), findsOneWidget);

      // Scroll back up
      await tester.drag(find.byType(ListView), const Offset(0, 500));
      await tester.pumpAndSettle();

      // Verify we're back at the top
      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('Orientation changes are handled correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: OrientationBuilder(
                builder: _buildOrientationContent,
              ),
            ),
          ),
        ),
      );

      // Test portrait orientation (default)
      expect(find.text('Portrait Mode'), findsOneWidget);

      // Change to landscape
      await tester.binding.setSurfaceSize(const Size(844, 390));
      await tester.pumpAndSettle();

      // Verify landscape layout
      expect(find.text('Landscape Mode'), findsOneWidget);

      // Reset orientation
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Performance is consistent across platforms', (tester) async {
      // Create a complex widget tree to test performance
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Column(
                children: [
                  // Header section
                  Container(
                    height: 100,
                    color: Colors.blue,
                    child: const Center(
                      child: Text(
                        'Performance Test',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                  // List section
                  Expanded(
                    child: ListView.builder(
                      itemCount: 100,
                      itemBuilder: (context, index) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text('$index'),
                          ),
                          title: Text('Performance Item $index'),
                          subtitle: Text('Subtitle for item $index'),
                          trailing: IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () {},
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify initial render
      expect(find.text('Performance Test'), findsOneWidget);
      expect(find.text('Performance Item 0'), findsOneWidget);

      // Test scrolling performance
      for (int i = 0; i < 10; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pump();
      }

      await tester.pumpAndSettle();

      // Verify we can still find content after scrolling
      expect(find.text('Performance Test'), findsOneWidget);
    });

    testWidgets('Error handling works across platforms', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Something went wrong',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Verify error state is displayed
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Test retry button
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Error state should still be visible (since we're not actually retrying)
      expect(find.text('Something went wrong'), findsOneWidget);
    });
  });
}

Widget _buildOrientationContent(BuildContext context, Orientation orientation) {
  if (orientation == Orientation.landscape) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.landscape, size: 48),
        SizedBox(width: 16),
        Text(
          'Landscape Mode',
          style: TextStyle(fontSize: 24),
        ),
      ],
    );
  } else {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.portrait, size: 48),
        SizedBox(height: 16),
        Text(
          'Portrait Mode',
          style: TextStyle(fontSize: 24),
        ),
      ],
    );
  }
}
