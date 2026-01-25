import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing advertisement frequency and timing
class AdFrequencyService {
  AdFrequencyService();

  static const String _lastAdShownKey = 'last_ad_shown';
  static const String _adCountTodayKey = 'ad_count_today';
  static const String _lastAdDateKey = 'last_ad_date';
  static const String _sessionAdCountKey = 'session_ad_count';
  static const String _sessionStartKey = 'session_start';

  // Frequency control settings
  static const Duration _minTimeBetweenAds = Duration(minutes: 5);
  static const Duration _sessionDuration = Duration(hours: 1);
  static const int _maxAdsPerDay = 12;
  static const int _maxAdsPerSession = 3;
  static const int _minActionsBeforeAd = 3;

  SharedPreferences? _prefs;
  int _actionsSinceLastAd = 0;
  Timer? _sessionTimer;

  /// Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _resetDailyCountIfNeeded();
    _resetSessionIfNeeded();
  }

  /// Check if an ad can be shown based on frequency rules
  Future<bool> canShowAd({
    required String placementId,
    bool respectUserActions = true,
  }) async {
    if (_prefs == null) await initialize();

    // Check if ads are globally disabled
    if (!await _areAdsEnabled()) return false;

    // Check time-based restrictions
    if (!await _checkTimeRestrictions()) return false;

    // Check daily limit
    if (!await _checkDailyLimit()) return false;

    // Check session limit
    if (!await _checkSessionLimit()) return false;

    // Check user action requirement
    if (respectUserActions && !_checkUserActionRequirement()) return false;

    // Check placement-specific rules
    if (!await _checkPlacementRules(placementId)) return false;

    return true;
  }

  /// Record that an ad was shown
  Future<void> recordAdShown(String placementId) async {
    if (_prefs == null) await initialize();

    final now = DateTime.now();

    // Update global counters
    await _prefs!.setInt(_lastAdShownKey, now.millisecondsSinceEpoch);

    // Update daily count
    final today = _getTodayKey();
    final currentCount = _prefs!.getInt('${_adCountTodayKey}_$today') ?? 0;
    await _prefs!.setInt('${_adCountTodayKey}_$today', currentCount + 1);

    // Update session count
    final sessionCount = _prefs!.getInt(_sessionAdCountKey) ?? 0;
    await _prefs!.setInt(_sessionAdCountKey, sessionCount + 1);

    // Update placement-specific tracking
    await _prefs!
        .setInt('${placementId}_last_shown', now.millisecondsSinceEpoch);

    // Reset action counter
    _actionsSinceLastAd = 0;
  }

  /// Record a user action (task completion, navigation, etc.)
  void recordUserAction() {
    _actionsSinceLastAd++;
  }

  /// Get time until next ad can be shown
  Future<Duration?> getTimeUntilNextAd() async {
    if (_prefs == null) await initialize();

    final lastAdShown = _prefs!.getInt(_lastAdShownKey);
    if (lastAdShown == null) return Duration.zero;

    final lastAdTime = DateTime.fromMillisecondsSinceEpoch(lastAdShown);
    final timeSinceLastAd = DateTime.now().difference(lastAdTime);

    if (timeSinceLastAd >= _minTimeBetweenAds) {
      return Duration.zero;
    }

    return _minTimeBetweenAds - timeSinceLastAd;
  }

  /// Get remaining ads for today
  Future<int> getRemainingAdsToday() async {
    if (_prefs == null) await initialize();

    final today = _getTodayKey();
    final currentCount = _prefs!.getInt('${_adCountTodayKey}_$today') ?? 0;
    return (_maxAdsPerDay - currentCount).clamp(0, _maxAdsPerDay);
  }

  /// Get remaining ads for current session
  Future<int> getRemainingAdsThisSession() async {
    if (_prefs == null) await initialize();

    final sessionCount = _prefs!.getInt(_sessionAdCountKey) ?? 0;
    return (_maxAdsPerSession - sessionCount).clamp(0, _maxAdsPerSession);
  }

  /// Check if user has performed enough actions to warrant an ad
  bool _checkUserActionRequirement() {
    return _actionsSinceLastAd >= _minActionsBeforeAd;
  }

  /// Check time-based restrictions
  Future<bool> _checkTimeRestrictions() async {
    final lastAdShown = _prefs!.getInt(_lastAdShownKey);
    if (lastAdShown == null) return true;

    final lastAdTime = DateTime.fromMillisecondsSinceEpoch(lastAdShown);
    final timeSinceLastAd = DateTime.now().difference(lastAdTime);

    return timeSinceLastAd >= _minTimeBetweenAds;
  }

  /// Check daily ad limit
  Future<bool> _checkDailyLimit() async {
    final today = _getTodayKey();
    final currentCount = _prefs!.getInt('${_adCountTodayKey}_$today') ?? 0;
    return currentCount < _maxAdsPerDay;
  }

  /// Check session ad limit
  Future<bool> _checkSessionLimit() async {
    final sessionCount = _prefs!.getInt(_sessionAdCountKey) ?? 0;
    return sessionCount < _maxAdsPerSession;
  }

  /// Check placement-specific rules
  Future<bool> _checkPlacementRules(String placementId) async {
    // Different placements can have different frequency rules
    final placementSpecificRules = {
      'task_list_banner': Duration(minutes: 10),
      'board_list_banner': Duration(minutes: 15),
      'settings_banner': Duration(minutes: 20),
      'task_complete_interstitial': Duration(minutes: 30),
      'board_create_interstitial': Duration(hours: 1),
    };

    final minInterval =
        placementSpecificRules[placementId] ?? _minTimeBetweenAds;
    final lastShown = _prefs!.getInt('${placementId}_last_shown');

    if (lastShown == null) return true;

    final lastShownTime = DateTime.fromMillisecondsSinceEpoch(lastShown);
    final timeSinceLastShown = DateTime.now().difference(lastShownTime);

    return timeSinceLastShown >= minInterval;
  }

  /// Check if ads are globally enabled
  Future<bool> _areAdsEnabled() async {
    // This would integrate with the subscription service
    // For now, assume ads are enabled for free users
    return true;
  }

  /// Reset daily count if it's a new day
  void _resetDailyCountIfNeeded() {
    final today = _getTodayKey();
    final lastAdDate = _prefs!.getString(_lastAdDateKey);

    if (lastAdDate != today) {
      // New day, reset all daily counters
      final keys =
          _prefs!.getKeys().where((key) => key.startsWith(_adCountTodayKey));
      for (final key in keys) {
        _prefs!.remove(key);
      }
      _prefs!.setString(_lastAdDateKey, today);
    }
  }

  /// Reset session if enough time has passed
  void _resetSessionIfNeeded() {
    final sessionStart = _prefs!.getInt(_sessionStartKey);
    final now = DateTime.now();

    if (sessionStart == null) {
      // First session
      _prefs!.setInt(_sessionStartKey, now.millisecondsSinceEpoch);
      _prefs!.setInt(_sessionAdCountKey, 0);
    } else {
      final sessionStartTime =
          DateTime.fromMillisecondsSinceEpoch(sessionStart);
      final sessionDuration = now.difference(sessionStartTime);

      if (sessionDuration >= _sessionDuration) {
        // New session
        _prefs!.setInt(_sessionStartKey, now.millisecondsSinceEpoch);
        _prefs!.setInt(_sessionAdCountKey, 0);
      }
    }
  }

  /// Get today's key for storage
  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Dispose resources
  void dispose() {
    _sessionTimer?.cancel();
  }
}
