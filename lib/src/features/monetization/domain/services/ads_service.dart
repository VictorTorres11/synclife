/// Service interface for managing advertisements
abstract class AdsService {
  /// Initializes the ads service
  Future<void> initialize();

  /// Loads a banner ad for the specified placement
  Future<void> loadBannerAd(String placementId);

  /// Shows a banner ad
  Future<void> showBannerAd(String placementId);

  /// Hides a banner ad
  Future<void> hideBannerAd(String placementId);

  /// Loads an interstitial ad
  Future<void> loadInterstitialAd(String placementId);

  /// Shows an interstitial ad
  Future<bool> showInterstitialAd(String placementId);

  /// Loads a rewarded ad
  Future<void> loadRewardedAd(String placementId);

  /// Shows a rewarded ad and returns if reward was earned
  Future<bool> showRewardedAd(String placementId);

  /// Checks if an ad is ready to show
  Future<bool> isAdReady(String placementId, AdType type);

  /// Disposes of all ads
  Future<void> dispose();

  /// Sets whether ads should be shown (based on subscription status)
  void setAdsEnabled(bool enabled);

  /// Gets the current ads enabled status
  bool get adsEnabled;
}

/// Types of ads
enum AdType {
  banner,
  interstitial,
  rewarded,
}

/// Ad placement identifiers
class AdPlacements {
  static const String taskListBanner = 'task_list_banner';
  static const String boardListBanner = 'board_list_banner';
  static const String settingsBanner = 'settings_banner';
  static const String taskCompleteInterstitial = 'task_complete_interstitial';
  static const String boardCreateInterstitial = 'board_create_interstitial';
  static const String extraCoinsRewarded = 'extra_coins_rewarded';
  static const String streakBoostRewarded = 'streak_boost_rewarded';
}
