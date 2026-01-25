import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/services/ads_service.dart';

/// Service for managing discrete advertisement display with frequency control
class DiscreteAdService {
  DiscreteAdService(this._adsService);

  final AdsService _adsService;

  // Frequency control settings
  static const int _minIntervalMinutes = 5; // Minimum 5 minutes between ads
  static const int _maxAdsPerHour = 6; // Maximum 6 ads per hour
  static const int _maxAdsPerDay = 30; // Maximum 30 ads per day

  // Timing settings for interstitial ads
  static const Map<String, int> _interstitialTimings = {
    AdPlacements.taskCompleteInterstitial: 10, // Every 10th task completion
    AdPlacements.boardCreateInterstitial: 3, // Every 3rd board creation
  };

  /// Checks if an ad can be shown based on frequency limits
  Future<bool> canShowAd(String placementId) async {
    if (!_adsService.adsEnabled) return false;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // Check minimum interval
    final lastAdKey = 'last_ad_$placementId';
    final lastAdTime = prefs.getInt(lastAdKey);
    if (lastAdTime != null) {
      final lastAd = DateTime.fromMillisecondsSinceEpoch(lastAdTime);
      final timeSinceLastAd = now.difference(lastAd);
      if (timeSinceLastAd.inMinutes < _minIntervalMinutes) {
        return false;
      }
    }

    // Check hourly limit
    final hourlyCount = await _getAdCountInTimeframe(Duration(hours: 1));
    if (hourlyCount >= _maxAdsPerHour) {
      return false;
    }

    // Check daily limit
    final dailyCount = await _getAdCountInTimeframe(Duration(days: 1));
    if (dailyCount >= _maxAdsPerDay) {
      return false;
    }

    return true;
  }

