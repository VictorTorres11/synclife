// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'language_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$supportedLanguagesHash() =>
    r'384308d8e0f1750283e78d96a4e669515fe8ef01';

/// Provider for supported languages
///
/// Copied from [supportedLanguages].
@ProviderFor(supportedLanguages)
final supportedLanguagesProvider =
    AutoDisposeProvider<List<SupportedLanguage>>.internal(
  supportedLanguages,
  name: r'supportedLanguagesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$supportedLanguagesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SupportedLanguagesRef = AutoDisposeProviderRef<List<SupportedLanguage>>;
String _$supportedRegionsHash() => r'8e332f44af41cd5a46220dde8237d16cc7ed6487';

/// Provider for supported regions
///
/// Copied from [supportedRegions].
@ProviderFor(supportedRegions)
final supportedRegionsProvider =
    AutoDisposeProvider<List<SupportedRegion>>.internal(
  supportedRegions,
  name: r'supportedRegionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$supportedRegionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SupportedRegionsRef = AutoDisposeProviderRef<List<SupportedRegion>>;
String _$languagePreferencesNotifierHash() =>
    r'dbbdfe9e8dcabd66ebbab1fe3beea541ca14b5fa';

/// Provider for language preferences
///
/// Copied from [LanguagePreferencesNotifier].
@ProviderFor(LanguagePreferencesNotifier)
final languagePreferencesNotifierProvider = AutoDisposeAsyncNotifierProvider<
    LanguagePreferencesNotifier, LanguagePreferences>.internal(
  LanguagePreferencesNotifier.new,
  name: r'languagePreferencesNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$languagePreferencesNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LanguagePreferencesNotifier
    = AutoDisposeAsyncNotifier<LanguagePreferences>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
