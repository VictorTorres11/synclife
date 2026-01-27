import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../domain/models/user.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/services/auth_service.dart';
import '../../domain/services/user_profile_service.dart';

/// Firebase implementation of AuthService
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    firebase_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    required this.userProfileService,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: ['email', 'profile'],
              // Use o Web Client ID do Firebase Console
              // Substitua pelo seu Web Client ID real do Firebase
              // serverClientId: '835942942857-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.apps.googleusercontent.com',
            );

  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final UserProfileService userProfileService;

  @override
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      return firebaseUser != null ? User.fromFirebaseUser(firebaseUser) : null;
    });
  }

  @override
  User? get currentUser {
    final firebaseUser = _firebaseAuth.currentUser;
    return firebaseUser != null ? User.fromFirebaseUser(firebaseUser) : null;
  }

  @override
  bool get isAuthenticated => _firebaseAuth.currentUser != null;

  @override
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final firebase_auth.UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      final firebaseUser = userCredential.user;
      return firebaseUser != null ? User.fromFirebaseUser(firebaseUser) : null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Handle Firebase Auth specific errors
      throw Exception('Firebase Auth Error: ${e.code} - ${e.message}');
    } on Exception catch (e) {
      // Handle other exceptions (including Google Sign-In errors)
      throw Exception('Google Sign-In Error: ${e.toString()}');
    } catch (e) {
      // Handle any other errors
      throw Exception('Unknown error during Google Sign-In: ${e.toString()}');
    }
  }

  @override
  Future<User?> signInWithApple() async {
    try {
      // Request credential for the currently signed in Apple account
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create an `OAuthCredential` from the credential returned by Apple
      final oauthCredential =
          firebase_auth.OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in the user with Firebase
      final firebase_auth.UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(oauthCredential);

      final firebaseUser = userCredential.user;
      return firebaseUser != null ? User.fromFirebaseUser(firebaseUser) : null;
    } catch (e) {
      // Handle sign-in errors
      rethrow;
    }
  }

  @override
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final firebase_auth.UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      return firebaseUser != null ? User.fromFirebaseUser(firebaseUser) : null;
    } catch (e) {
      // Handle sign-in errors
      rethrow;
    }
  }

  @override
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final firebase_auth.UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      return firebaseUser != null ? User.fromFirebaseUser(firebaseUser) : null;
    } catch (e) {
      // Handle sign-up errors
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Sign out from Firebase
      await _firebaseAuth.signOut();
    } catch (e) {
      // Handle sign-out errors
      rethrow;
    }
  }

  @override
  Future<UserProfile> createUserProfile(String userId,
      {String? language}) async {
    return await userProfileService.createUserProfile(userId,
        language: language);
  }

  @override
  Future<User?> getCurrentUser() async {
    return currentUser;
  }
}
