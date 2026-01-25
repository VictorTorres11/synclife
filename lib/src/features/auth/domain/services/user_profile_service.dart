import '../models/user_profile.dart';

/// Service for managing user profiles
abstract class UserProfileService {
  /// Create a new user profile with automatic region/timezone detection
  Future<UserProfile> createUserProfile(String userId, {String? language});
  
  /// Get user profile by user ID
  Future<UserProfile?> getUserProfile(String userId);
  
  /// Update user profile
  Future<UserProfile> updateUserProfile(UserProfile profile);
  
  /// Update user language preference
  Future<UserProfile> updateLanguage(String userId, String language);
}