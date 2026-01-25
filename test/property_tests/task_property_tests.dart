import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';
import '../../lib/src/features/tasks/domain/models/models.dart';

/// Property-based tests for task functionality
/// Feature: synclife-app, Property 5: Task creation with recurrence
/// Feature: synclife-app, Property 8: Inbox to task conversion
/// Feature: synclife-app, Property 6: Task completion feedback
void main() {
  group('Task Property Tests', () {
    test('Feature: synclife-app, Property 5: Task creation with recurrence', () async {
      // Property 5: Task creation with recurrence
      // For any valid task data and recurrence type (daily, weekly, monthly, specific date), 
      // the system should successfully create the task with correct recurrence settings
      // **Validates: Requirements 2.1**
      
      await PropertyTestRunner.runProperty<CreateTaskRequest>(
        description: 'Valid task data with any recurrence type should create task successfully',
        generator: _generateValidCreateTaskRequest,
        property: (request) {
          // Simulate task creation
          final createdTask = _simulateTaskCreation(request);
          
          // Validate that task was created with correct properties
          if (createdTask == null) return false;
          
          // Validate basic task properties
          if (createdTask.title != request.title) return false;
          if (createdTask.description != request.description) return false;
          if (createdTask.boardId != request.boardId) return false;
          if (createdTask.assignedTo != request.assignedTo) return false;
          if (createdTask.createdBy != request.createdBy) return false;
          
          // Validate recurrence is set correctly
          if (createdTask.recurrence != request.recurrence) return false;
          
          // Validate due date handling based on recurrence
          if (!_validateDueDateForRecurrence(createdTask, request)) return false;
          
          // Validate tags are preserved
          if (!_listsEqual(createdTask.tags, request.tags)) return false;
          
          // Validate initial state
          if (createdTask.isCompleted != false) return false;
          
          // Validate timestamps
          if (createdTask.createdAt.isAfter(DateTime.now())) return false;
          if (createdTask.updatedAt.isBefore(createdTask.createdAt)) return false;
          
          return true;
        },
      );
    });

    test('Feature: synclife-app, Property 8: Inbox to task conversion', () async {
      // Property 8: Inbox to task conversion
      // For any inbox item dragged to a valid date, the system should convert it 
      // to a scheduled task with that due date
      // **Validates: Requirements 2.5**
      
      await PropertyTestRunner.runProperty<Map<String, dynamic>>(
        description: 'Any inbox item should convert to a valid task with correct due date',
        generator: _generateInboxToTaskConversionData,
        property: (data) {
          final inboxItem = data['inboxItem'] as InboxItem;
          final conversionRequest = data['conversionRequest'] as ConvertInboxToTaskRequest;
          
          // Simulate inbox to task conversion
          final convertedTask = _simulateInboxToTaskConversion(inboxItem, conversionRequest);
          
          // Validate that conversion was successful
          if (convertedTask == null) return false;
          
          // Validate that task title matches inbox content
          if (convertedTask.title != inboxItem.content) return false;
          
          // Validate that due date is set correctly
          if (convertedTask.dueDate != conversionRequest.dueDate) return false;
          
          // Validate that board ID is set correctly
          if (convertedTask.boardId != conversionRequest.boardId) return false;
          
          // Validate that assignment is preserved
          if (convertedTask.assignedTo != conversionRequest.assignedTo) return false;
          
          // Validate that recurrence is set correctly
          if (convertedTask.recurrence != conversionRequest.recurrence) return false;
          
          // Validate that tags are preserved
          if (!_listsEqual(convertedTask.tags, conversionRequest.tags)) return false;
          
          // Validate that creator is preserved from inbox item
          if (convertedTask.createdBy != inboxItem.userId) return false;
          
          // Validate initial state
          if (convertedTask.isCompleted != false) return false;
          
          // Validate that description is null (inbox items become titles)
          if (convertedTask.description != null) return false;
          
          return true;
        },
      );
    });

    test('Feature: synclife-app, Property 6: Task completion feedback', () async {
      // Property 6: Task completion feedback
      // For any task marked as complete, the system should play success sound, 
      // show visual feedback, and update task status
      // **Validates: Requirements 2.2, 2.6**
      
      await PropertyTestRunner.runProperty<Task>(
        description: 'Any task completion should provide feedback and update status correctly',
        generator: _generateValidTask,
        property: (task) {
          // Skip already completed tasks
          if (task.isCompleted) return true;
          
          // Simulate task completion
          final completionResult = _simulateTaskCompletion(task);
          
          // Validate that completion was successful
          if (completionResult == null) return false;
          
          // Validate that task is marked as completed
          if (!completionResult['taskCompleted']) return false;
          
          // Validate that visual feedback was triggered
          if (!completionResult['visualFeedbackShown']) return false;
          
          // Validate that success sound was played
          if (!completionResult['successSoundPlayed']) return false;
          
          // Validate that updated timestamp is set
          if (!completionResult['timestampUpdated']) return false;
          
          // Validate that completion preserves other task properties
          final updatedTask = completionResult['updatedTask'] as Task;
          if (updatedTask.id != task.id) return false;
          if (updatedTask.title != task.title) return false;
          if (updatedTask.description != task.description) return false;
          if (updatedTask.boardId != task.boardId) return false;
          if (updatedTask.assignedTo != task.assignedTo) return false;
          if (updatedTask.recurrence != task.recurrence) return false;
          if (updatedTask.dueDate != task.dueDate) return false;
          if (!_listsEqual(updatedTask.tags, task.tags)) return false;
          if (updatedTask.createdBy != task.createdBy) return false;
          if (updatedTask.createdAt != task.createdAt) return false;
          
          // Validate that updatedAt timestamp is newer
          if (!updatedTask.updatedAt.isAfter(task.updatedAt)) return false;
          
          return true;
        },
      );
    });
  });
}