  /// Shows a banner ad if frequency allows
  Future<bool> showBannerAdIfAllowed(String placementId) async {
    if (!await canShowAd(placementId)) {
      return false;
    }

    try {
      await _adsService.loadBannerAd(placementId);
      await _adsService.showBannerAd(placementId);
      await _recordAdShown(placementId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Shows an interstitial ad with timing control
  Future<bool> showInterstitialAdWithTiming(String placementId) async {
    // Check if we should show ad based on current count BEFORE incrementing
    final timing = _interstitialTimings[placementId];
    bool shouldShowBasedOnTiming = false;

    if (timing == null) {
      // No specific timing rule, check frequency only
      shouldShowBasedOnTiming = true;
    } else {
      // Check if next count would be divisible by timing interval
      final prefs = await SharedPreferences.getInstance();
      final countKey = 'action_count_$placementId';
      final currentCount = prefs.getInt(countKey) ?? 0;
      final nextCount = currentCount + 1;

      shouldShowBasedOnTiming = (nextCount % timing == 0);
    }

    // Always increment counter for this action
    await _incrementInterstitialCounter(placementId);

    // Only proceed if timing allows and frequency allows
    if (!shouldShowBasedOnTiming || !await canShowAd(placementId)) {
      return false;
    }

    try {
      final success = await _adsService.showInterstitialAd(placementId);
      if (success) {
        await _recordAdShown(placementId);
        await _recordInterstitialTiming(placementId);
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Shows a rewarded ad
  Future<bool> showRewardedAd(String placementId) async {
    // Rewarded ads are user-initiated, so we're more lenient with frequency
    if (!_adsService.adsEnabled) return false;

    try {
      final success = await _adsService.showRewardedAd(placementId);
      if (success) {
        await _recordAdShown(placementId);
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Gets the count of ads shown in a specific timeframe
  Future<int> _getAdCountInTimeframe(Duration timeframe) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final cutoff = now.subtract(timeframe);

    final adTimestamps = prefs.getStringList('ad_timestamps') ?? [];

    int count = 0;
    for (final timestampStr in adTimestamps) {
      try {
        final timestamp = int.parse(timestampStr);
        final adTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        if (adTime.isAfter(cutoff)) {
          count++;
        }
      } catch (e) {
        // Skip invalid timestamps
        continue;
      }
    }

    return count;
  }

  /// Records that an ad was shown
  Future<void> _recordAdShown(String placementId) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // Record last ad time for this placement
    await prefs.setInt('last_ad_$placementId', now.millisecondsSinceEpoch);

    // Add to general ad timestamps list
    final adTimestamps = prefs.getStringList('ad_timestamps') ?? [];
    adTimestamps.add(now.millisecondsSinceEpoch.toString());

    // Keep only recent timestamps (last 24 hours)
    final cutoff = now.subtract(Duration(days: 1));
    final recentTimestamps = adTimestamps
        .map((timestamp) => int.parse(timestamp))
        .where((timestamp) =>
            DateTime.fromMillisecondsSinceEpoch(timestamp).isAfter(cutoff))
        .map((timestamp) => timestamp.toString())
        .toList();

    await prefs.setStringList('ad_timestamps', recentTimestamps);
  }

  /// Checks if an interstitial ad should be shown based on timing rules
  Future<bool> _shouldShowInterstitialBasedOnTiming(String placementId) async {
    final timing = _interstitialTimings[placementId];
    if (timing == null) return true; // No specific timing rule

    final prefs = await SharedPreferences.getInstance();
    final countKey = 'action_count_$placementId';
    final currentCount = prefs.getInt(countKey) ?? 0;

    // Check if we should show ad (every Nth action)
    return (currentCount + 1) % timing == 0;
  }

  /// Increments the action counter for interstitial timing
  Future<void> _incrementInterstitialCounter(String placementId) async {
    final prefs = await SharedPreferences.getInstance();
    final countKey = 'action_count_$placementId';
    final currentCount = prefs.getInt(countKey) ?? 0;
    await prefs.setInt(countKey, currentCount + 1);
  }

  /// Records interstitial timing (resets counter)
  Future<void> _recordInterstitialTiming(String placementId) async {
    final prefs = await SharedPreferences.getInstance();
    final countKey = 'action_count_$placementId';
    await prefs.setInt(countKey, 0); // Reset counter after showing ad
  }

  /// Gets ad statistics for debugging/analytics
  Future<Map<String, dynamic>> getAdStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    final hourlyCount = await _getAdCountInTimeframe(Duration(hours: 1));
    final dailyCount = await _getAdCountInTimeframe(Duration(days: 1));

    final adTimestamps = prefs.getStringList('ad_timestamps') ?? [];
    final lastAdTime = adTimestamps.isNotEmpty
        ? DateTime.fromMillisecondsSinceEpoch(int.parse(adTimestamps.last))
        : null;

    return {
      'adsEnabled': _adsService.adsEnabled,
      'hourlyCount': hourlyCount,
      'dailyCount': dailyCount,
      'maxAdsPerHour': _maxAdsPerHour,
      'maxAdsPerDay': _maxAdsPerDay,
      'lastAdTime': lastAdTime?.toIso8601String(),
      'canShowAd': await canShowAd('general'),
    };
  }

  /// Clears all ad frequency data (useful for testing)
  Future<void> clearAdData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((key) =>
            key.startsWith('last_ad_') ||
            key.startsWith('action_count_') ||
            key == 'ad_timestamps')
        .toList();

    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  /// Simulates user behavior for testing ad frequency
  Future<void> simulateAdInteraction(
    String placementId, {
    int interactions = 1,
    Duration? timeBetween,
  }) async {
    timeBetween ??= Duration(minutes: _minIntervalMinutes + 1);

    for (int i = 0; i < interactions; i++) {
      if (i > 0) {
        // Simulate time passing
        final prefs = await SharedPreferences.getInstance();
        final now = DateTime.now().subtract(timeBetween * (interactions - i));
        await prefs.setInt('last_ad_$placementId', now.millisecondsSinceEpoch);
      }

      await showBannerAdIfAllowed(placementId);
    }
  }
}
