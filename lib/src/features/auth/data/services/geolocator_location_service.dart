import 'package:geolocator/geolocator.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/services/location_service.dart';

/// Geolocator implementation of LocationService
class GeolocatorLocationService implements LocationService {
  @override
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      // Handle location errors
      return null;
    }
  }

  @override
  String detectRegionFromCoordinates(double latitude, double longitude) {
    // Comprehensive region detection based on coordinates
    
    // North America
    if (latitude >= 15 && latitude <= 85 && longitude >= -180 && longitude <= -50) {
      return 'NA';
    }
    // South America
    else if (latitude >= -60 && latitude <= 15 && longitude >= -85 && longitude <= -30) {
      return 'SA';
    }
    // Europe
    else if (latitude >= 35 && latitude <= 75 && longitude >= -15 && longitude <= 50) {
      return 'EU';
    }
    // Asia
    else if (latitude >= -10 && latitude <= 80 && longitude >= 50 && longitude <= 180) {
      return 'AS';
    }
    // Africa
    else if (latitude >= -35 && latitude <= 40 && longitude >= -20 && longitude <= 55) {
      return 'AF';
    }
    // Oceania
    else if (latitude >= -50 && latitude <= -10 && longitude >= 110 && longitude <= 180) {
      return 'OC';
    }
    // Antarctica
    else if (latitude < -60) {
      return 'AN';
    }
    
    // Default to Unknown for edge cases
    return 'UN';
  }

  @override
  String detectTimezoneFromCoordinates(double latitude, double longitude) {
    // Simplified timezone detection based on longitude
    // In a production app, you'd use a more sophisticated timezone database
    
    // Basic timezone calculation: longitude / 15 degrees per hour
    int timezoneOffset = (longitude / 15).round();
    
    // Clamp to valid timezone range (-12 to +14)
    timezoneOffset = timezoneOffset.clamp(-12, 14);
    
    // Handle special cases for some regions
    if (_isInChina(latitude, longitude)) {
      return 'Asia/Shanghai'; // China uses single timezone
    } else if (_isInIndia(latitude, longitude)) {
      return 'Asia/Kolkata'; // India Standard Time
    } else if (_isInRussia(latitude, longitude)) {
      return _getRussianTimezone(longitude);
    }
    
    // Return UTC offset format
    if (timezoneOffset == 0) {
      return 'UTC';
    } else if (timezoneOffset > 0) {
      return 'UTC+$timezoneOffset';
    } else {
      return 'UTC$timezoneOffset';
    }
  }

  @override
  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  @override
  Future<bool> requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  // Helper methods for special timezone cases
  bool _isInChina(double latitude, double longitude) {
    return latitude >= 18 && latitude <= 54 && 
           longitude >= 73 && longitude <= 135;
  }

  bool _isInIndia(double latitude, double longitude) {
    return latitude >= 6 && latitude <= 37 && 
           longitude >= 68 && longitude <= 97;
  }

  bool _isInRussia(double latitude, double longitude) {
    return latitude >= 41 && latitude <= 82 && 
           longitude >= 19 && longitude <= 180;
  }

  String _getRussianTimezone(double longitude) {
    // Simplified Russian timezone mapping
    if (longitude >= 19 && longitude < 40) return 'Europe/Moscow';
    if (longitude >= 40 && longitude < 70) return 'Asia/Yekaterinburg';
    if (longitude >= 70 && longitude < 105) return 'Asia/Novosibirsk';
    if (longitude >= 105 && longitude < 135) return 'Asia/Irkutsk';
    if (longitude >= 135 && longitude <= 180) return 'Asia/Vladivostok';
    return 'Europe/Moscow'; // Default
  }
}