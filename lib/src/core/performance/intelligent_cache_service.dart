import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Intelligent caching service with TTL and LRU eviction
class IntelligentCacheService {
  static IntelligentCacheService? _instance;
  static IntelligentCacheService get instance =>
      _instance ??= IntelligentCacheService._();

  IntelligentCacheService._();

  SharedPreferences? _prefs;
  final Map<String, CacheEntry> _memoryCache = {};
  final Map<String, DateTime> _accessTimes = {};

  /// Maximum number of items in memory cache
  static const int _maxMemoryCacheSize = 100;

  /// Default TTL in minutes
  static const int _defaultTtlMinutes = 30;

  /// Initialize the cache service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _cleanExpiredEntries();
  }

  /// Store data in cache with TTL
  Future<void> set<T>(
    String key,
    T data, {
    int ttlMinutes = _defaultTtlMinutes,
    bool persistToDisk = false,
  }) async {
    final entry = CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      ttlMinutes: ttlMinutes,
    );

    // Store in memory cache
    _memoryCache[key] = entry;
    _accessTimes[key] = DateTime.now();

    // Evict old entries if cache is full
    await _evictIfNeeded();

    // Optionally persist to disk
    if (persistToDisk && _prefs != null) {
      try {
        final serialized = jsonEncode({
          'data': data,
          'timestamp': entry.timestamp.millisecondsSinceEpoch,
          'ttlMinutes': ttlMinutes,
        });
        await _prefs!.setString('cache_$key', serialized);
      } catch (e) {
        debugPrint('Failed to persist cache entry to disk: $e');
      }
    }
  }

  /// Get data from cache
  Future<T?> get<T>(String key) async {
    // Check memory cache first
    final memoryEntry = _memoryCache[key];
    if (memoryEntry != null && !_isExpired(memoryEntry)) {
      _accessTimes[key] = DateTime.now(); // Update access time
      return memoryEntry.data as T?;
    }

    // Check disk cache
    if (_prefs != null) {
      try {
        final serialized = _prefs!.getString('cache_$key');
        if (serialized != null) {
          final data = jsonDecode(serialized);
          final entry = CacheEntry(
            data: data['data'],
            timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp']),
            ttlMinutes: data['ttlMinutes'],
          );

          if (!_isExpired(entry)) {
            // Move to memory cache
            _memoryCache[key] = entry;
            _accessTimes[key] = DateTime.now();
            return entry.data as T?;
          } else {
            // Remove expired entry from disk
            await _prefs!.remove('cache_$key');
          }
        }
      } catch (e) {
        debugPrint('Failed to read cache entry from disk: $e');
      }
    }

    return null;
  }

  /// Check if key exists in cache and is not expired
  Future<bool> has(String key) async {
    final data = await get(key);
    return data != null;
  }

  /// Remove specific key from cache
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    _accessTimes.remove(key);

    if (_prefs != null) {
      await _prefs!.remove('cache_$key');
    }
  }

  /// Clear all cache
  Future<void> clear() async {
    _memoryCache.clear();
    _accessTimes.clear();

    if (_prefs != null) {
      final keys = _prefs!.getKeys().where((key) => key.startsWith('cache_'));
      for (final key in keys) {
        await _prefs!.remove(key);
      }
    }
  }

  /// Get cache statistics
  CacheStats getStats() {
    final totalEntries = _memoryCache.length;
    final expiredEntries = _memoryCache.values.where(_isExpired).length;

    return CacheStats(
      totalEntries: totalEntries,
      expiredEntries: expiredEntries,
      memoryUsage: _memoryCache.length,
      maxMemorySize: _maxMemoryCacheSize,
    );
  }

  /// Clean expired entries
  Future<void> _cleanExpiredEntries() async {
    // Clean memory cache
    final expiredKeys = <String>[];
    for (final entry in _memoryCache.entries) {
      if (_isExpired(entry.value)) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _memoryCache.remove(key);
      _accessTimes.remove(key);
    }

    // Clean disk cache
    if (_prefs != null) {
      final cacheKeys =
          _prefs!.getKeys().where((key) => key.startsWith('cache_'));
      for (final key in cacheKeys) {
        try {
          final serialized = _prefs!.getString(key);
          if (serialized != null) {
            final data = jsonDecode(serialized);
            final entry = CacheEntry(
              data: data['data'],
              timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp']),
              ttlMinutes: data['ttlMinutes'],
            );

            if (_isExpired(entry)) {
              await _prefs!.remove(key);
            }
          }
        } catch (e) {
          // Remove corrupted entries
          await _prefs!.remove(key);
        }
      }
    }
  }

  /// Evict least recently used entries if cache is full
  Future<void> _evictIfNeeded() async {
    if (_memoryCache.length <= _maxMemoryCacheSize) return;

    // Sort by access time (oldest first)
    final sortedEntries = _accessTimes.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Remove oldest entries
    final entriesToRemove = _memoryCache.length - _maxMemoryCacheSize;
    for (int i = 0; i < entriesToRemove; i++) {
      final key = sortedEntries[i].key;
      _memoryCache.remove(key);
      _accessTimes.remove(key);
    }
  }

  /// Check if cache entry is expired
  bool _isExpired(CacheEntry entry) {
    final now = DateTime.now();
    final expiryTime = entry.timestamp.add(Duration(minutes: entry.ttlMinutes));
    return now.isAfter(expiryTime);
  }
}

/// Cache entry model
class CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final int ttlMinutes;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.ttlMinutes,
  });
}

/// Cache statistics
class CacheStats {
  final int totalEntries;
  final int expiredEntries;
  final int memoryUsage;
  final int maxMemorySize;

  CacheStats({
    required this.totalEntries,
    required this.expiredEntries,
    required this.memoryUsage,
    required this.maxMemorySize,
  });

  double get hitRatio =>
      totalEntries > 0 ? (totalEntries - expiredEntries) / totalEntries : 0.0;
  double get memoryUsageRatio => memoryUsage / maxMemorySize;
}
