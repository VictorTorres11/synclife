import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/discrete_ad_service.dart';
import '../../data/services/services.dart';
import '../../domain/models/models.dart';
import '../../domain/services/subscription_service.dart';
import '../../domain/services/ads_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Mock ads service for development
class MockAdsService implements AdsService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> loadBannerAd(String placementId) async {}

  @override
  Future<void> showBannerAd(String placementId) async {}

  @override
  Future<void> hideBannerAd(String placementId) async {}

  @override
  Future<void> loadInterstitialAd(String placementId) async {}

  @override
  Future<bool> showInterstitialAd(String placementId) async => false;

  @override
  Future<void> loadRewardedAd(String placementId) async {}

  @override
  Future<bool> showRewardedAd(String placementId) async => false;

  @override
  Future<bool> isAdReady(String placementId, AdType type) async => false;

  @override
  Future<void> dispose() async {}

  @override
  bool get adsEnabled => false;

  @override
  void setAdsEnabled(bool enabled) {}

  bool get isInitialized => true;
}

/// Provider for the subscription service
final subscriptionServiceProvider =
    Provider<SubscriptionService>((ref) => FirebaseSubscriptionService());

/// Provider for subscription service initialization
final subscriptionInitializationProvider = FutureProvider<void>((ref) async {
  // Initialize subscription service if it has an initialize method
  // For now, the service is ready to use without explicit initialization
});

/// Provider for the ads service
final adsServiceProvider = Provider<AdsService>((ref) => MockAdsService());

/// Provider for discrete ad service
final discreteAdServiceProvider = Provider<DiscreteAdService>((ref) {
  // TODO: Implement AdsService when needed
  return DiscreteAdService(MockAdsService());
});

/// Provider for calendar integration service
// final calendarIntegrationServiceProvider =
//     Provider<CalendarIntegrationService>((ref) {
//   return FirebaseCalendarIntegrationService();
// });

/// Provider for advanced backup service
// final advancedBackupServiceProvider = Provider<AdvancedBackupService>((ref) {
//   return FirebaseAdvancedBackupService();
// });

/// Provider for premium theme service
// final premiumThemeServiceProvider = Provider<PremiumThemeService>((ref) {
//   final subscriptionService = ref.watch(subscriptionServiceProvider);
//   return FirebasePremiumThemeService(subscriptionService: subscriptionService);
// });

/// Provider for user subscription (using current user)
final userSubscriptionProvider = StreamProvider.family<Subscription?, String>((ref, userId) {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return subscriptionService.watchUserSubscription(userId);
});

/// Provider for user limitations (using current user)
final userLimitationsProvider = StreamProvider.family<UserLimitations, String>((ref, userId) {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return subscriptionService.watchUserLimitations(userId);
});

/// Provider for current user subscription
final currentUserSubscriptionProvider = StreamProvider<Subscription?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return ref.watch(userSubscriptionProvider(user.id).future).asStream();
});

/// Provider for current user limitations
final currentUserLimitationsProvider = StreamProvider<UserLimitations>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(UserLimitations.forPlan('', SubscriptionPlan.free));
  }
  return ref.watch(userLimitationsProvider(user.id).future).asStream();
});

/// Provider for available subscription products
final availableProductsProvider =
    FutureProvider<List<SubscriptionProduct>>((ref) {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return subscriptionService.getAvailableProducts();
});

/// Provider to check if ads should be shown for a user
final shouldShowAdsProvider = FutureProvider<bool>((ref) {
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return Future.value(true);
  }

  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return subscriptionService.shouldShowAds(user.id);
});

/// Provider to check if user can perform a specific action
final canPerformActionProvider =
    FutureProvider.family<bool, LimitationType>((ref, type) {
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return Future.value(false);
  }

  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return subscriptionService.canPerformAction(user.id, type);
});

/// Provider for user subscription status by user ID
final isPremiumProvider = FutureProvider.family<bool, String>((ref, userId) async {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  final subscription = await subscriptionService.getUserSubscription(userId);
  return subscription?.effectivePlan == SubscriptionPlan.premium;
});

/// Provider for remaining task slots by user ID
final remainingTaskSlotsProvider = FutureProvider.family<int, String>((ref, userId) async {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  final limitations = await subscriptionService.getUserLimitations(userId);
  return limitations.remainingTaskSlots;
});

/// Provider for remaining board slots by user ID
final remainingBoardSlotsProvider = FutureProvider.family<int, String>((ref, userId) async {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  final limitations = await subscriptionService.getUserLimitations(userId);
  return limitations.remainingBoardSlots;
});

/// Provider for subscription status (derived from subscription)
final subscriptionStatusProvider = Provider<SubscriptionStatus?>((ref) {
  final subscriptionAsync = ref.watch(currentUserSubscriptionProvider);
  return subscriptionAsync.when(
    data: (subscription) => subscription?.status,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider for effective subscription plan (derived from subscription)
final effectivePlanProvider = Provider<SubscriptionPlan>((ref) {
  final subscriptionAsync = ref.watch(currentUserSubscriptionProvider);
  return subscriptionAsync.when(
    data: (subscription) =>
        subscription?.effectivePlan ?? SubscriptionPlan.free,
    loading: () => SubscriptionPlan.free,
    error: (_, __) => SubscriptionPlan.free,
  );
});

/// Provider to check if current user is premium
final currentUserIsPremiumProvider = Provider<bool>((ref) {
  final plan = ref.watch(effectivePlanProvider);
  return plan == SubscriptionPlan.premium;
});

/// Provider for current user remaining task slots
final currentUserRemainingTaskSlotsProvider = Provider<int>((ref) {
  final limitationsAsync = ref.watch(currentUserLimitationsProvider);
  return limitationsAsync.when(
    data: (limitations) => limitations.remainingTaskSlots,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for current user remaining board slots
final currentUserRemainingBoardSlotsProvider = Provider<int>((ref) {
  final limitationsAsync = ref.watch(currentUserLimitationsProvider);
  return limitationsAsync.when(
    data: (limitations) => limitations.remainingBoardSlots,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider to check if user can use calendar integration
final canUseCalendarIntegrationProvider = Provider<bool>((ref) {
  final limitationsAsync = ref.watch(currentUserLimitationsProvider);
  return limitationsAsync.when(
    data: (limitations) => limitations.canUseCalendarIntegration,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider to check if user can use advanced backup
final canUseAdvancedBackupProvider = Provider<bool>((ref) {
  final limitationsAsync = ref.watch(currentUserLimitationsProvider);
  return limitationsAsync.when(
    data: (limitations) => limitations.canUseAdvancedBackup,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider to check if user can use premium themes
final canUsePremiumThemesProvider = Provider<bool>((ref) {
  final limitationsAsync = ref.watch(currentUserLimitationsProvider);
  return limitationsAsync.when(
    data: (limitations) => limitations.canUsePremiumThemes,
    loading: () => false,
    error: (_, __) => false,
  );
});
