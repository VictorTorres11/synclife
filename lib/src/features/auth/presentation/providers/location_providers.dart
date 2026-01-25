import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/services/firebase_user_profile_service.dart';
import '../../data/services/geolocator_location_service.dart';
import '../../domain/services/location_service.dart';
import '../../domain/services/user_profile_service.dart';

part 'location_providers.g.dart';

/// Provider for the LocationService implementation
@riverpod
LocationService locationService(LocationServiceRef ref) {
  return GeolocatorLocationService();
}

/// Provider for the UserProfileService implementation
@riverpod
UserProfileService userProfileService(UserProfileServiceRef ref) {
  final locationService = ref.watch(locationServiceProvider);
  return FirebaseUserProfileService(locationService: locationService);
}