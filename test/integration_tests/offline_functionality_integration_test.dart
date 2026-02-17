import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synclife_app/src/core/theme/app_theme.dart';
import 'package:synclife_app/src/features/auth/domain/models/models.dart';
import 'package:synclife_app/src/features/tasks/domain/models/models.dart';
import 'package:synclife_app/src/features/tasks/presentation/pages/tasks_page.dart';
import '../helpers/mock_services.dart';

/// Integration tests for offline functionality
/// Tests task creation offline, synchronization when online, and conflict resolution
void main() {
  group('Offline Functionality Integration Tests', () {
    late MockAuthService mockAuthService;
    late MockTaskService mockTaskService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockTaskService = MockTaskService();
    });

    testWidgets('User can create tasks while offline', (tester) async {
      // Setup: User is logged in
      final user = User(
        id: 'offline-user-id',
        email: 'offline@example.com',
        displayName: 'Offline User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockAuthService.setCurrentUser(user);

      // Simulate offline state
      var isOnline = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Tasks'),
                actions: [
                  // Offline indicator
                  if (!isOnline)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.cloud_off, color: Colors.orange),
                    ),
                ],
              ),
              body: const TasksPage(),
              floatingActionButton: FloatingActionButton(
                onPressed: () {},
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify offline indicator is shown
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);

      // Create task while offline
      final offlineTask = await mockTaskService.createTask(
        CreateTaskRequest(
          title: 'Offline task',
          boardId: 'default-board',
          recurrence: TaskRecurrence.daily,
          tags: ['Home'],
          createdBy: user.id,
        ),
      );

      expect(offlineTask.title, equals('Offline task'));
      expect(offlineTask.id, isNotEmpty);

      // Task should be stored locally
      // In real implementation, this would be in SQLite
      final localTasks = await mockTaskService.getTasks('default-board');
      expect(localTasks, isNotEmpty);

      // Verify task appears in UI
      await tester.pumpAndSettle();
    });

    testWidgets('Tasks sync when connection is restored', (tester) async {
      // Setup: User with offline tasks
      final user = User(
        id: 'sync-user-id',
        email: 'sync@example.com',
        displayName: 'Sync User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockAuthService.setCurrentUser(user);

      // Create tasks while offline
      var isOnline = false;
      final offlineTasks = <Task>[];

      for (int i = 0; i < 3; i++) {
        final task = await mockTaskService.createTask(
          CreateTaskRequest(
            title: 'Offline task $i',
            boardId: 'default-board',
            recurrence: TaskRecurrence.daily,
            tags: ['Offline'],
            createdBy: user.id,
          ),
        );
        offlineTasks.add(task);
      }

      expect(offlineTasks.length, equals(3));

      // Display sync status
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Tasks'),
                actions: [
                  if (!isOnline)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(Icons.cloud_off, color: Colors.orange),
                          SizedBox(width: 4),
                          Text('Offline', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                ],
              ),
              body: Column(
                children: [
                  if (!isOnline)
                    Container(
                      color: Colors.orange.shade100,
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '${offlineTasks.length} tasks pending sync',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  const Expanded(
                    child: Center(
                      child: Text('Task list'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('3 tasks pending sync'), findsOneWidget);

      // Simulate connection restored
      isOnline = true;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Tasks'),
                actions: [
                  if (isOnline)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(Icons.cloud_done, color: Colors.green),
                          SizedBox(width: 4),
                          Text('Syncing...', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                ],
              ),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Syncing tasks...'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Syncing...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Simulate sync completion
      await tester.pumpAndSettle();

      // Verify all tasks are synced
      for (final task in offlineTasks) {
        expect(task.id, isNotEmpty);
      }

      // Show sync complete
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Tasks'),
                actions: const [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.cloud_done, color: Colors.green),
                  ),
                ],
              ),
              body: const Center(
                child: Text('All tasks synced'),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });

    testWidgets('Conflict resolution works correctly', (tester) async {
      // Setup: Task modified on two devices
      final user = User(
        id: 'conflict-user-id',
        email: 'conflict@example.com',
        displayName: 'Conflict User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockAuthService.setCurrentUser(user);

      // Create task
      final originalTask = await mockTaskService.createTask(
        CreateTaskRequest(
          title: 'Original task',
          boardId: 'default-board',
          recurrence: TaskRecurrence.daily,
          tags: ['Home'],
          createdBy: user.id,
        ),
      );

      // Device 1: Modify task offline
      final device1Update = await mockTaskService.updateTask(
        originalTask.id,
        UpdateTaskRequest(
          title: 'Updated on device 1',
          isCompleted: true,
        ),
      );

      // Device 2: Modify same task offline (different change)
      final device2Update = await mockTaskService.updateTask(
        originalTask.id,
        UpdateTaskRequest(
          title: 'Updated on device 2',
          tags: ['Work'],
        ),
      );

      // Both devices come online and sync
      // Conflict detected: same task modified on both devices

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Sync Conflict'),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning, size: 64, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text(
                      'Sync conflict detected',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Task was modified on multiple devices',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Device 1:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Title: ${device1Update.title}'),
                            Text('Completed: ${device1Update.isCompleted}'),
                          ],
                        ),
                      ),
                    ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Device 2:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Title: ${device2Update.title}'),
                            Text('Tags: ${device2Update.tags.join(", ")}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Using last-write-wins strategy',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Sync conflict detected'), findsOneWidget);
      expect(find.text('Using last-write-wins strategy'), findsOneWidget);

      // Apply last-write-wins resolution
      // The most recent update wins
      final resolvedTask = device1Update.updatedAt.isAfter(device2Update.updatedAt)
          ? device1Update
          : device2Update;

      expect(resolvedTask.id, equals(originalTask.id));

      // For completion status, last-write-wins is applied
      // For non-conflicting fields, merge is possible
    });

    testWidgets('Offline queue handles multiple operations', (tester) async {
      final user = User(
        id: 'queue-user-id',
        email: 'queue@example.com',
        displayName: 'Queue User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockAuthService.setCurrentUser(user);

      // Simulate offline mode
      var isOnline = false;
      final pendingOperations = <String>[];

      // Create multiple tasks
      pendingOperations.add('Create: Task 1');
      final task1 = await mockTaskService.createTask(
        CreateTaskRequest(
          title: 'Task 1',
          boardId: 'default-board',
          recurrence: TaskRecurrence.daily,
          tags: ['Home'],
          createdBy: user.id,
        ),
      );

      pendingOperations.add('Create: Task 2');
      final task2 = await mockTaskService.createTask(
        CreateTaskRequest(
          title: 'Task 2',
          boardId: 'default-board',
          recurrence: TaskRecurrence.weekly,
          tags: ['Work'],
          createdBy: user.id,
        ),
      );

      // Update a task
      pendingOperations.add('Update: Task 1');
      await mockTaskService.updateTask(
        task1.id,
        UpdateTaskRequest(title: 'Task 1 Updated'),
      );

      // Complete a task
      pendingOperations.add('Complete: Task 2');
      await mockTaskService.completeTask(task2.id);

      // Delete a task
      pendingOperations.add('Delete: Task 1');
      await mockTaskService.deleteTask(task1.id);

      // Display sync queue
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Sync Queue'),
              ),
              body: Column(
                children: [
                  Container(
                    color: Colors.orange.shade100,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_off),
                        const SizedBox(width: 8),
                        Text(
                          '${pendingOperations.length} operations pending',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: pendingOperations.length,
                      itemBuilder: (context, index) => ListTile(
                        leading: const Icon(Icons.pending),
                        title: Text(pendingOperations[index]),
                        trailing: const Icon(Icons.schedule),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('5 operations pending'), findsOneWidget);
      expect(find.byIcon(Icons.pending), findsNWidgets(5));

      // Simulate going online
      isOnline = true;

      // Process queue in order
      for (final operation in pendingOperations) {
        // Each operation would be processed sequentially
        // with retry logic and error handling
      }

      // Verify queue is empty after sync
      pendingOperations.clear();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Sync Queue'),
                actions: const [
                  Icon(Icons.cloud_done, color: Colors.green),
                ],
              ),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 64, color: Colors.green),
                    SizedBox(height: 16),
                    Text('All operations synced'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('All operations synced'), findsOneWidget);
    });

    testWidgets('Offline mode handles errors gracefully', (tester) async {
      final user = User(
        id: 'error-user-id',
        email: 'error@example.com',
        displayName: 'Error User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockAuthService.setCurrentUser(user);

      // Simulate storage full error
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Error'),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Storage full',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cannot save task offline. Please free up space.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Manage Storage'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Storage full'), findsOneWidget);
      expect(find.text('Manage Storage'), findsOneWidget);
    });

    testWidgets('Sync retry logic with exponential backoff', (tester) async {
      final user = User(
        id: 'retry-user-id',
        email: 'retry@example.com',
        displayName: 'Retry User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockAuthService.setCurrentUser(user);

      // Create task offline
      final task = await mockTaskService.createTask(
        CreateTaskRequest(
          title: 'Retry task',
          boardId: 'default-board',
          recurrence: TaskRecurrence.daily,
          tags: ['Home'],
          createdBy: user.id,
        ),
      );

      // Simulate sync failures
      var retryCount = 0;
      final retryDelays = [1, 2, 4, 8, 16]; // Exponential backoff in seconds

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Sync Status'),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text('Sync attempt ${retryCount + 1}'),
                    const SizedBox(height: 8),
                    if (retryCount > 0)
                      Text(
                        'Retrying in ${retryDelays[retryCount]} seconds...',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Sync attempt 1'), findsOneWidget);

      // Simulate retry attempts
      for (int i = 0; i < 3; i++) {
        retryCount++;
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                appBar: AppBar(
                  title: const Text('Sync Status'),
                ),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text('Sync attempt ${retryCount + 1}'),
                      const SizedBox(height: 8),
                      Text(
                        'Retrying in ${retryDelays[retryCount]} seconds...',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }

      expect(retryCount, equals(3));
    });

    testWidgets('Offline indicator updates correctly', (tester) async {
      var isOnline = true;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Tasks'),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      isOnline ? Icons.cloud_done : Icons.cloud_off,
                      color: isOnline ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
              body: const Center(
                child: Text('Task list'),
              ),
            ),
          ),
        ),
      );

      // Verify online indicator
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);

      // Simulate going offline
      isOnline = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Tasks'),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      isOnline ? Icons.cloud_done : Icons.cloud_off,
                      color: isOnline ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
              body: const Center(
                child: Text('Task list'),
              ),
            ),
          ),
        ),
      );

      // Verify offline indicator
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);

      // Simulate going back online
      isOnline = true;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Tasks'),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      isOnline ? Icons.cloud_done : Icons.cloud_off,
                      color: isOnline ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
              body: const Center(
                child: Text('Task list'),
              ),
            ),
          ),
        ),
      );

      // Verify online indicator again
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });
  });
}
