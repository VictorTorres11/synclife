import 'package:geolocator/geolocator.dart';

/// Service for handling location detection and region/timezone mapping
abstract class LocationService {
  /// Get current GPS position
  Future<Position?> getCurrentPosition();
  
  /// Detect region from GPS coordinates
  String detectRegionFromCoordinates(double latitude, double longitude);
  
  /// Detect timezone from GPS coordinates
  String detectTimezoneFromCoordinates(double latitude, double longitude);
  
  /// Check if location permissions are granted
  Future<bool> hasLocationPermission();
  
  /// Request location permissions
  Future<bool> requestLocationPermission();
}