import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/create_task_request.dart';
import '../../domain/models/task.dart';
import '../../domain/models/update_task_request.dart';
import '../../domain/services/task_service.dart';

/// Firebase implementation of TaskService
class FirebaseTaskService implements TaskService {
  FirebaseTaskService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference get _tasksCollection => _firestore.collection('tasks');

  @override
  Future<List<Task>> getTasks(String boardId) async {
    final querySnapshot = await _tasksCollection
        .where('boardId', isEqualTo: boardId)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => Task.fromMap({
              'id': doc.id,
              ...doc.data()! as Map<String, dynamic>,
            }))
        .toList();
  }

  @override
  Future<Task?> getTask(String taskId) async {
    final doc = await _tasksCollection.doc(taskId).get();

    if (!doc.exists) {
      return null;
    }

    return Task.fromMap({
      'id': doc.id,
      ...doc.data()! as Map<String, dynamic>,
    });
  }

  @override
  Future<Task> createTask(CreateTaskRequest request) async {
    final now = DateTime.now();
    final taskData = {
      'title': request.title,
      'description': request.description,
      'boardId': request.boardId,
      'assignedTo': request.assignedTo,
      'recurrence': request.recurrence.toJson(),
      'dueDate': request.dueDate?.toIso8601String(),
      'isCompleted': false,
      'tags': request.tags,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'createdBy': request.createdBy,
    };

    final docRef = await _tasksCollection.add(taskData);

    return Task.fromMap({
      'id': docRef.id,
      ...taskData,
    });
  }

  @override
  Future<Task> updateTask(String taskId, UpdateTaskRequest request) async {
    final now = DateTime.now();
    final updateData = <String, dynamic>{
      'updatedAt': now.toIso8601String(),
    };

    if (request.title != null) updateData['title'] = request.title;
    if (request.description != null)
      updateData['description'] = request.description;
    if (request.assignedTo != null)
      updateData['assignedTo'] = request.assignedTo;
    if (request.recurrence != null)
      updateData['recurrence'] = request.recurrence!.toJson();
    if (request.dueDate != null)
      updateData['dueDate'] = request.dueDate!.toIso8601String();
    if (request.isCompleted != null)
      updateData['isCompleted'] = request.isCompleted;
    if (request.tags != null) updateData['tags'] = request.tags;

    await _tasksCollection.doc(taskId).update(updateData);

    final doc = await _tasksCollection.doc(taskId).get();
    return Task.fromMap({
      'id': doc.id,
      ...doc.data()! as Map<String, dynamic>,
    });
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _tasksCollection.doc(taskId).delete();
  }

  @override
  Future<void> completeTask(String taskId) async {
    await _tasksCollection.doc(taskId).update({
      'isCompleted': true,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Stream<List<Task>> watchTasks(String boardId) {
    return _tasksCollection
        .where('boardId', isEqualTo: boardId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromMap({
                  'id': doc.id,
                  ...doc.data()! as Map<String, dynamic>,
                }))
            .toList());
  }

  @override
  Future<List<Task>> getTasksByUser(String userId) async {
    final querySnapshot = await _tasksCollection
        .where('assignedTo', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => Task.fromMap({
              'id': doc.id,
              ...doc.data()! as Map<String, dynamic>,
            }))
        .toList();
  }

  @override
  Future<List<Task>> getTasksByDateRange(DateTime start, DateTime end) async {
    final querySnapshot = await _tasksCollection
        .where('dueDate', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('dueDate', isLessThanOrEqualTo: end.toIso8601String())
        .orderBy('dueDate')
        .get();

    return querySnapshot.docs
        .map((doc) => Task.fromMap({
              'id': doc.id,
              ...doc.data()! as Map<String, dynamic>,
            }))
        .toList();
  }

  @override
  Future<List<Task>> getTasksByTags(List<String> tags) async {
    final querySnapshot = await _tasksCollection
        .where('tags', arrayContainsAny: tags)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => Task.fromMap({
              'id': doc.id,
              ...doc.data()! as Map<String, dynamic>,
            }))
        .toList();
  }
}
