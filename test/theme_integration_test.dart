import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:synclife_app/src/core/theme/app_theme.dart';
import 'package:synclife_app/src/core/theme/theme_provider.dart';
import 'package:synclife_app/src/core/theme/theme_settings_widget.dart';

void main() {
  group('Theme Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Complete theme switching flow works', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              final themeMode = ref.watch(themeModeProvider);
              return MaterialApp(
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,
                home: Scaffold(
                  appBar: AppBar(
                    title: const Text('Theme Test'),
                    actions: const [ThemeToggleButton()],
                  ),
                  body: const ThemeSettingsWidget(),
                ),
              );
            },
          ),
        ),
      );

      // Wait for initial render
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('Theme Test'), findsOneWidget);
      expect(find.byType(ThemeToggleButton), findsOneWidget);

      // Find and tap the theme toggle button
      final toggleButton = find.byType(ThemeToggleButton);
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      // The button should still be there and functional
      expect(toggleButton, findsOneWidget);

      // Test radio button selection in theme settings
      final lightThemeRadio = find.byWidgetPredicate(
        (widget) => widget is RadioListTile<AppThemeMode> && 
                   widget.value == AppThemeMode.light,
      );
      
      if (lightThemeRadio.evaluate().isNotEmpty) {
        await tester.tap(lightThemeRadio);
        await tester.pumpAndSettle();
      }

      // Verify the app is still functional
      expect(find.text('Tema do Aplicativo'), findsOneWidget);
    });

    testWidgets('Theme changes are reflected in UI', (tester) async {
      late WidgetRef testRef;
      
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              testRef = ref;
              final themeMode = ref.watch(themeModeProvider);
              return MaterialApp(
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,
                home: Scaffold(
                  body: Builder(
                    builder: (context) {
                      final brightness = Theme.of(context).brightness;
                      return Center(
                        child: Text(
                          brightness == Brightness.dark ? 'Dark Theme' : 'Light Theme',
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially should show system theme (likely light in test environment)
      expect(find.text('Light Theme'), findsOneWidget);

      // Programmatically change to dark theme
      await testRef.read(themeProvider.notifier).setThemeMode(AppThemeMode.dark);
      await tester.pumpAndSettle();

      // Should now show dark theme
      expect(find.text('Dark Theme'), findsOneWidget);

      // Change back to light theme
      await testRef.read(themeProvider.notifier).setThemeMode(AppThemeMode.light);
      await tester.pumpAndSettle();

      // Should show light theme again
      expect(find.text('Light Theme'), findsOneWidget);
    });
  });
}