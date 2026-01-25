import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/services/firebase_notification_service.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/services/notification_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return FirebaseNotificationService(
    firestore: FirebaseFirestore.instance,
  );
});

/// Provider for user's notifications
final userNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final authState = ref.watch(authStateProvider);
  final notificationService = ref.watch(notificationServiceProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return notificationService.watchUserNotifications(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Provider for filtered notifications
final filteredNotificationsProvider =
    StreamProvider.family<List<AppNotification>, NotificationType?>(
        (ref, filter) {
  final notificationsAsync = ref.watch(userNotificationsProvider);

  return notificationsAsync.when(
    data: (notifications) {
      if (filter == null) {
        return Stream.value(notifications);
      }
      return Stream.value(
        notifications
            .where((notification) => notification.type == filter)
            .toList(),
      );
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Provider for unread notification count
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final notificationsAsync = ref.watch(userNotificationsProvider);

  return notificationsAsync.when(
    data: (notifications) {
      final unreadCount = notifications.where((n) => !n.isRead).length;
      return Stream.value(unreadCount);
    },
    loading: () => Stream.value(0),
    error: (_, __) => Stream.value(0),
  );
});

/// Provider for team activity notifications
final teamActivityNotificationsProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final notificationsAsync = ref.watch(userNotificationsProvider);

  return notificationsAsync.when(
    data: (notifications) {
      final teamNotifications = notifications
          .where((n) => n.type == NotificationType.teamActivity)
          .toList();
      return Stream.value(teamNotifications);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Provider for notification actions
final notificationActionsProvider = StateNotifierProvider<
    NotificationActionsNotifier, NotificationActionsState>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return NotificationActionsNotifier(notificationService);
});

/// State for notification actions
class NotificationActionsState {
  const NotificationActionsState({
    this.isLoading = false,
    this.error,
  });

  final bool isLoading;
  final String? error;

  NotificationActionsState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return NotificationActionsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for handling notification actions
class NotificationActionsNotifier
    extends StateNotifier<NotificationActionsState> {
  NotificationActionsNotifier(this._notificationService)
      : super(const NotificationActionsState());

  final NotificationService _notificationService;

  /// Marks a notification as read
  Future<void> markAsRead(String notificationId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _notificationService.markAsRead(notificationId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Marks all notifications as read
  Future<void> markAllAsRead() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _notificationService.markAllAsRead();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Deletes a notification
  Future<void> deleteNotification(String notificationId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _notificationService.deleteNotification(notificationId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clears all read notifications
  Future<void> clearReadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _notificationService.clearReadNotifications();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clears error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}
