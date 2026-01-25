import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/services/notification_service.dart';
import '../../presentation/providers/notification_providers.dart';
import '../services/device_token_service.dart';

/// Service responsible for initializing notifications when the app starts
class NotificationInitializationService {
  NotificationInitializationService({
    required NotificationService notificationService,
    required DeviceTokenService deviceTokenService,
  })  : _notificationService = notificationService,
        _deviceTokenService = deviceTokenService;

  final NotificationService _notificationService;
  final DeviceTokenService _deviceTokenService;

  /// Initialize notifications for the app
  Future<void> initialize() async {
    try {
      debugPrint('Initializing notification service...');

      // Initialize the notification service
      await _notificationService.initialize();

      debugPrint('Notification service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  /// Setup notifications for a specific user
  Future<void> setupUserNotifications(String userId) async {
    try {
      debugPrint('Setting up notifications for user: $userId');

      // Register device token
      await _deviceTokenService.registerDeviceToken(userId);

      // Subscribe to user-specific notifications
      await _deviceTokenService.subscribeToUserNotifications(userId);

      // Listen for token refresh
      _deviceTokenService.listenForTokenRefresh(userId);

      // Clean up old tokens
      await _deviceTokenService.cleanupOldTokens(userId);

      debugPrint('User notifications setup completed');
    } catch (e) {
      debugPrint('Error setting up user notifications: $e');
    }
  }

  /// Cleanup notifications when user logs out
  Future<void> cleanupUserNotifications(String userId) async {
    try {
      debugPrint('Cleaning up notifications for user: $userId');

      // Unregister device token
      await _deviceTokenService.unregisterDeviceToken(userId);

      // Unsubscribe from user-specific notifications
      await _deviceTokenService.unsubscribeFromUserNotifications(userId);

      debugPrint('User notifications cleanup completed');
    } catch (e) {
      debugPrint('Error cleaning up user notifications: $e');
    }
  }

  /// Subscribe to board notifications
  Future<void> subscribeToBoard(String boardId) async {
    try {
      await _deviceTokenService.subscribeToBoard(boardId);
    } catch (e) {
      debugPrint('Error subscribing to board notifications: $e');
    }
  }

  /// Unsubscribe from board notifications
  Future<void> unsubscribeFromBoard(String boardId) async {
    try {
      await _deviceTokenService.unsubscribeFromBoard(boardId);
    } catch (e) {
      debugPrint('Error unsubscribing from board notifications: $e');
    }
  }
}

/// Provider for the notification initialization service
final notificationInitializationServiceProvider =
    Provider<NotificationInitializationService>((ref) {
  final notificationService = ref.read(notificationServiceProvider);
  final deviceTokenService = ref.read(deviceTokenServiceProvider);

  return NotificationInitializationService(
    notificationService: notificationService,
    deviceTokenService: deviceTokenService,
  );
});

/// Provider that handles notification initialization based on auth state
final notificationInitializationProvider = Provider<void>((ref) {
  final initService = ref.read(notificationInitializationServiceProvider);
  final authState = ref.watch(authStateProvider);

  // Initialize notifications when app starts
  initService.initialize();

  // Setup/cleanup user notifications based on auth state
  authState.whenData((user) {
    if (user != null) {
      initService.setupUserNotifications(user.id);
    }
  });

  // Listen for auth state changes
  ref.listen(authStateProvider, (previous, next) {
    next.whenData((user) {
      if (user != null) {
        // User logged in - setup notifications
        initService.setupUserNotifications(user.id);
      } else {
        // User logged out - cleanup notifications
        if (previous?.value != null) {
          initService.cleanupUserNotifications(previous!.value!.id);
        }
      }
    });
  });
});
