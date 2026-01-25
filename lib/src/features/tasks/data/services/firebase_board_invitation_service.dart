import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../auth/domain/models/user.dart';
import '../../domain/models/board_invitation.dart';
import '../../domain/services/board_invitation_service.dart';

/// Firebase implementation of board invitation service
class FirebaseBoardInvitationService implements BoardInvitationService {
  FirebaseBoardInvitationService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference get _invitationsCollection =>
      _firestore.collection('board_invitations');

  CollectionReference get _usersCollection => _firestore.collection('users');

  @override
  Future<BoardInvitation> createBoardInvitation({
    required String boardId,
    required String boardName,
    required String inviterId,
    required String inviterName,
    required String inviterEmail,
    required String inviteeEmail,
    String? message,
    DateTime? expiresAt,
  }) async {
    // Check if email is already invited
    final existingInvite = await isEmailAlreadyInvited(boardId, inviteeEmail);
    if (existingInvite) {
      throw Exception('Este email já foi convidado para este quadro');
    }

    final inviteCode = generateBoardInviteCode();
    final now = DateTime.now();

    final invitation = BoardInvitation(
      id: _invitationsCollection.doc().id,
      boardId: boardId,
      boardName: boardName,
      inviterId: inviterId,
      inviterName: inviterName,
      inviterEmail: inviterEmail,
      inviteeEmail: inviteeEmail,
      inviteCode: inviteCode,
      status: BoardInvitationStatus.pending,
      createdAt: now,
      expiresAt: expiresAt ?? now.add(const Duration(days: 7)),
      message: message,
    );

    await _invitationsCollection.doc(invitation.id).set(invitation.toMap());

    return invitation;
  }

  @override
  Future<BoardInvitation> acceptBoardInvitation(
      String inviteCode, String userId) async {
    final querySnapshot = await _invitationsCollection
        .where('inviteCode', isEqualTo: inviteCode)
        .where('status', isEqualTo: BoardInvitationStatus.pending.name)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('Convite não encontrado ou já processado');
    }

    final doc = querySnapshot.docs.first;
    final invitation =
        BoardInvitation.fromMap(doc.data() as Map<String, dynamic>);

    if (invitation.isExpired) {
      throw Exception('Este convite expirou');
    }

    final updatedInvitation = invitation.copyWith(
      status: BoardInvitationStatus.accepted,
      acceptedAt: DateTime.now(),
    );

    await _invitationsCollection.doc(doc.id).update(updatedInvitation.toMap());

    // Add user to board members (this would be handled by board service)
    // await _addUserToBoard(invitation.boardId, userId);

