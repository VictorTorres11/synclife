import 'package:mockito/mockito.dart';

import 'package:synclife_app/src/features/auth/domain/models/models.dart';
import 'package:synclife_app/src/features/auth/domain/services/auth_service.dart';
import 'package:synclife_app/src/features/gamification/domain/models/models.dart';
import 'package:synclife_app/src/features/gamification/domain/services/services.dart';
import 'package:synclife_app/src/features/tasks/domain/models/models.dart';
import 'package:synclife_app/src/features/tasks/domain/services/task_service.dart';

/// Simple mock implementation for testing
class MockTaskService extends Mock implements TaskService {
  @override
  Future<List<Task>> getTasks(String boardId) async => [];

  @override
  Future<Task?> getTask(String taskId) async => null;

  @override
  Future<Task> createTask(CreateTaskRequest request) async => Task(
        id: 'mock-task-id',
        title: request.title,
        description: request.description,
        boardId: request.boardId,
        assignedTo: request.assignedTo,
        recurrence: request.recurrence,
        dueDate: request.dueDate,
        isCompleted: false,
        tags: request.tags,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'mock-user-id',
      );

  @override
  Future<Task> updateTask(String taskId, UpdateTaskRequest request) async =>
      Task(
        id: taskId,
        title: request.title ?? 'Mock Task',
        boardId: 'mock-board-id',
        recurrence: TaskRecurrence.none,
        isCompleted: request.isCompleted ?? false,
        tags: request.tags ?? [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'mock-user-id',
      );

  @override
  Future<void> deleteTask(String taskId) async {
    // Mock implementation
  }

  @override
  Future<void> completeTask(String taskId) async {
    // Mock implementation
  }

  @override
  Stream<List<Task>> watchTasks(String boardId) => Stream.value([]);

  @override
  Future<List<Task>> getTasksByUser(String userId) async => [];

  @override
  Future<List<Task>> getTasksByDateRange(DateTime start, DateTime end) async =>
      [];

  @override
  Future<List<Task>> getTasksByTags(List<String> tags) async => [];
}

/// Mock implementation of GamificationService for testing
class MockGamificationService extends Mock implements GamificationService {
  final Map<String, UserStats> _userStats = {};
  int lastDeductedAmount = 0;
  String lastDeductedReason = '';
  int lastAwardedAmount = 0;
  String lastAwardedReason = '';

  void setUserStats(String userId, UserStats stats) {
    _userStats[userId] = stats;
  }

  @override
  Future<UserStats?> getUserStats(String userId) async {
    return _userStats[userId];
  }

  @override
  Future<UserStats> deductFluxoCoins(
      String userId, int amount, String reason) async {
    lastDeductedAmount = amount;
    lastDeductedReason = reason;

    final currentStats = _userStats[userId] ?? UserStats.initial(userId);
    final updatedStats = currentStats.copyWith(
      fluxoCoins: currentStats.fluxoCoins - amount,
      updatedAt: DateTime.now(),
    );
    _userStats[userId] = updatedStats;
    return updatedStats;
  }

  @override
  Future<UserStats> awardFluxoCoins(
      String userId, int amount, String reason) async {
    lastAwardedAmount = amount;
    lastAwardedReason = reason;

    final currentStats = _userStats[userId] ?? UserStats.initial(userId);
    final updatedStats = currentStats.copyWith(
      fluxoCoins: currentStats.fluxoCoins + amount,
      updatedAt: DateTime.now(),
    );
    _userStats[userId] = updatedStats;
    return updatedStats;
  }

  @override
  Future<List<Achievement>> getUserAchievements(String userId) async => [];

  @override
  Future<UserStats> calculateDailyXP(
      String userId, List<String> completedTaskIds) async {
    return _userStats[userId] ?? UserStats.initial(userId);
  }

  @override
  Future<UserStats> updateStreak(String userId,
      {required bool completedEssentialTasks}) async {
    return _userStats[userId] ?? UserStats.initial(userId);
  }

  @override
  Future<CollectiveStreak> updateCollectiveStreak(
      String boardId, Map<String, bool> memberCompletionStatus) async {
    return CollectiveStreak.initial(
        boardId, memberCompletionStatus.keys.toList());
  }

