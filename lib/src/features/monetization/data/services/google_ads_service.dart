import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../domain/services/services.dart';

/// Google Mobile Ads implementation of AdsService
class GoogleAdsService implements AdsService {
  GoogleAdsService();

  bool _initialized = false;
  bool _adsEnabled = true;
  final Map<String, BannerAd> _bannerAds = {};
  final Map<String, InterstitialAd> _interstitialAds = {};
  final Map<String, RewardedAd> _rewardedAds = {};

  // Test ad unit IDs - replace with real ones in production
  static const String _testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // Production ad unit IDs (replace with your actual ad unit IDs)
  static String get _bannerAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-YOUR_PUBLISHER_ID/banner_android'
      : 'ca-app-pub-YOUR_PUBLISHER_ID/banner_ios';

  static String get _interstitialAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-YOUR_PUBLISHER_ID/interstitial_android'
      : 'ca-app-pub-YOUR_PUBLISHER_ID/interstitial_ios';

  static String get _rewardedAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-YOUR_PUBLISHER_ID/rewarded_android'
      : 'ca-app-pub-YOUR_PUBLISHER_ID/rewarded_ios';

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await MobileAds.instance.initialize();

      // Set request configuration for better ad targeting
      final requestConfiguration = RequestConfiguration(
        testDeviceIds: ['YOUR_TEST_DEVICE_ID'], // Add your test device ID
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
      );

      MobileAds.instance.updateRequestConfiguration(requestConfiguration);

