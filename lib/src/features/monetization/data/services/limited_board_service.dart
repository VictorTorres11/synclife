import '../../domain/models/user_limitations.dart';
import '../../domain/services/services.dart';
import '../../../tasks/domain/services/board_service.dart';
import '../../../tasks/domain/services/task_service.dart';
import '../../../tasks/domain/models/board.dart';
import '../../../tasks/domain/models/create_board_request.dart';
import '../../../auth/domain/models/user.dart';

/// Board service wrapper that enforces user limitations
class LimitedBoardService implements BoardService {
  LimitedBoardService({
    required BoardService boardService,
    required TaskService taskService,
    required SubscriptionService subscriptionService,
  })  : _boardService = boardService,
        _taskService = taskService,
        _subscriptionService = subscriptionService;

  final BoardService _boardService;
  final TaskService _taskService;
  final SubscriptionService _subscriptionService;

  @override
  Future<List<Board>> getUserBoards() {
    return _boardService.getUserBoards();
  }

  @override
  Future<Board> createBoard(CreateBoardRequest request) async {
    // Check if user can create more boards
    final canCreate = await _subscriptionService.canPerformAction(
      request.ownerId,
      LimitationType.boards,
    );

    if (!canCreate) {
      throw BoardLimitExceededException(
        'You have reached your board limit. Upgrade to Premium for unlimited boards.',
      );
    }

    // Create the board
    final board = await _boardService.createBoard(request);

    // Increment usage counter
    await _subscriptionService.incrementUsage(
      request.ownerId,
      LimitationType.boards,
    );

    return board;
  }

  @override
  Future<String> generateInviteLink(String boardId) {
    return _boardService.generateInviteLink(boardId);
  }

  @override
  Future<void> joinBoard(String inviteCode) async {
    // Note: We could add member limit checks here if needed
    // For now, we'll delegate to the base service
    return _boardService.joinBoard(inviteCode);
  }

  @override
  Stream<List<Board>> watchUserBoards() {
    return _boardService.watchUserBoards();
  }

  @override
  Future<Board?> getBoard(String boardId) {
    return _boardService.getBoard(boardId);
  }

  @override
  Future<Board> updateBoard(String boardId, Map<String, dynamic> updates) {
    return _boardService.updateBoard(boardId, updates);
  }

  @override
  Future<void> leaveBoard(String boardId) async {
    // Get the board to find the owner and check if user is the owner
    final board = await _boardService.getBoard(boardId);
    if (board == null) return;

    // Get all tasks in this board before deleting
    final tasks = await _taskService.getTasks(boardId);
    
    // Leave/delete the board
    await _boardService.leaveBoard(boardId);

    // If there were tasks in the board, decrement task counter for each task
    for (final task in tasks) {
      await _subscriptionService.decrementUsage(
        task.createdBy,
        LimitationType.activeTasks,
      );
    }

    // Decrement board counter (assuming the user was the owner)
    // In a real implementation, you'd check if the user is the owner
    await _subscriptionService.decrementUsage(
      board.ownerId,
      LimitationType.boards,
    );
  }

  @override
  Future<void> removeMember(String boardId, String userId) {
    return _boardService.removeMember(boardId, userId);
  }

  @override
  Future<List<User>> searchUsers(String query) {
    return _boardService.searchUsers(query);
  }

  @override
  Future<void> sendDirectInvitation(String boardId, String userEmail) async {
    // Check board member limits before sending invitation
    final board = await _boardService.getBoard(boardId);
    if (board == null) {
      throw Exception('Board not found');
    }

    final limitations =
        await _subscriptionService.getUserLimitations(board.ownerId);

    // Check if adding a new member would exceed limits
    if (limitations.maxBoardMembers != -1 &&
        board.memberIds.length >= limitations.maxBoardMembers) {
      throw BoardMemberLimitExceededException(
        'This board has reached its member limit. Upgrade to Premium for unlimited members.',
      );
    }

    return _boardService.sendDirectInvitation(boardId, userEmail);
  }
}

/// Exception thrown when user exceeds board limits
class BoardLimitExceededException implements Exception {
  const BoardLimitExceededException(this.message);

  final String message;

  @override
  String toString() => 'BoardLimitExceededException: $message';
}

/// Exception thrown when board member limits are exceeded
class BoardMemberLimitExceededException implements Exception {
  const BoardMemberLimitExceededException(this.message);

  final String message;

  @override
  String toString() => 'BoardMemberLimitExceededException: $message';
}
