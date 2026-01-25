import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:synclife_app/src/core/theme/app_theme.dart';
import 'package:synclife_app/src/core/theme/theme_provider.dart';
import 'package:synclife_app/src/core/theme/theme_settings_widget.dart';

void main() {
  group('Theme Button Functionality', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Theme toggle button cycles through themes correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              final themeMode = ref.watch(themeModeProvider);
              final currentTheme = ref.watch(themeProvider);
              
              return MaterialApp(
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,
                home: Scaffold(
                  appBar: AppBar(
                    title: Text('Current: ${currentTheme.name}'),
                    actions: const [ThemeToggleButton()],
                  ),
                  body: Center(
                    child: Text('Theme: ${themeMode.name}'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially should be system theme
      expect(find.text('Current: system'), findsOneWidget);
      
      // Find and tap the theme toggle button
      final toggleButton = find.byType(ThemeToggleButton);
      expect(toggleButton, findsOneWidget);

      // First tap: system -> light
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();
      expect(find.text('Current: light'), findsOneWidget);

      // Second tap: light -> dark
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();
      expect(find.text('Current: dark'), findsOneWidget);

      // Third tap: dark -> system
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();
      expect(find.text('Current: system'), findsOneWidget);
    });

    testWidgets('Theme changes persist correctly', (tester) async {
      late WidgetRef testRef;
      
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              testRef = ref;
              final currentTheme = ref.watch(themeProvider);
              
              return MaterialApp(
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                home: Scaffold(
                  body: Center(
                    child: Text('Current: ${currentTheme.name}'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Change to dark theme programmatically
      await testRef.read(themeProvider.notifier).setThemeMode(AppThemeMode.dark);
      await tester.pumpAndSettle();
      expect(find.text('Current: dark'), findsOneWidget);

      // Change to light theme
      await testRef.read(themeProvider.notifier).setThemeMode(AppThemeMode.light);
      await tester.pumpAndSettle();
      expect(find.text('Current: light'), findsOneWidget);

      // Verify persistence by checking SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getInt('theme_mode');
      expect(savedTheme, AppThemeMode.light.index);
    });
  });
}