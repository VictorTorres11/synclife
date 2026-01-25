import '../models/board.dart';
import '../models/create_board_request.dart';
import '../../../auth/domain/models/user.dart';

/// Abstract interface for board management operations
abstract class BoardService {
  /// Get all boards for the current user
  Future<List<Board>> getUserBoards();

  /// Create a new board
  Future<Board> createBoard(CreateBoardRequest request);

  /// Generate an invite link for a board
  Future<String> generateInviteLink(String boardId);

  /// Join a board using an invite code
  Future<void> joinBoard(String inviteCode);

  /// Watch user boards for real-time updates
  Stream<List<Board>> watchUserBoards();

  /// Get a specific board by ID
  Future<Board?> getBoard(String boardId);

  /// Update board settings
  Future<Board> updateBoard(String boardId, Map<String, dynamic> updates);

  /// Leave a board
  Future<void> leaveBoard(String boardId);

  /// Remove a member from a board (owner only)
  Future<void> removeMember(String boardId, String userId);

  /// Search for users by email or user ID
  Future<List<User>> searchUsers(String query);

  /// Send direct invitation to a user
  Future<void> sendDirectInvitation(String boardId, String userEmail);
}