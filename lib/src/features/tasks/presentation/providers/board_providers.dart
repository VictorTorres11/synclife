import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/services/firebase_board_activity_service.dart';
import '../../data/services/firebase_board_invitation_service.dart';
import '../../data/services/firebase_board_service.dart';
import '../../domain/models/board.dart';
import '../../domain/models/board_activity.dart';
import '../../domain/models/board_invitation.dart';
import '../../domain/services/board_activity_service.dart';
import '../../domain/services/board_invitation_service.dart';
import '../../domain/services/board_service.dart';

/// Provider for the board service
final boardServiceProvider = Provider<BoardService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return FirebaseBoardService(authService: authService);
});

/// Provider for the board invitation service
final boardInvitationServiceProvider = Provider<BoardInvitationService>((ref) {
  return FirebaseBoardInvitationService();
});

/// Provider for the board activity service
final boardActivityServiceProvider = Provider<BoardActivityService>((ref) {
  return FirebaseBoardActivityService();
});

/// Provider for user boards stream
final userBoardsProvider = StreamProvider<List<Board>>((ref) {
  final boardService = ref.watch(boardServiceProvider);
  return boardService.watchUserBoards();
});

/// Provider for a specific board
final boardProvider =
    FutureProvider.family<Board?, String>((ref, boardId) async {
  final boardService = ref.watch(boardServiceProvider);
  return boardService.getBoard(boardId);
});

/// Provider for board members count
final boardMembersCountProvider =
    Provider.family<int, Board>((ref, board) => board.memberIds.length);

/// Provider for checking if current user is board owner
final isBoardOwnerProvider = Provider.family<bool, Board>((ref, board) {
  final currentUser = ref.watch(currentUserProvider);
  return currentUser?.id == board.ownerId;
});

/// Provider for checking if current user can invite to board
final canInviteToBoardProvider = Provider.family<bool, Board>((ref, board) {
  final isOwner = ref.watch(isBoardOwnerProvider(board));
  // For now, only owners can invite (can be extended later)
  return isOwner;
});

/// Provider for board invitations stream
final boardInvitationsProvider =
    StreamProvider.family<List<BoardInvitation>, String>((ref, boardId) {
  final invitationService = ref.watch(boardInvitationServiceProvider);
  return invitationService.watchBoardInvitations(boardId);
});

/// Provider for pending board invitations
final pendingBoardInvitationsProvider =
    FutureProvider.family<List<BoardInvitation>, String>((ref, boardId) async {
  final invitationService = ref.watch(boardInvitationServiceProvider);
  return invitationService.getPendingInvitations(boardId);
});

/// Provider for board invitation history
final boardInvitationHistoryProvider =
    FutureProvider.family<List<BoardInvitation>, String>((ref, boardId) async {
  final invitationService = ref.watch(boardInvitationServiceProvider);
  return invitationService.getInvitationHistory(boardId);
});

/// Provider for board invitation statistics
final boardInvitationStatsProvider =
    FutureProvider.family<BoardInvitationStats, String>((ref, boardId) async {
  final invitationService = ref.watch(boardInvitationServiceProvider);
  return invitationService.getInvitationStats(boardId);
});

/// Provider for board activities stream
final boardActivitiesProvider =
    StreamProvider.family<List<BoardActivity>, String>((ref, boardId) {
  final activityService = ref.watch(boardActivityServiceProvider);
  return activityService.watchBoardActivities(boardId);
});

/// Provider for online users stream
final onlineUsersProvider =
    StreamProvider.family<List<UserPresence>, String>((ref, boardId) {
  final activityService = ref.watch(boardActivityServiceProvider);
  return activityService.watchOnlineUsers(boardId);
});

/// Provider for board activity statistics
final boardActivityStatsProvider =
    FutureProvider.family<BoardActivityStats, String>((ref, boardId) async {
  final activityService = ref.watch(boardActivityServiceProvider);
  return activityService.getActivityStats(boardId);
});
