import '../models/user.dart';
import '../models/user_profile.dart';

/// Abstract interface for authentication operations
abstract class AuthService {
  /// Sign in with Google account
  Future<User?> signInWithGoogle();

  /// Sign in with Apple account
  Future<User?> signInWithApple();

  /// Sign in with email and password
  Future<User?> signInWithEmail(String email, String password);

  /// Sign up with email and password
  Future<User?> signUpWithEmail(String email, String password);

  /// Sign out the current user
  Future<void> signOut();

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges;

  /// Get the current authenticated user
  User? get currentUser;

  /// Get the current authenticated user asynchronously
  Future<User?> getCurrentUser();

  /// Check if user is currently authenticated
  bool get isAuthenticated;

  /// Create user profile after registration
  Future<UserProfile> createUserProfile(String userId, {String? language});

  /// Update user profile information
  Future<void> updateUserProfile({String? displayName, String? photoURL});
}
