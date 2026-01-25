import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/firebase_auth_service.dart';
import '../../domain/models/user.dart';
import '../../domain/services/auth_service.dart';
import 'location_providers.dart';

part 'auth_providers.g.dart';

/// Provider for the AuthService implementation
@riverpod
AuthService authService(AuthServiceRef ref) {
  final userProfileService = ref.watch(userProfileServiceProvider);
  return FirebaseAuthService(userProfileService: userProfileService);
}

/// Provider for the current authenticated user
@riverpod
Stream<User?> authState(AuthStateRef ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
}

/// Provider for checking if user is authenticated
@riverpod
bool isAuthenticated(IsAuthenticatedRef ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
}

/// Provider for the current user (synchronous access)
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});