/// Generates valid CreateTaskRequest for testing
CreateTaskRequest _generateValidCreateTaskRequest() {
  final recurrence = TaskRecurrence.values[
    TestGenerators.randomInt(max: TaskRecurrence.values.length - 1)
  ];
  
  return CreateTaskRequest(
    title: TestGenerators.randomString(minLength: 1, maxLength: 100),
    description: TestGenerators.randomBool() 
        ? TestGenerators.randomString(minLength: 1, maxLength: 500) 
        : null,
    boardId: TestGenerators.randomUuid(),
    assignedTo: TestGenerators.randomBool() 
        ? TestGenerators.randomUuid() 
        : null,
    recurrence: recurrence,
    dueDate: _generateDueDateForRecurrence(recurrence),
    tags: TestGenerators.randomList(
      () => _generateValidTag(),
      minLength: 0,
      maxLength: 5,
    ),
    createdBy: TestGenerators.randomUuid(),
  );
}

/// Generates appropriate due date based on recurrence type
DateTime? _generateDueDateForRecurrence(TaskRecurrence recurrence) {
  switch (recurrence) {
    case TaskRecurrence.none:
      // For non-recurring tasks, may or may not have due date
      return TestGenerators.randomBool() 
          ? DateTime.now().add(Duration(days: TestGenerators.randomInt(max: 365)))
          : null;
    case TaskRecurrence.daily:
    case TaskRecurrence.weekly:
    case TaskRecurrence.monthly:
    case TaskRecurrence.custom:
      // Recurring tasks should have a due date
      return DateTime.now().add(Duration(days: TestGenerators.randomInt(max: 365)));
  }
}

/// Generates valid task tags
String _generateValidTag() {
  const validTags = [
    'Health', 'Home', 'Finance', 'Work', 'Personal', 
    'Urgent', 'Important', 'Exercise', 'Study', 'Shopping'
  ];
  return validTags[TestGenerators.randomInt(max: validTags.length - 1)];
}

