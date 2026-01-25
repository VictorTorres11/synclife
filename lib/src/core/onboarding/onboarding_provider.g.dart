// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$shouldShowOnboardingHash() =>
    r'f698ec24b09a4f73e11a3617715a7de4f4d26894';

/// Provider for checking if onboarding should be shown
///
/// Copied from [shouldShowOnboarding].
@ProviderFor(shouldShowOnboarding)
final shouldShowOnboardingProvider = AutoDisposeFutureProvider<bool>.internal(
  shouldShowOnboarding,
  name: r'shouldShowOnboardingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$shouldShowOnboardingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ShouldShowOnboardingRef = AutoDisposeFutureProviderRef<bool>;
String _$onboardingStateHash() => r'8651efe11c6ee2be5eebdafabed2c6b5886f905c';

/// Provider for onboarding completion state
///
/// Copied from [OnboardingState].
@ProviderFor(OnboardingState)
final onboardingStateProvider =
    AutoDisposeAsyncNotifierProvider<OnboardingState, bool>.internal(
  OnboardingState.new,
  name: r'onboardingStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$onboardingStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$OnboardingState = AutoDisposeAsyncNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