  @override
  Future<CollectiveStreak?> getCollectiveStreak(String boardId) async => null;

  @override
  Future<StreakValidation> validateEssentialTasks(
      String userId, DateTime date) async {
    return StreakValidation(
      userId: userId,
      date: date,
      completedEssentialTasks: 0,
      totalEssentialTasks: 0,
      isStreakDay: false,
    );
  }

  @override
  Future<UserStats> processDaily(String userId) async {
    return _userStats[userId] ?? UserStats.initial(userId);
  }

  @override
  Future<List<Achievement>> checkAndUnlockAchievements(String userId) async =>
      [];

  @override
  Stream<UserStats?> watchUserStats(String userId) =>
      Stream.value(_userStats[userId]);

  @override
  Stream<List<Achievement>> watchUserAchievements(String userId) =>
      Stream.value([]);

  @override
  Stream<CollectiveStreak?> watchCollectiveStreak(String boardId) =>
      Stream.value(null);

  @override
  int calculateTaskXP(List<String> tags, {required bool isEssential}) => 10;

  @override
  String getCategoryFromTags(List<String> tags) => 'Home';
}

/// Mock implementation of AuthService for testing
class MockAuthService extends Mock implements AuthService {
  User? _currentUser;
  final Map<String, UserProfile> _userProfiles = {};

  void setCurrentUser(User? user) {
    _currentUser = user;
  }

  void setUserProfile(String userId, UserProfile profile) {
    _userProfiles[userId] = profile;
  }

  @override
  Future<User?> signInWithGoogle() async {
    final user = User(
      id: 'mock-google-user-id',
      email: 'test@gmail.com',
      displayName: 'Test Google User',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _currentUser = user;
    return user;
  }

  @override
  Future<User?> signInWithApple() async {
    final user = User(
      id: 'mock-apple-user-id',
      email: 'test@icloud.com',
      displayName: 'Test Apple User',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _currentUser = user;
    return user;
  }

  @override
  Future<User?> signInWithEmail(String email, String password) async {
    final user = User(
      id: 'mock-email-user-id',
      email: email,
      displayName: 'Test Email User',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _currentUser = user;
    return user;
  }

  @override
  Future<User?> signUpWithEmail(String email, String password) async {
    final user = User(
      id: 'mock-new-user-id',
      email: email,
      displayName: 'New Test User',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _currentUser = user;
    return user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  Stream<User?> get authStateChanges => Stream.value(_currentUser);

  @override
  User? get currentUser => _currentUser;

  @override
  bool get isAuthenticated => _currentUser != null;

  @override
  Future<UserProfile> createUserProfile(String userId,
      {String? language}) async {
    final profile = UserProfile(
      userId: userId,
      region: 'US',
      timezone: 'America/New_York',
      language: language ?? 'en',
      isOnboardingCompleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _userProfiles[userId] = profile;
    return profile;
  }
}

/// Mock data for testing
class MockData {
  static const String mockUserId = 'test-user-123';
  static const String mockEmail = 'test@example.com';
  static const String mockBoardId = 'test-board-456';
  static const String mockTaskId = 'test-task-789';

  static Map<String, dynamic> get mockUserData => {
        'id': mockUserId,
        'email': mockEmail,
        'displayName': 'Test User',
        'createdAt': DateTime.now().toIso8601String(),
        'region': 'US',
        'timezone': 'America/New_York',
        'language': 'en',
      };

  static Map<String, dynamic> get mockTaskData => {
        'id': mockTaskId,
        'title': 'Test Task',
        'description': 'A test task for unit testing',
        'boardId': mockBoardId,
        'assignedTo': mockUserId,
        'recurrence': 'daily',
        'dueDate':
            DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'isCompleted': false,
        'tags': ['test', 'development'],
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'createdBy': mockUserId,
      };

  static Map<String, dynamic> get mockBoardData => {
        'id': mockBoardId,
        'name': 'Test Board',
        'description': 'A test board for unit testing',
        'type': 'private',
        'ownerId': mockUserId,
        'memberIds': [mockUserId],
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
}
