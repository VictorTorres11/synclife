import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'onboarding_service.dart';

part 'onboarding_provider.g.dart';

/// Provider for checking if onboarding should be shown
@riverpod
Future<bool> shouldShowOnboarding(Ref ref) async {
  final isCompleted = await OnboardingService.isOnboardingCompleted();

  // Only show onboarding if it hasn't been completed yet
  return !isCompleted;
}

/// Provider for onboarding completion state
@riverpod
class OnboardingState extends _$OnboardingState {
  @override
  Future<bool> build() async {
    return await OnboardingService.isOnboardingCompleted();
  }

  /// Complete onboarding
  Future<void> completeOnboarding() async {
    await OnboardingService.completeOnboarding();
    state = const AsyncValue.data(true);
  }

  /// Reset onboarding (for testing)
  Future<void> resetOnboarding() async {
    await OnboardingService.resetOnboarding();
    state = const AsyncValue.data(false);
  }
}
