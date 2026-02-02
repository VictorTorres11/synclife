import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../auth/domain/services/auth_service.dart';
import '../../domain/models/subtask.dart';
import '../../domain/models/create_subtask_request.dart';
import '../../domain/services/subtask_service.dart';

/// Firebase implementation of SubtaskService
class FirebaseSubtaskService implements SubtaskService {
  FirebaseSubtaskService({
    FirebaseFirestore? firestore,
    required this.authService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final AuthService authService;

  CollectionReference get _subtasksCollection => _firestore.collection('subtasks');

  @override
  Future<List<Subtask>> getSubtasks(String taskId) async {
    final querySnapshot = await _subtasksCollection
        .where('taskId', isEqualTo: taskId)
        .orderBy('order')
        .get();

    return querySnapshot.docs
        .map((doc) => Subtask.fromMap({
              'id': doc.id,
              ...doc.data()! as Map<String, dynamic>,
            }))
        .toList();
  }

  @override
  Future<Subtask> createSubtask(CreateSubtaskRequest request) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Validate that the creator is the current user
    if (request.createdBy != currentUser.id) {
      throw Exception('Cannot create subtask for another user');
    }

    // Get the next order number
    final existingSubtasks = await getSubtasks(request.taskId);
    final nextOrder = existingSubtasks.length;

    final now = DateTime.now();
    final subtaskData = {
      'taskId': request.taskId,
      'title': request.title,
      'description': request.description,
      'isCompleted': false,
      'order': nextOrder,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'createdBy': request.createdBy,
    };

    final docRef = await _subtasksCollection.add(subtaskData);

    return Subtask.fromMap({
      'id': docRef.id,
      ...subtaskData,
    });
  }

  @override
  Future<Subtask> updateSubtask(String subtaskId, {String? title, String? description}) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final updateData = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (title != null) {
      updateData['title'] = title;
    }
    if (description != null) {
      updateData['description'] = description;
    }

    await _subtasksCollection.doc(subtaskId).update(updateData);

    final doc = await _subtasksCollection.doc(subtaskId).get();
    return Subtask.fromMap({
      'id': doc.id,
      ...doc.data()! as Map<String, dynamic>,
    });
  }

  @override
  Future<Subtask> toggleSubtaskCompletion(String subtaskId) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final doc = await _subtasksCollection.doc(subtaskId).get();
    if (!doc.exists) {
      throw Exception('Subtask not found');
    }

    final currentData = doc.data()! as Map<String, dynamic>;
    final isCompleted = currentData['isCompleted'] as bool;

    await _subtasksCollection.doc(subtaskId).update({
      'isCompleted': !isCompleted,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    return Subtask.fromMap({
      'id': doc.id,
      ...currentData,
      'isCompleted': !isCompleted,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> deleteSubtask(String subtaskId) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    await _subtasksCollection.doc(subtaskId).delete();
  }

  @override
  Future<void> reorderSubtasks(String taskId, List<String> subtaskIds) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final batch = _firestore.batch();
    
    for (int i = 0; i < subtaskIds.length; i++) {
      final subtaskRef = _subtasksCollection.doc(subtaskIds[i]);
      batch.update(subtaskRef, {
        'order': i,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }

    await batch.commit();
  }

  @override
  Stream<List<Subtask>> watchSubtasks(String taskId) {
    return _subtasksCollection
        .where('taskId', isEqualTo: taskId)
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Subtask.fromMap({
                'id': doc.id,
                ...doc.data()! as Map<String, dynamic>,
              }))
          .toList();
    });
  }

  @override
  Future<SubtaskStats> getSubtaskStats(String taskId) async {
    final subtasks = await getSubtasks(taskId);
    final completed = subtasks.where((subtask) => subtask.isCompleted).length;
    
    return SubtaskStats(
      total: subtasks.length,
      completed: completed,
    );
  }
}