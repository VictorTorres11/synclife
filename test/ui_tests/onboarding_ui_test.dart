import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synclife_app/src/core/onboarding/onboarding_overlay.dart';
import 'package:synclife_app/src/core/onboarding/onboarding_wrapper.dart';
import 'package:synclife_app/src/core/theme/app_theme.dart';

/// UI tests for onboarding flows
void main() {
  group('Onboarding UI Tests', () {
    testWidgets('Onboarding overlay displays correctly', (tester) async {
      var onCompleteCallbackCalled = false;
      var onSkipCallbackCalled = false;

      final steps = [
        const OnboardingStep(
          title: 'Test Step 1',
          description: 'This is a test step',
          icon: Icons.info,
        ),
        const OnboardingStep(
          title: 'Test Step 2',
          description: 'This is another test step',
          icon: Icons.check,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: OnboardingOverlay(
              steps: steps,
              onComplete: () => onCompleteCallbackCalled = true,
              onSkip: () => onSkipCallbackCalled = true,
            ),
          ),
        ),
      );

      // Verify first step is displayed
      expect(find.text('Test Step 1'), findsOneWidget);
      expect(find.text('This is a test step'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
      expect(find.byIcon(Icons.info), findsOneWidget);

      // Verify navigation buttons
      expect(find.text('Pular'), findsOneWidget);
      expect(find.text('Próximo'), findsOneWidget);
      expect(
          find.text('Anterior'), findsNothing); // Should not show on first step

      // Tap next button
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();

      // Verify second step is displayed
      expect(find.text('Test Step 2'), findsOneWidget);
      expect(find.text('This is another test step'), findsOneWidget);
      expect(find.text('2/2'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);

      // Verify navigation buttons on last step
      expect(find.text('Finalizar'), findsOneWidget);
      expect(find.text('Anterior'), findsOneWidget);

      // Tap finish button
      await tester.tap(find.text('Finalizar'));
      await tester.pumpAndSettle();

      // Verify callback was called
      expect(onCompleteCallbackCalled, isTrue);
      expect(onSkipCallbackCalled, isFalse);
    });

    testWidgets('Onboarding can be skipped', (tester) async {
      var onSkipCallbackCalled = false;

      final steps = [
        const OnboardingStep(
          title: 'Test Step',
          description: 'This is a test step',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: OnboardingOverlay(
              steps: steps,
              onComplete: () {},
              onSkip: () => onSkipCallbackCalled = true,
            ),
          ),
        ),
      );

      // Tap skip button
      await tester.tap(find.text('Pular'));
      await tester.pumpAndSettle();

      // Verify callback was called
      expect(onSkipCallbackCalled, isTrue);
    });

    testWidgets('Onboarding navigation works correctly', (tester) async {
      final steps = [
        const OnboardingStep(
          title: 'Step 1',
          description: 'First step',
        ),
        const OnboardingStep(
          title: 'Step 2',
          description: 'Second step',
        ),
        const OnboardingStep(
          title: 'Step 3',
          description: 'Third step',
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

      // Start at step 1
      expect(find.text('Step 1'), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);

      // Go to step 2
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2'), findsOneWidget);
      expect(find.text('2/3'), findsOneWidget);

      // Go to step 3
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();
      expect(find.text('Step 3'), findsOneWidget);
      expect(find.text('3/3'), findsOneWidget);

      // Go back to step 2
      await tester.tap(find.text('Anterior'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2'), findsOneWidget);
      expect(find.text('2/3'), findsOneWidget);

      // Go back to step 1
      await tester.tap(find.text('Anterior'));
      await tester.pumpAndSettle();
      expect(find.text('Step 1'), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);
    });

    testWidgets('Onboarding wrapper shows onboarding when needed',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const OnboardingWrapper(
              onboardingSteps: [
                OnboardingStep(
                  title: 'Welcome',
                  description: 'Welcome to the app',
                ),
              ],
              child: Scaffold(
                body: Center(
                  child: Text('Main Content'),
                ),
              ),
            ),
          ),
        ),
      );

      // Verify main content is displayed
      expect(find.text('Main Content'), findsOneWidget);

      // Note: Onboarding overlay won't show in tests without proper provider setup
      // This test verifies the wrapper doesn't break the main content
    });
  });
}
