import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/inbox_item.dart';
import '../../domain/models/create_inbox_item_request.dart';
import '../../domain/models/convert_inbox_to_task_request.dart';
import '../../domain/models/task.dart';
import '../../domain/models/create_task_request.dart';
import '../../domain/services/inbox_service.dart';
import '../../domain/services/task_service.dart';

/// Firebase implementation of InboxService
class FirebaseInboxService implements InboxService {
  FirebaseInboxService({
    FirebaseFirestore? firestore,
    required TaskService taskService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _taskService = taskService;

  final FirebaseFirestore _firestore;
  final TaskService _taskService;

  CollectionReference get _inboxCollection => _firestore.collection('inbox');

  @override
  Future<List<InboxItem>> getInboxItems(String userId) async {
    final querySnapshot = await _inboxCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => InboxItem.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }))
        .toList();
  }

  @override
  Future<InboxItem> createInboxItem(CreateInboxItemRequest request) async {
    // Validate content
    if (!validateInboxContent(request.content)) {
      throw ArgumentError('Invalid inbox content');
    }

    final now = DateTime.now();
    final itemData = {
      'content': request.content.trim(),
      'userId': request.userId,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };

    final docRef = await _inboxCollection.add(itemData);
    
    return InboxItem.fromMap({
      'id': docRef.id,
      ...itemData,
    });
  }

  @override
  Future<InboxItem> updateInboxItem(String itemId, String newContent) async {
    // Validate content
    if (!validateInboxContent(newContent)) {
      throw ArgumentError('Invalid inbox content');
    }

    final now = DateTime.now();
    final updateData = {
      'content': newContent.trim(),
      'updatedAt': now.toIso8601String(),
    };

    await _inboxCollection.doc(itemId).update(updateData);

    final doc = await _inboxCollection.doc(itemId).get();
    return InboxItem.fromMap({
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    });
  }

  @override
  Future<void> deleteInboxItem(String itemId) async {
    await _inboxCollection.doc(itemId).delete();
  }

  @override
  Future<Task> convertInboxItemToTask(ConvertInboxToTaskRequest request) async {
    // Get the inbox item
    final inboxDoc = await _inboxCollection.doc(request.inboxItemId).get();
    if (!inboxDoc.exists) {
      throw ArgumentError('Inbox item not found');
    }

    final inboxItem = InboxItem.fromMap({
      'id': inboxDoc.id,
      ...inboxDoc.data() as Map<String, dynamic>,
    });

    // Create task from inbox item
    final createTaskRequest = CreateTaskRequest(
      title: inboxItem.content,
      description: null, // Inbox items become task titles
      boardId: request.boardId,
      assignedTo: request.assignedTo,
      recurrence: request.recurrence,
      dueDate: request.dueDate,
      tags: request.tags,
      createdBy: inboxItem.userId,
    );

    // Create the task
    final task = await _taskService.createTask(createTaskRequest);

    // Delete the inbox item after successful conversion
    await deleteInboxItem(request.inboxItemId);

    return task;
  }

  @override
  Stream<List<InboxItem>> watchInboxItems(String userId) {
    return _inboxCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InboxItem.fromMap({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }))
            .toList());
  }

  @override
  bool validateInboxContent(String content) {
    // Validate that content is not empty or just whitespace
    final trimmedContent = content.trim();
    
    if (trimmedContent.isEmpty) return false;
    
    // Validate length constraints
    if (trimmedContent.length > 500) return false;
    
    // Content should contain at least one non-whitespace character
    if (!RegExp(r'\S').hasMatch(trimmedContent)) return false;
    
    return true;
  }
}