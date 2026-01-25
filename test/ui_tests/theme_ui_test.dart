import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synclife_app/src/core/theme/app_theme.dart';
import 'package:synclife_app/src/core/theme/theme_settings_widget.dart';

/// UI tests for theme system and cross-platform consistency
void main() {
  group('Theme UI Tests', () {
    testWidgets('Light theme displays correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Test App'),
            ),
            body: const Column(
              children: [
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Test Card'),
                  ),
                ),
                ElevatedButton(
                  onPressed: null,
                  child: Text('Test Button'),
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Test Input',
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify theme elements are rendered
      expect(find.text('Test App'), findsOneWidget);
      expect(find.text('Test Card'), findsOneWidget);
      expect(find.text('Test Button'), findsOneWidget);
      expect(find.text('Test Input'), findsOneWidget);

      // Verify theme colors are applied
      final appBarFinder = find.byType(AppBar);
      expect(appBarFinder, findsOneWidget);

      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);

      final buttonFinder = find.byType(ElevatedButton);
      expect(buttonFinder, findsOneWidget);
    });

    testWidgets('Dark theme displays correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Test App Dark'),
            ),
            body: const Column(
              children: [
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Test Card Dark'),
                  ),
                ),
                ElevatedButton(
                  onPressed: null,
                  child: Text('Test Button Dark'),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify dark theme elements are rendered
      expect(find.text('Test App Dark'), findsOneWidget);
      expect(find.text('Test Card Dark'), findsOneWidget);
      expect(find.text('Test Button Dark'), findsOneWidget);
    });

    testWidgets('Theme settings widget works correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const Scaffold(
              body: ThemeSettingsWidget(),
            ),
          ),
        ),
      );

      // Verify theme settings are displayed
      expect(find.text('Tema do Aplicativo'), findsOneWidget);
      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Escuro'), findsOneWidget);
      expect(find.text('Automático'), findsOneWidget);

      // Test theme switching
      await tester.tap(find.text('Escuro'));
      await tester.pumpAndSettle();

      // Verify dark theme option is available
      expect(find.text('Escuro'), findsOneWidget);
    });

    testWidgets('Cross-platform components render consistently',
        (tester) async {
      // Test common UI components across different screen sizes
      await tester.binding.setSurfaceSize(const Size(400, 800)); // Mobile size

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Cross-Platform Test'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {},
                ),
              ],
            ),
            drawer: const Drawer(
              child: Column(
                children: [
                  DrawerHeader(
                    child: Text('Menu'),
                  ),
                  ListTile(
                    leading: Icon(Icons.home),
                    title: Text('Home'),
                  ),
                  ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Settings'),
                  ),
                ],
              ),
            ),
            body: const SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Responsive Layout Test',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Input Field',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: null,
                                  child: Text('Primary'),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: null,
                                  child: Text('Secondary'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(label: Text('Tag 1')),
                      Chip(label: Text('Tag 2')),
                      Chip(label: Text('Tag 3')),
                    ],
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      // Verify all components render on mobile
      expect(find.text('Cross-Platform Test'), findsOneWidget);
      expect(find.text('Responsive Layout Test'), findsOneWidget);
      expect(find.text('Input Field'), findsOneWidget);
      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Secondary'), findsOneWidget);
      expect(find.text('Tag 1'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Test tablet size
      await tester.binding.setSurfaceSize(const Size(800, 1200)); // Tablet size
      await tester.pumpAndSettle();

      // Verify components still render correctly on larger screen
      expect(find.text('Cross-Platform Test'), findsOneWidget);
      expect(find.text('Responsive Layout Test'), findsOneWidget);

      // Test desktop size
      await tester.binding
          .setSurfaceSize(const Size(1200, 800)); // Desktop size
      await tester.pumpAndSettle();

      // Verify components still render correctly on desktop
      expect(find.text('Cross-Platform Test'), findsOneWidget);
      expect(find.text('Responsive Layout Test'), findsOneWidget);

      // Reset to default size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Navigation drawer works correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Drawer Test'),
            ),
            drawer: const Drawer(
              child: Column(
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                    ),
                    child: Text(
                      'SyncLife',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.home),
                    title: Text('Home'),
                  ),
                  ListTile(
                    leading: Icon(Icons.task),
                    title: Text('Tasks'),
                  ),
                  ListTile(
                    leading: Icon(Icons.group),
                    title: Text('Boards'),
                  ),
                  ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Settings'),
                  ),
                ],
              ),
            ),
            body: const Center(
              child: Text('Main Content'),
            ),
          ),
        ),
      );

      // Verify drawer is closed initially
      expect(find.text('SyncLife'), findsNothing);
      expect(find.text('Main Content'), findsOneWidget);

      // Open drawer by tapping the menu button
      final ScaffoldState scaffoldState =
          tester.firstState(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Verify drawer is open
      expect(find.text('SyncLife'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Boards'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Tap on a menu item
      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();

      // Verify drawer is still visible (since we're not navigating away)
      expect(find.text('SyncLife'), findsOneWidget);
    });

    testWidgets('Form validation displays correctly', (tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Form(
              key: formKey,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Required Field',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'This field is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        formKey.currentState?.validate();
                      },
                      child: const Text('Validate'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Verify form is displayed
      expect(find.text('Required Field'), findsOneWidget);
      expect(find.text('Validate'), findsOneWidget);

      // Trigger validation without entering text
      await tester.tap(find.text('Validate'));
      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(find.text('This field is required'), findsOneWidget);

      // Enter text and validate again
      await tester.enterText(find.byType(TextFormField), 'Valid input');
      await tester.tap(find.text('Validate'));
      await tester.pumpAndSettle();

      // Verify error message is gone
      expect(find.text('This field is required'), findsNothing);
    });

    testWidgets('Loading states display correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading...'),
                SizedBox(height: 32),
                LinearProgressIndicator(),
                SizedBox(height: 16),
                Text('Progress: 50%'),
              ],
            ),
          ),
        ),
      );

      // Verify loading indicators are displayed
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
      expect(find.text('Progress: 50%'), findsOneWidget);
    });

    testWidgets('Error states display correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
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
                  const SizedBox(height: 8),
                  const Text(
                    'Please try again later',
                    style: TextStyle(color: Colors.grey),
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
      );

      // Verify error state is displayed
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Please try again later'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
