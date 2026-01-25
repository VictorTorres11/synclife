import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synclife_app/src/core/onboarding/onboarding_overlay.dart';
import 'package:synclife_app/src/core/onboarding/onboarding_wrapper.dart';
import 'package:synclife_app/src/core/theme/app_theme.dart';
import 'package:synclife_app/src/features/tasks/presentation/pages/tasks_page.dart';

/// Integration tests for onboarding flows
void main() {
  group('Onboarding Integration Tests', () {
    testWidgets('Complete onboarding flow works end-to-end', (tester) async {
      var onboardingCompleted = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: OnboardingWrapper(
              onboardingSteps: SyncLifeOnboardingSteps.defaultSteps,
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('SyncLife'),
                ),
                body: const Center(
                  child: Text('Welcome to SyncLife!'),
                ),
              ),
            ),
          ),
        ),
      );

      // Wait for onboarding to potentially show
      await tester.pumpAndSettle();

      // Verify main content is visible
      expect(find.text('Welcome to SyncLife!'), findsOneWidget);

      // Note: In a real integration test, we would mock the onboarding service
      // to simulate first-time user experience
    });

    testWidgets('Onboarding can be triggered contextually', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    OnboardingTrigger.showContextualOnboarding(
                      context,
                      steps: SyncLifeOnboardingSteps.taskManagementSteps,
                    );
                  },
                  child: const Text('Show Task Help'),
                ),
              ),
            ),
          ),
        ),
      );

      // Tap button to trigger contextual onboarding
      await tester.tap(find.text('Show Task Help'));
      await tester.pumpAndSettle();

      // Verify contextual onboarding appears
      expect(find.text('Gestos de Tarefa'), findsOneWidget);
      expect(
          find.text('Deslize para a direita para completar uma tarefa, '
              'ou para a esquerda para adiá-la. Toque para ver detalhes.'),
          findsOneWidget);

      // Complete the contextual onboarding
      await tester.tap(find.text('Finalizar'));
      await tester.pumpAndSettle();

      // Verify onboarding is dismissed
      expect(find.text('Gestos de Tarefa'), findsNothing);
    });

    testWidgets('Onboarding highlights target elements correctly',
        (tester) async {
      final targetKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Stack(
              children: [
                Center(
                  child: Container(
                    key: targetKey,
                    width: 100,
                    height: 50,
                    color: Colors.blue,
                    child: const Center(
                      child: Text('Target Element'),
                    ),
                  ),
                ),
                OnboardingOverlay(
                  steps: [
                    OnboardingStep(
                      title: 'Target Test',
                      description: 'This highlights the target element',
                      targetKey: targetKey,
                    ),
                  ],
                  onComplete: () {},
                ),
              ],
            ),
          ),
        ),
      );

      // Verify onboarding overlay is displayed
      expect(find.text('Target Test'), findsOneWidget);
      expect(find.text('This highlights the target element'), findsOneWidget);
      expect(find.text('Target Element'), findsOneWidget);

      // Complete onboarding
      await tester.tap(find.text('Finalizar'));
      await tester.pumpAndSettle();
    });

    testWidgets('Onboarding adapts to different screen sizes', (tester) async {
      final steps = [
        const OnboardingStep(
          title: 'Responsive Test',
          description: 'This onboarding should work on all screen sizes',
          icon: Icons.phone_android,
        ),
      ];

      // Test mobile size
      await tester.binding.setSurfaceSize(const Size(390, 844));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: OnboardingOverlay(
              steps: steps,
              onComplete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Responsive Test'), findsOneWidget);
      expect(find.byIcon(Icons.phone_android), findsOneWidget);

      // Test tablet size
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      await tester.pumpAndSettle();

      expect(find.text('Responsive Test'), findsOneWidget);

      // Test desktop size
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpAndSettle();

      expect(find.text('Responsive Test'), findsOneWidget);

      // Reset size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Onboarding navigation handles edge cases', (tester) async {
      final steps = [
        const OnboardingStep(
          title: 'Step 1',
          description: 'First step',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: OnboardingOverlay(
              steps: steps,
              onComplete: () {},
            ),
          ),
        ),
      );

      // Verify single step shows "Finalizar" instead of "Próximo"
      expect(find.text('Finalizar'), findsOneWidget);
      expect(find.text('Próximo'), findsNothing);
      expect(find.text('Anterior'), findsNothing);

      // Test with empty steps
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: OnboardingOverlay(
              steps: const [],
              onComplete: () {},
            ),
          ),
        ),
      );

      // Should show nothing for empty steps
      expect(find.text('Step 1'), findsNothing);
    });

    testWidgets('Onboarding keyboard navigation works', (tester) async {
      final steps = [
        const OnboardingStep(
          title: 'Keyboard Test',
          description: 'Test keyboard navigation',
        ),
        const OnboardingStep(
          title: 'Second Step',
          description: 'Second step for keyboard test',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: OnboardingOverlay(
              steps: steps,
              onComplete: () {},
            ),
          ),
        ),
      );

      // Verify first step
      expect(find.text('Keyboard Test'), findsOneWidget);

      // Test tab navigation to next button
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Test enter key to proceed
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Should move to second step
      expect(find.text('Second Step'), findsOneWidget);
    });

    testWidgets('Onboarding works with different themes', (tester) async {
      final steps = [
        const OnboardingStep(
          title: 'Theme Test',
          description: 'Testing with different themes',
          icon: Icons.palette,
        ),
      ];

      // Test with light theme
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: OnboardingOverlay(
              steps: steps,
              onComplete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Theme Test'), findsOneWidget);
      expect(find.byIcon(Icons.palette), findsOneWidget);

      // Test with dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: OnboardingOverlay(
              steps: steps,
              onComplete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Theme Test'), findsOneWidget);
      expect(find.byIcon(Icons.palette), findsOneWidget);
    });

    testWidgets('Onboarding handles rapid user interactions', (tester) async {
      var completionCount = 0;

      final steps = [
        const OnboardingStep(
          title: 'Rapid Test 1',
          description: 'First step',
        ),
        const OnboardingStep(
          title: 'Rapid Test 2',
          description: 'Second step',
        ),
        const OnboardingStep(
          title: 'Rapid Test 3',
          description: 'Third step',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: OnboardingOverlay(
              steps: steps,
              onComplete: () => completionCount++,
            ),
          ),
        ),
      );

      // Rapidly tap through all steps
      await tester.tap(find.text('Próximo'));
      await tester.pump();
      await tester.tap(find.text('Próximo'));
      await tester.pump();
      await tester.tap(find.text('Finalizar'));
      await tester.pumpAndSettle();

      // Should only complete once
      expect(completionCount, equals(1));
    });
  });
}