      _initialized = true;
    } catch (e) {
      throw Exception('Failed to initialize ads: $e');
    }
  }

  @override
  Future<void> loadBannerAd(String placementId) async {
    if (!_adsEnabled || !_initialized) return;

    try {
      // Dispose existing ad if any
      _bannerAds[placementId]?.dispose();

      final bannerAd = BannerAd(
        adUnitId: _getBannerAdUnitId(),
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            print('Banner ad loaded for placement: $placementId');
          },
          onAdFailedToLoad: (ad, error) {
            print(
                'Banner ad failed to load for placement $placementId: $error');
            ad.dispose();
            _bannerAds.remove(placementId);
          },
          onAdOpened: (ad) {
            print('Banner ad opened for placement: $placementId');
          },
          onAdClosed: (ad) {
            print('Banner ad closed for placement: $placementId');
          },
        ),
      );

      await bannerAd.load();
      _bannerAds[placementId] = bannerAd;
    } catch (e) {
      throw Exception('Failed to load banner ad: $e');
    }
  }

  @override
  Future<void> showBannerAd(String placementId) async {
    if (!_adsEnabled) return;

    final ad = _bannerAds[placementId];
    if (ad == null) {
      await loadBannerAd(placementId);
    }
    // Banner ads are shown automatically when loaded
  }

  @override
  Future<void> hideBannerAd(String placementId) async {
    final ad = _bannerAds[placementId];
    if (ad != null) {
      ad.dispose();
      _bannerAds.remove(placementId);
    }
  }

  @override
  Future<void> loadInterstitialAd(String placementId) async {
    if (!_adsEnabled || !_initialized) return;

    try {
      // Dispose existing ad if any
      _interstitialAds[placementId]?.dispose();

      await InterstitialAd.load(
        adUnitId: _getInterstitialAdUnitId(),
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAds[placementId] = ad;
            print('Interstitial ad loaded for placement: $placementId');
          },
          onAdFailedToLoad: (error) {
            print(
                'Interstitial ad failed to load for placement $placementId: $error');
            _interstitialAds.remove(placementId);
          },
        ),
      );
    } catch (e) {
      throw Exception('Failed to load interstitial ad: $e');
    }
  }

  @override
  Future<bool> showInterstitialAd(String placementId) async {
    if (!_adsEnabled) return false;

    final ad = _interstitialAds[placementId];
    if (ad == null) {
      await loadInterstitialAd(placementId);
      return false;
    }

    try {
      bool adShown = false;

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          print('Interstitial ad showed for placement: $placementId');
          adShown = true;
        },
        onAdDismissedFullScreenContent: (ad) {
          print('Interstitial ad dismissed for placement: $placementId');
          ad.dispose();
          _interstitialAds.remove(placementId);
          // Preload next ad
          loadInterstitialAd(placementId);
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print(
              'Interstitial ad failed to show for placement $placementId: $error');
          ad.dispose();
          _interstitialAds.remove(placementId);
        },
      );

      await ad.show();
      return adShown;
    } catch (e) {
      print('Error showing interstitial ad: $e');
      return false;
    }
  }

  @override
  Future<void> loadRewardedAd(String placementId) async {
    if (!_adsEnabled || !_initialized) return;

    try {
      // Dispose existing ad if any
      _rewardedAds[placementId]?.dispose();

      await RewardedAd.load(
        adUnitId: _getRewardedAdUnitId(),
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAds[placementId] = ad;
            print('Rewarded ad loaded for placement: $placementId');
          },
          onAdFailedToLoad: (error) {
            print(
                'Rewarded ad failed to load for placement $placementId: $error');
            _rewardedAds.remove(placementId);
          },
        ),
      );
    } catch (e) {
      throw Exception('Failed to load rewarded ad: $e');
    }
  }

  @override
  Future<bool> showRewardedAd(String placementId) async {
    if (!_adsEnabled) return false;

    final ad = _rewardedAds[placementId];
    if (ad == null) {
      await loadRewardedAd(placementId);
      return false;
    }

    try {
      bool rewardEarned = false;

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          print('Rewarded ad showed for placement: $placementId');
        },
        onAdDismissedFullScreenContent: (ad) {
          print('Rewarded ad dismissed for placement: $placementId');
          ad.dispose();
          _rewardedAds.remove(placementId);
          // Preload next ad
          loadRewardedAd(placementId);
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print(
              'Rewarded ad failed to show for placement $placementId: $error');
          ad.dispose();
          _rewardedAds.remove(placementId);
        },
      );

      await ad.show(onUserEarnedReward: (ad, reward) {
        print('User earned reward: ${reward.amount} ${reward.type}');
        rewardEarned = true;
      });

      return rewardEarned;
    } catch (e) {
      print('Error showing rewarded ad: $e');
      return false;
    }
  }

  @override
  Future<bool> isAdReady(String placementId, AdType type) async {
    switch (type) {
      case AdType.banner:
        return _bannerAds.containsKey(placementId);
      case AdType.interstitial:
        return _interstitialAds.containsKey(placementId);
      case AdType.rewarded:
        return _rewardedAds.containsKey(placementId);
    }
  }

  @override
  Future<void> dispose() async {
    // Dispose all banner ads
    for (final ad in _bannerAds.values) {
      ad.dispose();
    }
    _bannerAds.clear();

    // Dispose all interstitial ads
    for (final ad in _interstitialAds.values) {
      ad.dispose();
    }
    _interstitialAds.clear();

    // Dispose all rewarded ads
    for (final ad in _rewardedAds.values) {
      ad.dispose();
    }
    _rewardedAds.clear();

    _initialized = false;
  }

  @override
  void setAdsEnabled(bool enabled) {
    _adsEnabled = enabled;

    if (!enabled) {
      // Hide all currently shown ads
      for (final placementId in _bannerAds.keys.toList()) {
        hideBannerAd(placementId);
      }
    }
  }

  @override
  bool get adsEnabled => _adsEnabled;

  // Helper methods to get ad unit IDs
  String _getBannerAdUnitId() {
    // Use test ad unit ID in debug mode
    return const bool.fromEnvironment('dart.vm.product')
        ? _bannerAdUnitId
        : _testBannerAdUnitId;
  }

  String _getInterstitialAdUnitId() {
    return const bool.fromEnvironment('dart.vm.product')
        ? _interstitialAdUnitId
        : _testInterstitialAdUnitId;
  }

  String _getRewardedAdUnitId() {
    return const bool.fromEnvironment('dart.vm.product')
        ? _rewardedAdUnitId
        : _testRewardedAdUnitId;
  }
}
