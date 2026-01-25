import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:synclife_app/src/core/theme/theme_provider.dart';
import 'package:synclife_app/src/core/theme/theme_settings_widget.dart';

void main() {
  group('Theme Provider Tests', () {
    test('ThemeNotifier should start with system theme', () {
      final notifier = ThemeNotifier();
      expect(notifier.state, AppThemeMode.system);
    });

    test('ThemeNotifier should change theme mode', () async {
      final notifier = ThemeNotifier();
      
      await notifier.setThemeMode(AppThemeMode.dark);
      expect(notifier.state, AppThemeMode.dark);
      
      await notifier.setThemeMode(AppThemeMode.light);
      expect(notifier.state, AppThemeMode.light);
    });

    test('ThemeNotifier should convert to Flutter ThemeMode correctly', () {
      final notifier = ThemeNotifier();
      
      notifier.state = AppThemeMode.system;
      expect(notifier.flutterThemeMode, ThemeMode.system);
      
      notifier.state = AppThemeMode.light;
      expect(notifier.flutterThemeMode, ThemeMode.light);
      
      notifier.state = AppThemeMode.dark;
      expect(notifier.flutterThemeMode, ThemeMode.dark);
    });

    testWidgets('ThemeToggleButton should be tappable', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                actions: const [ThemeToggleButton()],
              ),
            ),
          ),
        ),
      );

      // Find the theme toggle button
      final toggleButton = find.byType(ThemeToggleButton);
      expect(toggleButton, findsOneWidget);

      // Tap the button
      await tester.tap(toggleButton);
      await tester.pump();

      // Button should still be there after tap
      expect(toggleButton, findsOneWidget);
    });

    testWidgets('ThemeSettingsWidget should display theme options', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ThemeSettingsWidget(),
            ),
          ),
        ),
      );

      // Verify theme options are displayed
      expect(find.text('Tema do Aplicativo'), findsOneWidget);
      expect(find.text('Automático'), findsOneWidget);
      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Escuro'), findsOneWidget);
    });
  });
}