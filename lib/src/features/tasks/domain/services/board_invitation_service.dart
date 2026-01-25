import '../models/board_invitation.dart';
import '../../../auth/domain/models/user.dart';

/// Service interface for board invitation management
abstract class BoardInvitationService {
  /// Creates a board invitation
  Future<BoardInvitation> createBoardInvitation({
    required String boardId,
    required String boardName,
    required String inviterId,
    required String inviterName,
    required String inviterEmail,
    required String inviteeEmail,
    String? message,
    DateTime? expiresAt,
  });

  /// Accepts a board invitation
  Future<BoardInvitation> acceptBoardInvitation(
      String inviteCode, String userId);

  /// Declines a board invitation
  Future<BoardInvitation> declineBoardInvitation(String inviteCode);

  /// Cancels a board invitation (by inviter)
  Future<BoardInvitation> cancelBoardInvitation(String invitationId);

  /// Gets invitations sent for a specific board
  Future<List<BoardInvitation>> getBoardInvitations(String boardId);

  /// Gets invitations sent by a user across all boards
  Future<List<BoardInvitation>> getSentInvitations(String userId);

  /// Gets invitations received by a user (by email)
  Future<List<BoardInvitation>> getReceivedInvitations(String email);

  /// Gets pending invitations for a board
  Future<List<BoardInvitation>> getPendingInvitations(String boardId);

  /// Gets invitation by invite code
  Future<BoardInvitation?> getInvitationByCode(String inviteCode);

  /// Generates a unique invite code for board
  String generateBoardInviteCode();

  /// Validates a board invite code format
  bool isValidBoardInviteCode(String code);

  /// Checks if an email is already invited to a board
  Future<bool> isEmailAlreadyInvited(String boardId, String email);

  /// Searches for users by email or name
  Future<List<User>> searchUsers(String query);

  /// Gets invitation history for a board (all statuses)
  Future<List<BoardInvitation>> getInvitationHistory(String boardId);

  /// Watches board invitations in real-time
  Stream<List<BoardInvitation>> watchBoardInvitations(String boardId);

  /// Watches sent invitations by user in real-time
  Stream<List<BoardInvitation>> watchSentInvitations(String userId);

  /// Watches received invitations by email in real-time
  Stream<List<BoardInvitation>> watchReceivedInvitations(String email);

  /// Resends an invitation (creates new one, cancels old)
  Future<BoardInvitation> resendInvitation(String invitationId);

  /// Bulk invite multiple emails to a board
  Future<List<BoardInvitation>> bulkInviteToBoard({
    required String boardId,
    required String boardName,
    required String inviterId,
    required String inviterName,
    required String inviterEmail,
    required List<String> inviteeEmails,
    String? message,
    DateTime? expiresAt,
  });

  /// Gets invitation statistics for a board
  Future<BoardInvitationStats> getInvitationStats(String boardId);
}

/// Statistics for board invitations
class BoardInvitationStats {
  const BoardInvitationStats({
    required this.totalSent,
    required this.totalAccepted,
    required this.totalPending,
    required this.totalDeclined,
    required this.totalExpired,
    required this.totalCancelled,
  });

  final int totalSent;
  final int totalAccepted;
  final int totalPending;
  final int totalDeclined;
  final int totalExpired;
  final int totalCancelled;

  double get acceptanceRate => totalSent > 0 ? totalAccepted / totalSent : 0.0;
  double get pendingRate => totalSent > 0 ? totalPending / totalSent : 0.0;
}
