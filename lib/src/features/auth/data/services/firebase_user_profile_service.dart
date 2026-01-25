import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/user_profile.dart';
import '../../domain/services/location_service.dart';
import '../../domain/services/user_profile_service.dart';

/// Firebase implementation of UserProfileService
class FirebaseUserProfileService implements UserProfileService {
  FirebaseUserProfileService({
    FirebaseFirestore? firestore,
    required this.locationService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final LocationService locationService;

  @override
  Future<UserProfile> createUserProfile(String userId, {String? language}) async {
    final now = DateTime.now();
    
    // Try to detect location automatically
    String region = 'UN'; // Default to Unknown
    String timezone = 'UTC'; // Default to UTC
    
    try {
      final position = await locationService.getCurrentPosition();
      if (position != null) {
        region = locationService.detectRegionFromCoordinates(
          position.latitude, 
          position.longitude,
        );
        timezone = locationService.detectTimezoneFromCoordinates(
          position.latitude, 
          position.longitude,
        );
      }
    } catch (e) {
      // If location detection fails, use system defaults
      region = _getSystemRegion();
      timezone = _getSystemTimezone();
    }
    
    // Determine language
    final detectedLanguage = language ?? _getSystemLanguage();
    
    final profile = UserProfile(
      userId: userId,
      region: region,
      timezone: timezone,
      language: detectedLanguage,
      isOnboardingCompleted: false,
      createdAt: now,
      updatedAt: now,
    );
    
    // Save to Firestore
    await _firestore
        .collection('userProfiles')
        .doc(userId)
        .set(profile.toMap());
    
    return profile;
  }

  @override
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection('userProfiles')
          .doc(userId)
          .get();
      
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<UserProfile> updateUserProfile(UserProfile profile) async {
    final updatedProfile = profile.copyWith(updatedAt: DateTime.now());
    
    await _firestore
        .collection('userProfiles')
        .doc(profile.userId)
        .update(updatedProfile.toMap());
    
    return updatedProfile;
  }

  @override
  Future<UserProfile> updateLanguage(String userId, String language) async {
    final profile = await getUserProfile(userId);
    if (profile == null) {
      throw Exception('User profile not found');
    }
    
    final updatedProfile = profile.copyWith(
      language: language,
      updatedAt: DateTime.now(),
    );
    
    await _firestore
        .collection('userProfiles')
        .doc(userId)
        .update({'language': language, 'updatedAt': updatedProfile.updatedAt.toIso8601String()});
    
    return updatedProfile;
  }

  // Helper methods for system defaults
  String _getSystemRegion() {
    // Try to detect region from system locale
    try {
      final locale = Platform.localeName;
      if (locale.contains('_')) {
        final countryCode = locale.split('_').last;
        return _mapCountryCodeToRegion(countryCode);
      }
    } catch (e) {
      // Ignore errors
    }
    return 'UN';
  }

  String _getSystemTimezone() {
    // In a real implementation, you'd use a timezone detection library
    // For now, return UTC as default
    return 'UTC';
  }

  String _getSystemLanguage() {
    try {
      final locale = Platform.localeName;
      if (locale.contains('_')) {
        return locale.split('_').first;
      }
      return locale;
    } catch (e) {
      return 'en'; // Default to English
    }
  }

  String _mapCountryCodeToRegion(String countryCode) {
    // Map country codes to regions
    const countryToRegion = {
      // North America
      'US': 'NA', 'CA': 'NA', 'MX': 'NA',
      // South America
      'BR': 'SA', 'AR': 'SA', 'CL': 'SA', 'CO': 'SA', 'PE': 'SA',
      // Europe
      'GB': 'EU', 'DE': 'EU', 'FR': 'EU', 'IT': 'EU', 'ES': 'EU', 'NL': 'EU',
      'SE': 'EU', 'NO': 'EU', 'DK': 'EU', 'FI': 'EU', 'PL': 'EU', 'RU': 'EU',
      // Asia
      'CN': 'AS', 'JP': 'AS', 'KR': 'AS', 'IN': 'AS', 'TH': 'AS', 'VN': 'AS',
      'ID': 'AS', 'MY': 'AS', 'SG': 'AS', 'PH': 'AS',
      // Africa
      'ZA': 'AF', 'NG': 'AF', 'EG': 'AF', 'KE': 'AF', 'MA': 'AF',
      // Oceania
      'AU': 'OC', 'NZ': 'OC', 'FJ': 'OC',
    };
    
    return countryToRegion[countryCode.toUpperCase()] ?? 'UN';
  }
}