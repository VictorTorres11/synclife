import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../auth/domain/services/auth_service.dart';
import '../../domain/models/task_comment.dart';
import '../../domain/models/create_comment_request.dart';
import '../../domain/services/comment_service.dart';

/// Firebase implementation of CommentService
class FirebaseCommentService implements CommentService {
  FirebaseCommentService({
    FirebaseFirestore? firestore,
    required this.authService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final AuthService authService;

  CollectionReference get _commentsCollection => _firestore.collection('taskComments');

  @override
  Future<List<TaskComment>> getTaskComments(String taskId) async {
    final querySnapshot = await _commentsCollection
        .where('taskId', isEqualTo: taskId)
        .orderBy('createdAt', descending: false)
        .get();

    return querySnapshot.docs
        .map((doc) => TaskComment.fromMap({
              'id': doc.id,
              ...doc.data()! as Map<String, dynamic>,
            }))
        .toList();
  }

  @override
  Future<TaskComment> createComment(CreateCommentRequest request) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Validate that the author is the current user
    if (request.authorId != currentUser.id) {
      throw Exception('Cannot create comment for another user');
    }

    final now = DateTime.now();
    final commentData = {
      'taskId': request.taskId,
      'content': request.content,
      'authorId': request.authorId,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };

    final docRef = await _commentsCollection.add(commentData);
    
    return TaskComment.fromMap({
      'id': docRef.id,
      ...commentData,
    });
  }

  @override
  Future<TaskComment> updateComment(String commentId, String newContent) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Get the existing comment to verify ownership
    final commentDoc = await _commentsCollection.doc(commentId).get();
    if (!commentDoc.exists) {
      throw Exception('Comment not found');
    }

    final commentData = commentDoc.data()! as Map<String, dynamic>;
    final authorId = commentData['authorId'] as String;

    // Only the author can update their comment
    if (authorId != currentUser.id) {
      throw Exception('Permission denied: can only update your own comments');
    }

    final updateData = {
      'content': newContent,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await _commentsCollection.doc(commentId).update(updateData);

    final updatedDoc = await _commentsCollection.doc(commentId).get();
    return TaskComment.fromMap({
      'id': updatedDoc.id,
      ...updatedDoc.data()! as Map<String, dynamic>,
    });
  }

  @override
  Future<void> deleteComment(String commentId) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Get the existing comment to verify ownership
    final commentDoc = await _commentsCollection.doc(commentId).get();
    if (!commentDoc.exists) {
      throw Exception('Comment not found');
    }

    final commentData = commentDoc.data()! as Map<String, dynamic>;
    final authorId = commentData['authorId'] as String;

    // Only the author can delete their comment
    if (authorId != currentUser.id) {
      throw Exception('Permission denied: can only delete your own comments');
    }

    await _commentsCollection.doc(commentId).delete();
  }

  @override
  Stream<List<TaskComment>> watchTaskComments(String taskId) {
    return _commentsCollection
        .where('taskId', isEqualTo: taskId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskComment.fromMap({
                  'id': doc.id,
                  ...doc.data()! as Map<String, dynamic>,
                }))
            .toList());
  }
}