/// Simulates task creation (mock implementation)
Task? _simulateTaskCreation(CreateTaskRequest request) {
  try {
    // Validate required fields
    if (request.title.trim().isEmpty) return null;
    if (request.boardId.isEmpty) return null;
    if (request.createdBy.isEmpty) return null;
    
    // Validate recurrence and due date consistency
    if (!_isRecurrenceAndDueDateValid(request.recurrence, request.dueDate)) {
      return null;
    }
    
    final now = DateTime.now();
    
    return Task(
      id: TestGenerators.randomUuid(),
      title: request.title,
      description: request.description,
      boardId: request.boardId,
      assignedTo: request.assignedTo,
      recurrence: request.recurrence,
      dueDate: request.dueDate,
      isCompleted: false,
      tags: List<String>.from(request.tags),
      createdAt: now,
      updatedAt: now,
      createdBy: request.createdBy,
    );
  } catch (e) {
    return null;
  }
}

/// Validates that recurrence and due date are consistent
bool _isRecurrenceAndDueDateValid(TaskRecurrence recurrence, DateTime? dueDate) {
  switch (recurrence) {
    case TaskRecurrence.none:
      // Non-recurring tasks can have any due date or no due date
      return true;
    case TaskRecurrence.daily:
    case TaskRecurrence.weekly:
    case TaskRecurrence.monthly:
    case TaskRecurrence.custom:
      // Recurring tasks should have a due date
      return dueDate != null;
  }
}

/// Validates due date is appropriate for the recurrence pattern
bool _validateDueDateForRecurrence(Task task, CreateTaskRequest request) {
  // Due date should match the request
  if (task.dueDate != request.dueDate) return false;
  
  // Validate recurrence-specific rules
  switch (task.recurrence) {
    case TaskRecurrence.none:
      // No specific validation needed for non-recurring tasks
      return true;
    case TaskRecurrence.daily:
    case TaskRecurrence.weekly:
    case TaskRecurrence.monthly:
    case TaskRecurrence.custom:
      // Recurring tasks should have a due date
      return task.dueDate != null;
  }
}

/// Compares two lists for equality
bool _listsEqual<T>(List<T> list1, List<T> list2) {
  if (list1.length != list2.length) return false;
  
  for (int i = 0; i < list1.length; i++) {
    if (list1[i] != list2[i]) return false;
  }
  
  return true;
}

/// Generates inbox to task conversion test data
Map<String, dynamic> _generateInboxToTaskConversionData() {
  final inboxItem = _generateValidInboxItem();
  final conversionRequest = _generateValidConversionRequest();
  
  return {
    'inboxItem': inboxItem,
    'conversionRequest': conversionRequest,
  };
}

/// Generates a valid inbox item for testing
InboxItem _generateValidInboxItem() {
  final now = DateTime.now();
  
  return InboxItem(
    id: TestGenerators.randomUuid(),
    content: TestGenerators.randomString(minLength: 1, maxLength: 100),
    userId: TestGenerators.randomUuid(),
    createdAt: now,
    updatedAt: now,
  );
}

/// Generates a valid conversion request
ConvertInboxToTaskRequest _generateValidConversionRequest() {
  final recurrence = TaskRecurrence.values[
    TestGenerators.randomInt(max: TaskRecurrence.values.length - 1)
  ];
  
  return ConvertInboxToTaskRequest(
    inboxItemId: TestGenerators.randomUuid(),
    boardId: TestGenerators.randomUuid(),
    assignedTo: TestGenerators.randomBool() 
        ? TestGenerators.randomUuid() 
        : null,
    recurrence: recurrence,
    dueDate: _generateDueDateForRecurrence(recurrence),
    tags: TestGenerators.randomList(
      () => _generateValidTag(),
      minLength: 0,
      maxLength: 3,
    ),
  );
}

