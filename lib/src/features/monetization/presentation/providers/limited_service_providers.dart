import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/limited_task_service.dart';
import '../../data/services/limited_board_service.dart';
import '../../domain/services/subscription_service.dart';
import '../../../tasks/domain/services/task_service.dart';
import '../../../tasks/domain/services/board_service.dart';
import '../../../../core/sync/providers/sync_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../tasks/data/services/firebase_board_service.dart';
import 'monetization_providers.dart';

/// Provider for the base task service (offline-first)
final baseTaskServiceProvider = Provider<TaskService>((ref) {
  return ref.read(offlineTaskServiceProvider);
});

/// Provider for the base board service
final baseBoardServiceProvider = Provider<BoardService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return FirebaseBoardService(authService: authService);
});

/// Provider for limited task service that enforces usage limits
final limitedTaskServiceProvider = Provider<TaskService>((ref) {
  final baseTaskService = ref.watch(baseTaskServiceProvider);
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return LimitedTaskService(
    taskService: baseTaskService,
    subscriptionService: subscriptionService,
  );
});

/// Provider for limited board service that enforces usage limits
final limitedBoardServiceProvider = Provider<BoardService>((ref) {
  final baseBoardService = ref.watch(baseBoardServiceProvider);
  final baseTaskService = ref.watch(baseTaskServiceProvider);
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return LimitedBoardService(
    boardService: baseBoardService,
    taskService: baseTaskService,
    subscriptionService: subscriptionService,
  );
});