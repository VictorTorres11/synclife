import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'onboarding_overlay.dart';
import 'onboarding_provider.dart';

/// Wrapper widget that shows onboarding overlay when needed
class OnboardingWrapper extends ConsumerStatefulWidget {
  const OnboardingWrapper({
    super.key,
    required this.child,
    this.onboardingSteps,
  });

  final Widget child;
  final List<OnboardingStep>? onboardingSteps;

  @override
  ConsumerState<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends ConsumerState<OnboardingWrapper> {
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    // Wait a frame to ensure the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final shouldShow = await ref.read(shouldShowOnboardingProvider.future);
      if (mounted && shouldShow) {
        setState(() {
          _showOnboarding = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showOnboarding)
          OnboardingOverlay(
            steps:
                widget.onboardingSteps ?? SyncLifeOnboardingSteps.defaultSteps,
            onComplete: _completeOnboarding,
            onSkip: _completeOnboarding,
          ),
      ],
    );
  }

  void _completeOnboarding() {
    ref.read(onboardingStateProvider.notifier).completeOnboarding();
    setState(() {
      _showOnboarding = false;
    });
  }
}

/// Extension to easily add onboarding to any widget
extension OnboardingExtension on Widget {
  Widget withOnboarding({
    List<OnboardingStep>? steps,
  }) {
    return OnboardingWrapper(
      onboardingSteps: steps,
      child: this,
    );
  }
}

/// Helper class for triggering contextual onboarding
class OnboardingTrigger {
  /// Show contextual onboarding for a specific feature
  static void showContextualOnboarding(
    BuildContext context, {
    required List<OnboardingStep> steps,
    VoidCallback? onComplete,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => OnboardingOverlay(
        steps: steps,
        onComplete: () {
          Navigator.of(context).pop();
          onComplete?.call();
        },
        onSkip: () {
          Navigator.of(context).pop();
          onComplete?.call();
        },
      ),
    );
  }

  /// Show gamification onboarding when user first visits dashboard
  static void showGamificationOnboarding(BuildContext context) {
    showContextualOnboarding(
      context,
      steps: SyncLifeOnboardingSteps.gamificationSteps,
    );
  }

  /// Show board collaboration onboarding when user creates first shared board
  static void showBoardCollaborationOnboarding(BuildContext context) {
    showContextualOnboarding(
      context,
      steps: SyncLifeOnboardingSteps.boardCollaborationSteps,
    );
  }

  /// Show notification onboarding when user first visits notification center
  static void showNotificationOnboarding(BuildContext context) {
    showContextualOnboarding(
      context,
      steps: SyncLifeOnboardingSteps.notificationSteps,
    );
  }

  /// Show store onboarding when user first visits rewards store
  static void showStoreOnboarding(BuildContext context) {
    showContextualOnboarding(
      context,
      steps: SyncLifeOnboardingSteps.storeSteps,
    );
  }

  /// Show task management onboarding when user creates first task
  static void showTaskManagementOnboarding(BuildContext context) {
    showContextualOnboarding(
      context,
      steps: SyncLifeOnboardingSteps.taskManagementSteps,
    );
  }
}