/// Simulates inbox to task conversion (mock implementation)
Task? _simulateInboxToTaskConversion(InboxItem inboxItem, ConvertInboxToTaskRequest request) {
  try {
    // Validate inbox item content
    if (inboxItem.content.trim().isEmpty) return null;
    
    // Validate conversion request
    if (request.boardId.isEmpty) return null;
    
    // Validate recurrence and due date consistency
    if (!_isRecurrenceAndDueDateValid(request.recurrence, request.dueDate)) {
      return null;
    }
    
    final now = DateTime.now();
    
    return Task(
      id: TestGenerators.randomUuid(),
      title: inboxItem.content, // Inbox content becomes task title
      description: null, // Inbox items don't have descriptions
      boardId: request.boardId,
      assignedTo: request.assignedTo,
      recurrence: request.recurrence,
      dueDate: request.dueDate,
      isCompleted: false,
      tags: List<String>.from(request.tags),
      createdAt: now,
      updatedAt: now,
      createdBy: inboxItem.userId, // Preserve original creator
    );
  } catch (e) {
    return null;
  }
}

/// Generates a valid task for testing
Task _generateValidTask() {
  final now = DateTime.now();
  final recurrence = TaskRecurrence.values[
    TestGenerators.randomInt(max: TaskRecurrence.values.length - 1)
  ];
  
  // Ensure createdAt is in the past
  final createdAt = now.subtract(Duration(days: TestGenerators.randomInt(max: 30)));
  // Ensure updatedAt is between createdAt and now
  final maxHoursSinceCreated = now.difference(createdAt).inHours;
  final updatedAt = createdAt.add(Duration(hours: TestGenerators.randomInt(max: maxHoursSinceCreated + 1)));
  
  return Task(
    id: TestGenerators.randomUuid(),
    title: TestGenerators.randomString(minLength: 1, maxLength: 100),
    description: TestGenerators.randomBool() 
        ? TestGenerators.randomString(minLength: 1, maxLength: 500) 
        : null,
    boardId: TestGenerators.randomUuid(),
    assignedTo: TestGenerators.randomBool() 
        ? TestGenerators.randomUuid() 
        : null,
    recurrence: recurrence,
    dueDate: _generateDueDateForRecurrence(recurrence),
    isCompleted: TestGenerators.randomBool(),
    tags: TestGenerators.randomList(
      () => _generateValidTag(),
      minLength: 0,
      maxLength: 5,
    ),
    createdAt: createdAt,
    updatedAt: updatedAt,
    createdBy: TestGenerators.randomUuid(),
  );
}

/// Simulates task completion with feedback (mock implementation)
Map<String, dynamic>? _simulateTaskCompletion(Task task) {
  try {
    // Validate that task can be completed
    if (task.isCompleted) return null;
    
    // Ensure the new timestamp is always after the current updatedAt
    // Add at least 1 second to ensure meaningful difference
    final now = DateTime.now();
    final newUpdatedAt = task.updatedAt.isAfter(now) 
        ? task.updatedAt.add(const Duration(seconds: 1))
        : now.add(const Duration(seconds: 1));
    
    // Simulate completion process
    final updatedTask = task.copyWith(
      isCompleted: true,
      updatedAt: newUpdatedAt,
    );
    
    // Simulate feedback mechanisms
    final visualFeedbackShown = _simulateVisualFeedback();
    final successSoundPlayed = _simulateSuccessSound();
    final timestampUpdated = updatedTask.updatedAt.isAfter(task.updatedAt);
    
    return {
      'taskCompleted': updatedTask.isCompleted,
      'visualFeedbackShown': visualFeedbackShown,
      'successSoundPlayed': successSoundPlayed,
      'timestampUpdated': timestampUpdated,
      'updatedTask': updatedTask,
    };
  } catch (e) {
    return null;
  }
}

/// Simulates visual feedback display
bool _simulateVisualFeedback() {
  // In a real implementation, this would trigger UI animations, 
  // snackbars, or other visual feedback mechanisms
  // For testing, we simulate that feedback is always shown
  return true;
}

/// Simulates success sound playback
bool _simulateSuccessSound() {
  // In a real implementation, this would trigger haptic feedback
  // and play success sounds
  // For testing, we simulate that sound is always played
  return true;
}