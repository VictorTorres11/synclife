import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../auth/domain/models/user.dart';
import '../../../auth/domain/services/auth_service.dart';
import '../../domain/models/board.dart';
import '../../domain/models/board_settings.dart';
import '../../domain/models/create_board_request.dart';
import '../../domain/services/board_service.dart';

/// Firebase implementation of BoardService
class FirebaseBoardService implements BoardService {
  FirebaseBoardService({
    FirebaseFirestore? firestore,
    required this.authService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final AuthService authService;

  CollectionReference get _boardsCollection => _firestore.collection('boards');
  CollectionReference get _invitesCollection => _firestore.collection('invites');
  CollectionReference get _usersCollection => _firestore.collection('users');

  @override
  Future<List<Board>> getUserBoards() async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }
    
    final querySnapshot = await _boardsCollection
        .where('memberIds', arrayContains: currentUser.id)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => Board.fromMap({
              'id': doc.id,
              ...doc.data()! as Map<String, dynamic>,
            }))
        .toList();
  }

  @override
  Future<Board> createBoard(CreateBoardRequest request) async {
    final now = DateTime.now();
    final boardData = {
      'name': request.name,
      'description': request.description,
      'type': request.type.toJson(),
      'ownerId': request.ownerId,
      'memberIds': [request.ownerId], // Owner is always a member
      'settings': (request.settings ?? const BoardSettings()).toMap(),
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };

    final docRef = await _boardsCollection.add(boardData);
    
    return Board.fromMap({
      'id': docRef.id,
      ...boardData,
    });
  }

  @override
  Future<String> generateInviteLink(String boardId) async {
    // Generate a unique invite code
    final inviteCode = _generateInviteCode();
    
    await _invitesCollection.doc(inviteCode).set({
      'boardId': boardId,
      'createdAt': DateTime.now().toIso8601String(),
      'expiresAt': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
    });

    // Return a deep link URL - in production this would be the actual app URL
    return 'https://synclife.app/invite/$inviteCode';
  }

  @override
  Future<void> joinBoard(String inviteCode) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }
    
    final inviteDoc = await _invitesCollection.doc(inviteCode).get();
    if (!inviteDoc.exists) {
      throw Exception('Invalid invite code');
    }

    final inviteData = inviteDoc.data()! as Map<String, dynamic>;
    final boardId = inviteData['boardId'] as String;
    final expiresAt = DateTime.parse(inviteData['expiresAt'] as String);

    if (DateTime.now().isAfter(expiresAt)) {
      throw Exception('Invite code has expired');
    }

    // Add user to board members
    await _boardsCollection.doc(boardId).update({
      'memberIds': FieldValue.arrayUnion([currentUser.id]),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Stream<List<Board>> watchUserBoards() {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }
    
    return _boardsCollection
        .where('memberIds', arrayContains: currentUser.id)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Board.fromMap({
                  'id': doc.id,
                  ...doc.data()! as Map<String, dynamic>,
                }))
            .toList());
  }

  @override
  Future<Board?> getBoard(String boardId) async {
    final doc = await _boardsCollection.doc(boardId).get();
    if (!doc.exists) return null;

    return Board.fromMap({
      'id': doc.id,
      ...doc.data()! as Map<String, dynamic>,
    });
  }

  @override
  Future<Board> updateBoard(String boardId, Map<String, dynamic> updates) async {
    final updateData = {
      ...updates,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await _boardsCollection.doc(boardId).update(updateData);

    final doc = await _boardsCollection.doc(boardId).get();
    return Board.fromMap({
      'id': doc.id,
      ...doc.data()! as Map<String, dynamic>,
    });
  }

  @override
  Future<void> leaveBoard(String boardId) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }
    
    await _boardsCollection.doc(boardId).update({
      'memberIds': FieldValue.arrayRemove([currentUser.id]),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> removeMember(String boardId, String userId) async {
    await _boardsCollection.doc(boardId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<List<User>> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final queryLower = query.toLowerCase().trim();
    
    // Search by email (exact match for privacy)
    if (queryLower.contains('@')) {
      final emailQuery = await _usersCollection
          .where('email', isEqualTo: queryLower)
          .limit(10)
          .get();
      
      return emailQuery.docs
          .map((doc) => User.fromMap({
                'id': doc.id,
                ...doc.data()! as Map<String, dynamic>,
              }))
          .toList();
    }
    
    // Search by user ID (exact match)
    try {
      final userDoc = await _usersCollection.doc(queryLower).get();
      if (userDoc.exists) {
        return [
          User.fromMap({
            'id': userDoc.id,
            ...userDoc.data()! as Map<String, dynamic>,
          })
        ];
      }
    } catch (e) {
      // User ID not found, continue with other searches
    }
    
    return [];
  }

  @override
  Future<void> sendDirectInvitation(String boardId, String userEmail) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Check if board exists and user has permission
    final board = await getBoard(boardId);
    if (board == null) {
      throw Exception('Board not found');
    }

    if (board.ownerId != currentUser.id && !board.memberIds.contains(currentUser.id)) {
      throw Exception('Permission denied');
    }

    // Find user by email
    final userQuery = await _usersCollection
        .where('email', isEqualTo: userEmail.toLowerCase())
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      throw Exception('User not found');
    }

    final targetUserId = userQuery.docs.first.id;

    // Check if user is already a member
    if (board.memberIds.contains(targetUserId)) {
      throw Exception('User is already a member of this board');
    }

    // Create a direct invitation record
    await _firestore.collection('directInvitations').add({
      'boardId': boardId,
      'fromUserId': currentUser.id,
      'toUserId': targetUserId,
      'toUserEmail': userEmail.toLowerCase(),
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
      'expiresAt': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
    });

    // In a real implementation, this would trigger a notification
    // For now, we'll just create the invitation record
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        8, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }
}