    return updatedInvitation;
  }

  @override
  Future<BoardInvitation> declineBoardInvitation(String inviteCode) async {
    final querySnapshot = await _invitationsCollection
        .where('inviteCode', isEqualTo: inviteCode)
        .where('status', isEqualTo: BoardInvitationStatus.pending.name)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('Convite não encontrado ou já processado');
    }

    final doc = querySnapshot.docs.first;
    final invitation =
        BoardInvitation.fromMap(doc.data() as Map<String, dynamic>);

    final updatedInvitation = invitation.copyWith(
      status: BoardInvitationStatus.declined,
    );

    await _invitationsCollection.doc(doc.id).update(updatedInvitation.toMap());

    return updatedInvitation;
  }

  @override
  Future<BoardInvitation> cancelBoardInvitation(String invitationId) async {
    final doc = await _invitationsCollection.doc(invitationId).get();

    if (!doc.exists) {
      throw Exception('Convite não encontrado');
    }

    final invitation =
        BoardInvitation.fromMap(doc.data() as Map<String, dynamic>);

    if (invitation.status != BoardInvitationStatus.pending) {
      throw Exception('Apenas convites pendentes podem ser cancelados');
    }

    final updatedInvitation = invitation.copyWith(
      status: BoardInvitationStatus.cancelled,
    );

    await _invitationsCollection
        .doc(invitationId)
        .update(updatedInvitation.toMap());

    return updatedInvitation;
  }

  @override
  Future<List<BoardInvitation>> getBoardInvitations(String boardId) async {
    final querySnapshot = await _invitationsCollection
        .where('boardId', isEqualTo: boardId)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) =>
            BoardInvitation.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<BoardInvitation>> getSentInvitations(String userId) async {
    final querySnapshot = await _invitationsCollection
        .where('inviterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) =>
            BoardInvitation.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<BoardInvitation>> getReceivedInvitations(String email) async {
    final querySnapshot = await _invitationsCollection
        .where('inviteeEmail', isEqualTo: email)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) =>
            BoardInvitation.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<BoardInvitation>> getPendingInvitations(String boardId) async {
    final querySnapshot = await _invitationsCollection
        .where('boardId', isEqualTo: boardId)
        .where('status', isEqualTo: BoardInvitationStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) =>
            BoardInvitation.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<BoardInvitation?> getInvitationByCode(String inviteCode) async {
    final querySnapshot = await _invitationsCollection
        .where('inviteCode', isEqualTo: inviteCode)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    return BoardInvitation.fromMap(
        querySnapshot.docs.first.data() as Map<String, dynamic>);
  }

  @override
  String generateBoardInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  @override
  bool isValidBoardInviteCode(String code) {
    // Check format: 8 characters, alphanumeric uppercase
    final regex = RegExp(r'^[A-Z0-9]{8}$');
    return regex.hasMatch(code);
  }

  @override
  Future<bool> isEmailAlreadyInvited(String boardId, String email) async {
    final querySnapshot = await _invitationsCollection
        .where('boardId', isEqualTo: boardId)
        .where('inviteeEmail', isEqualTo: email)
        .where('status', whereIn: [
          BoardInvitationStatus.pending.name,
          BoardInvitationStatus.accepted.name,
        ])
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  @override
  Future<List<User>> searchUsers(String query) async {
    // Search by email
    final emailQuery = await _usersCollection
        .where('email', isGreaterThanOrEqualTo: query.toLowerCase())
        .where('email', isLessThan: '${query.toLowerCase()}z')
        .limit(10)
        .get();

    // Search by display name
    final nameQuery = await _usersCollection
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThan: '${query}z')
        .limit(10)
        .get();

    final users = <User>[];
    final seenEmails = <String>{};

    // Add email results
    for (final doc in emailQuery.docs) {
      final user = User.fromMap(doc.data() as Map<String, dynamic>);
      if (!seenEmails.contains(user.email)) {
        users.add(user);
        seenEmails.add(user.email);
      }
    }

    // Add name results (avoid duplicates)
    for (final doc in nameQuery.docs) {
      final user = User.fromMap(doc.data() as Map<String, dynamic>);
      if (!seenEmails.contains(user.email)) {
        users.add(user);
        seenEmails.add(user.email);
      }
    }

    return users;
  }

  @override
  Future<List<BoardInvitation>> getInvitationHistory(String boardId) async {
    return getBoardInvitations(boardId);
  }

  @override
  Stream<List<BoardInvitation>> watchBoardInvitations(String boardId) {
    return _invitationsCollection
        .where('boardId', isEqualTo: boardId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                BoardInvitation.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  @override
  Stream<List<BoardInvitation>> watchSentInvitations(String userId) {
    return _invitationsCollection
        .where('inviterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                BoardInvitation.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  @override
  Stream<List<BoardInvitation>> watchReceivedInvitations(String email) {
    return _invitationsCollection
        .where('inviteeEmail', isEqualTo: email)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                BoardInvitation.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  @override
  Future<BoardInvitation> resendInvitation(String invitationId) async {
    final doc = await _invitationsCollection.doc(invitationId).get();

    if (!doc.exists) {
      throw Exception('Convite não encontrado');
    }

    final oldInvitation =
        BoardInvitation.fromMap(doc.data() as Map<String, dynamic>);

    // Cancel old invitation
    await cancelBoardInvitation(invitationId);

    // Create new invitation
    return createBoardInvitation(
      boardId: oldInvitation.boardId,
      boardName: oldInvitation.boardName,
      inviterId: oldInvitation.inviterId,
      inviterName: oldInvitation.inviterName,
      inviterEmail: oldInvitation.inviterEmail,
      inviteeEmail: oldInvitation.inviteeEmail,
      message: oldInvitation.message,
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );
  }

  @override
  Future<List<BoardInvitation>> bulkInviteToBoard({
    required String boardId,
    required String boardName,
    required String inviterId,
    required String inviterName,
    required String inviterEmail,
    required List<String> inviteeEmails,
    String? message,
    DateTime? expiresAt,
  }) async {
    final invitations = <BoardInvitation>[];

    for (final email in inviteeEmails) {
      try {
        final invitation = await createBoardInvitation(
          boardId: boardId,
          boardName: boardName,
          inviterId: inviterId,
          inviterName: inviterName,
          inviterEmail: inviterEmail,
          inviteeEmail: email,
          message: message,
          expiresAt: expiresAt,
        );
        invitations.add(invitation);
      } on Exception catch (e) {
        // Log error but continue with other invitations
        print('Failed to invite $email: $e');
      }
    }

    return invitations;
  }

  @override
  Future<BoardInvitationStats> getInvitationStats(String boardId) async {
    final invitations = await getBoardInvitations(boardId);

    final totalSent = invitations.length;
    final totalAccepted = invitations
        .where((invite) => invite.status == BoardInvitationStatus.accepted)
        .length;
    final totalPending = invitations
        .where((invite) => invite.status == BoardInvitationStatus.pending)
        .length;
    final totalDeclined = invitations
        .where((invite) => invite.status == BoardInvitationStatus.declined)
        .length;
    final totalExpired = invitations
        .where((invite) => invite.status == BoardInvitationStatus.expired)
        .length;
    final totalCancelled = invitations
        .where((invite) => invite.status == BoardInvitationStatus.cancelled)
        .length;

    return BoardInvitationStats(
      totalSent: totalSent,
      totalAccepted: totalAccepted,
      totalPending: totalPending,
      totalDeclined: totalDeclined,
      totalExpired: totalExpired,
      totalCancelled: totalCancelled,
    );
  }
}
