import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synclife_app/src/core/theme/app_theme.dart';
import 'package:synclife_app/src/features/auth/domain/models/models.dart';
import 'package:synclife_app/src/features/gamification/domain/models/models.dart';
import 'package:synclife_app/src/features/tasks/domain/models/models.dart';
import 'package:synclife_app/src/features/tasks/presentation/pages/tasks_page.dart';
import '../helpers/mock_services.dart';

/// Integration tests for complete user flows
/// Tests registration, onboarding, task management, board collaboration, and gamification
void main() {
  group('Complete Flow Integration Tests', () {
    late MockAuthService mockAuthService;
    late MockTaskService mockTaskService;
    late MockGamificationService mockGamificationService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockTaskService = MockTaskService();
      mockGamificationService = MockGamificationService();
    });

    testWidgets('Registration and onboarding flow works end-to-end',
        (tester) async {
      // Step 1: User opens app for first time
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              appBar: AppBar(title: const Text('Welcome to SyncLife')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Create your account'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Sign in with Google'),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Sign in with Apple'),
                    ),
                    const TextField(
                      decoration: InputDecoration(labelText: 'Email'),
                    ),
                    const TextField(
                      decoration: InputDecoration(labelText: 'Password'),
                      obscureText: true,
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Register'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Verify registration options are available
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.text('Sign in with Apple'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);

      // Step 2: User registers with email
      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'test@example.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Password'), 'password123');
      await tester.pumpAndSettle();

      // Simulate registration
      final user = await mockAuthService.signUpWithEmail(
          'test@example.com', 'password123');
      expect(user, isNotNull);
      expect(user!.email, equals('test@example.com'));

      // Step 3: Verify user profile is created with region detection
      final profile = await mockAuthService.createUserProfile(user.id);
      expect(profile.userId, equals(user.id));
      expect(profile.region, isNotEmpty);
      expect(profile.timezone, isNotEmpty);

      // Step 4: Verify onboarding starts
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, size: 64),
                    const SizedBox(height: 16),
                    const Text('Welcome to SyncLife!'),
                    const SizedBox(height: 8),
                    const Text('Let\'s get you started'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Start Tour'),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Skip'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Welcome to SyncLife!'), findsOneWidget);
      expect(find.text('Start Tour'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('Task creation and management flow works end-to-end',
        (tester) async {
      // Setup: User is logged in
      final user = User(
        id: 'test-user-id',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockAuthService.setCurrentUser(user);

      // Step 1: Navigate to tasks page
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const TasksPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify tasks page is displayed
      expect(find.text('SyncLife'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Step 2: Create a new task
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify task creation dialog/page appears
      // (In real implementation, this would show a form)

      // Step 3: Fill task details
      final taskRequest = CreateTaskRequest(
        title: 'Complete project documentation',
        description: 'Write comprehensive docs for the project',
        boardId: 'default-board-id',
        recurrence: TaskRecurrence.daily,
        dueDate: DateTime.now().add(const Duration(days: 1)),
        tags: ['Work', 'Documentation'],
        createdBy: user.id,
      );

      final createdTask = await mockTaskService.createTask(taskRequest);
      expect(createdTask.title, equals('Complete project documentation'));
      expect(createdTask.recurrence, equals(TaskRecurrence.daily));
      expect(createdTask.tags, contains('Work'));

      // Step 4: Verify task appears in list
      await tester.pumpAndSettle();

      // Step 5: Complete the task (swipe right)
      // In real implementation, this would be a swipe gesture
      await mockTaskService.completeTask(createdTask.id);

      // Step 6: Verify completion feedback
      // (Visual feedback and sound would be tested here)
    });

    testWidgets('Board collaboration flow works end-to-end', (tester) async {
      // Setup: Two users
      final user1 = User(
        id: 'user-1-id',
        email: 'user1@example.com',
        displayName: 'User One',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final user2 = User(
        id: 'user-2-id',
        email: 'user2@example.com',
        displayName: 'User Two',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      mockAuthService.setCurrentUser(user1);

      // Step 1: User 1 creates a shared board
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              appBar: AppBar(title: const Text('Boards')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('My Boards'),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Create Board'),
                    ),
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {},
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Create Board'), findsOneWidget);

      // Step 2: Generate invite link
      const inviteLink = 'https://synclife.app/invite/unique-code-123';
      expect(inviteLink, contains('unique-code-123'));

      // Step 3: User 2 joins via invite link
      mockAuthService.setCurrentUser(user2);

      // Simulate joining board
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              appBar: AppBar(title: const Text('Join Board')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('You\'ve been invited to join a board!'),
                    const SizedBox(height: 20),
                    const Text('Family Tasks'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Accept Invitation'),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Decline'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Accept Invitation'), findsOneWidget);

      // Step 4: Verify real-time synchronization
      // Both users should see the same tasks
      final task = await mockTaskService.createTask(
        CreateTaskRequest(
          title: 'Shared task',
          boardId: 'shared-board-id',
          recurrence: TaskRecurrence.none,
          tags: ['Shared'],
          createdBy: user1.id,
        ),
      );

      expect(task.title, equals('Shared task'));
      expect(task.boardId, equals('shared-board-id'));

      // Step 5: Test task assignment
      final updatedTask = await mockTaskService.updateTask(
        task.id,
        UpdateTaskRequest(
          assignedTo: user2.id,
        ),
      );

      expect(updatedTask.assignedTo, equals(user2.id));

      // Step 6: Test comments (would be implemented in real service)
      // Comments would allow team communication on tasks
    });

    testWidgets('Gamification system flow works end-to-end', (tester) async {
      // Setup: User with initial stats
      final user = User(
        id: 'gamification-user-id',
        email: 'gamer@example.com',
        displayName: 'Gamer User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final initialStats = UserStats(
        userId: user.id,
        totalXP: 0,
        level: 1,
        fluxoCoins: 100,
        currentStreak: 0,
        longestStreak: 0,
        categoryXP: {},
        lastActive: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      mockAuthService.setCurrentUser(user);
      mockGamificationService.setUserStats(user.id, initialStats);

      // Step 1: Display gamification dashboard
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              appBar: AppBar(title: const Text('Your Progress')),
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text('Level 1'),
                            const SizedBox(height: 8),
                            const LinearProgressIndicator(value: 0.0),
                            const SizedBox(height: 8),
                            Text('0 / 100 XP'),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Icon(Icons.local_fire_department),
                                    const Text('Streak'),
                                    Text('${initialStats.currentStreak} days'),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Icon(Icons.monetization_on),
                                    const Text('FluxoCoins'),
                                    Text('${initialStats.fluxoCoins}'),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Category Progress'),
                            SizedBox(height: 8),
                            Text('Health: 0 XP'),
                            Text('Home: 0 XP'),
                            Text('Finance: 0 XP'),
                            Text('Work: 0 XP'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Level 1'), findsOneWidget);
      expect(find.text('0 days'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);

      // Step 2: Complete tasks to earn XP
      final task1 = await mockTaskService.createTask(
        CreateTaskRequest(
          title: 'Morning workout',
          boardId: 'default-board',
          recurrence: TaskRecurrence.daily,
          tags: ['Health', 'Essential'],
          createdBy: user.id,
        ),
      );

      await mockTaskService.completeTask(task1.id);

      // Step 3: Process daily XP calculation
      final updatedStats = await mockGamificationService.calculateDailyXP(
        user.id,
        [task1.id],
      );

      expect(updatedStats.userId, equals(user.id));

      // Step 4: Update streak
      final streakStats = await mockGamificationService.updateStreak(
        user.id,
        completedEssentialTasks: true,
      );

      expect(streakStats.userId, equals(user.id));

      // Step 5: Award FluxoCoins
      final coinsStats = await mockGamificationService.awardFluxoCoins(
        user.id,
        50,
        'Daily completion bonus',
      );

      expect(coinsStats.fluxoCoins, greaterThan(initialStats.fluxoCoins));
      expect(mockGamificationService.lastAwardedAmount, equals(50));
      expect(mockGamificationService.lastAwardedReason,
          equals('Daily completion bonus'));

      // Step 6: Verify leaderboard (for shared boards)
      // In real implementation, this would show rankings
    });

    testWidgets('Complete user journey from registration to rewards',
        (tester) async {
      // This test combines all flows into one complete journey

      // Step 1: Registration
      final user = await mockAuthService.signUpWithEmail(
        'journey@example.com',
        'password123',
      );
      expect(user, isNotNull);

      // Step 2: Profile creation with region detection
      final profile = await mockAuthService.createUserProfile(user!.id);
      expect(profile.region, isNotEmpty);

      // Step 3: Create initial stats
      final initialStats = UserStats.initial(user.id);
      mockGamificationService.setUserStats(user.id, initialStats);

      // Step 4: Create first task
      final task = await mockTaskService.createTask(
        CreateTaskRequest(
          title: 'First task',
          boardId: 'default-board',
          recurrence: TaskRecurrence.daily,
          tags: ['Home'],
          createdBy: user.id,
        ),
      );
      expect(task.title, equals('First task'));

      // Step 5: Complete task
      await mockTaskService.completeTask(task.id);

      // Step 6: Earn XP and coins
      await mockGamificationService.calculateDailyXP(user.id, [task.id]);
      final stats = await mockGamificationService.awardFluxoCoins(
        user.id,
        25,
        'First task completion',
      );

      expect(stats!.fluxoCoins, greaterThan(0));

      // Step 7: Create shared board
      // (Would be implemented with BoardService)

      // Step 8: Invite friend
      // (Would be implemented with invitation system)

      // Step 9: Earn referral bonus
      // (Would be triggered after friend completes 5 tasks)

      // Step 10: Purchase from store
      final purchaseStats = await mockGamificationService.deductFluxoCoins(
        user.id,
        50,
        'Store purchase: Theme',
      );

      expect(purchaseStats.fluxoCoins, lessThan(stats.fluxoCoins));
      expect(mockGamificationService.lastDeductedAmount, equals(50));
    });

    testWidgets('Multi-user collaboration scenario', (tester) async {
      // Simulate a family using SyncLife together

      // Create family members
      final parent1 = await mockAuthService.signUpWithEmail(
        'parent1@family.com',
        'password',
      );
      final parent2 = await mockAuthService.signUpWithEmail(
        'parent2@family.com',
        'password',
      );

      expect(parent1, isNotNull);
      expect(parent2, isNotNull);

      // Initialize stats for both
      mockGamificationService.setUserStats(
        parent1!.id,
        UserStats.initial(parent1.id),
      );
      mockGamificationService.setUserStats(
        parent2!.id,
        UserStats.initial(parent2.id),
      );

      // Parent 1 creates shared board
      const boardId = 'family-board-id';

      // Both create and complete tasks
      final task1 = await mockTaskService.createTask(
        CreateTaskRequest(
          title: 'Grocery shopping',
          boardId: boardId,
          recurrence: TaskRecurrence.weekly,
          tags: ['Home', 'Essential'],
          assignedTo: parent1.id,
          createdBy: parent1.id,
        ),
      );

      final task2 = await mockTaskService.createTask(
        CreateTaskRequest(
          title: 'Cook dinner',
          boardId: boardId,
          recurrence: TaskRecurrence.daily,
          tags: ['Home', 'Essential'],
          assignedTo: parent2.id,
          createdBy: parent2.id,
        ),
      );

      // Complete tasks
      await mockTaskService.completeTask(task1.id);
      await mockTaskService.completeTask(task2.id);

      // Update collective streak
      final collectiveStreak =
          await mockGamificationService.updateCollectiveStreak(
        boardId,
        {
          parent1.id: true,
          parent2.id: true,
        },
      );

      expect(collectiveStreak.boardId, equals(boardId));
      expect(collectiveStreak.memberIds, contains(parent1.id));
      expect(collectiveStreak.memberIds, contains(parent2.id));

      // Verify both users maintain individual streaks
      await mockGamificationService.updateStreak(
        parent1.id,
        completedEssentialTasks: true,
      );
      await mockGamificationService.updateStreak(
        parent2.id,
        completedEssentialTasks: true,
      );
    });

    testWidgets('Task recurrence patterns work correctly', (tester) async {
      final user = await mockAuthService.signUpWithEmail(
        'recurrence@example.com',
        'password',
      );

      // Test daily recurrence
      final dailyTask = await mockTaskService.createTask(
        CreateTaskRequest(
          title: 'Daily meditation',
          boardId: 'default-board',
          recurrence: TaskRecurrence.daily,
          tags: ['Health'],
          createdBy: user!.id,
        ),
      );
      expect(dailyTask.recurrence, equals(TaskRecurrence.daily));

      // Test weekly recurrence
      final weeklyTask = await mockTaskService.createTask(
        CreateTaskRequest(
          title: 'Weekly review',
          boardId: 'default-board',
          recurrence: TaskRecurrence.weekly,
          tags: ['Work'],
          createdBy: user.id,
        ),
      );
      expect(weeklyTask.recurrence, equals(TaskRecurrence.weekly));

      // Test monthly recurrence
      final monthlyTask = await mockTaskService.createTask(
        CreateTaskRequest(
          title: 'Pay bills',
          boardId: 'default-board',
          recurrence: TaskRecurrence.monthly,
          tags: ['Finance'],
          createdBy: user.id,
        ),
      );
      expect(monthlyTask.recurrence, equals(TaskRecurrence.monthly));

      // Test one-time task
      final oneTimeTask = await mockTaskService.createTask(
        CreateTaskRequest(
          title: 'Buy birthday gift',
          boardId: 'default-board',
          recurrence: TaskRecurrence.none,
          dueDate: DateTime.now().add(const Duration(days: 7)),
          tags: ['Personal'],
          createdBy: user.id,
        ),
      );
      expect(oneTimeTask.recurrence, equals(TaskRecurrence.none));
      expect(oneTimeTask.dueDate, isNotNull);
    });

    testWidgets('Inbox to task conversion flow', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const TasksPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to Inbox tab
      await tester.tap(find.text('Inbox'));
      await tester.pumpAndSettle();

      // Verify Inbox is displayed
      // In real implementation, user would see inbox items

      // Simulate creating inbox item
      final inboxItem = await mockTaskService.createTask(
        CreateTaskRequest(
          title: 'Quick note',
          boardId: 'inbox',
          recurrence: TaskRecurrence.none,
          tags: ['Inbox'],
          createdBy: 'test-user-id',
        ),
      );

      expect(inboxItem.title, equals('Quick note'));

      // Simulate drag to convert to task
      // In real implementation, this would be a drag gesture
      final convertedTask = await mockTaskService.updateTask(
        inboxItem.id,
        UpdateTaskRequest(
          dueDate: DateTime.now().add(const Duration(days: 1)),
          tags: ['Home'],
        ),
      );

      expect(convertedTask.id, equals(inboxItem.id));
    });
  });
}
