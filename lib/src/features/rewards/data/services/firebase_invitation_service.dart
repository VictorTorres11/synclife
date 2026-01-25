import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/models.dart';
import '../../domain/services/services.dart';
import '../../../gamification/domain/services/services.dart';
import '../../../auth/domain/services/services.dart';

/// Firebase implementation of InvitationService
class FirebaseInvitationService implements InvitationService {
  FirebaseInvitationService({
    required FirebaseFirestore firestore,
    required GamificationService gamificationService,
    required AuthService authService,
  }) : _firestore = firestore,
       _gamificationService = gamificationService,
       _authService = authService,
       _uuid = const Uuid(),
       _random = Random();

  final FirebaseFirestore _firestore;
  final GamificationService _gamificationService;
  final AuthService _authService;
  final Uuid _uuid;
  final Random _random;

  static const int defaultReferralBonus = 100; // FluxoCoins
  static const int requiredTasksForBonus = 5;

  CollectionReference<Map<String, dynamic>> get _invitationsCollection =>
      _firestore.collection('invitations');

  CollectionReference<Map<String, dynamic>> get _referralBonusesCollection =>
      _firestore.collection('referralBonuses');

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  @override
  Future<Invitation> createInvitation(String inviterId, String inviterEmail, String inviteeEmail) async {
    try {
      // Check if invitee already has an account
      final isExisting = await isExistingUser(inviteeEmail);
      
      final invitationId = _uuid.v4();
      final inviteCode = generateInviteCode();
      
      final invitation = Invitation(
        id: invitationId,
        inviterId: inviterId,
        inviterEmail: inviterEmail,
        inviteeEmail: inviteeEmail,
        inviteCode: inviteCode,
        status: InvitationStatus.pending,
        createdAt: DateTime.now(),
        bonusAmount: isExisting ? 0 : defaultReferralBonus,
      );

      await _invitationsCollection.doc(invitationId).set(invitation.toMap());
      return invitation;
    } catch (e) {
      throw Exception('Failed to create invitation: $e');
    }
  }

  @override
  Future<Invitation> acceptInvitation(String inviteCode, String inviteeId) async {
    try {
      return await _firestore.runTransaction<Invitation>((transaction) async {
        // Get invitation by code
        final invitationQuery = await _invitationsCollection
            .where('inviteCode', isEqualTo: inviteCode)
            .where('status', isEqualTo: InvitationStatus.pending.name)
            .limit(1)
            .get();

        if (invitationQuery.docs.isEmpty) {
          throw Exception('Invalid or expired invite code');
        }

        final invitationDoc = invitationQuery.docs.first;
        final invitation = Invitation.fromMap(invitationDoc.data());

        // Update invitation status
        final acceptedInvitation = invitation.copyWith(
          status: InvitationStatus.accepted,
          acceptedAt: DateTime.now(),
        );

        transaction.update(invitationDoc.reference, acceptedInvitation.toMap());

        // If this is a new user invitation (has bonus), create referral bonus tracking
        if (invitation.bonusAmount > 0) {
          final referralBonusId = _uuid.v4();
          final referralBonus = ReferralBonus(
            id: referralBonusId,
            invitationId: invitation.id,
            inviterId: invitation.inviterId,
            inviteeId: inviteeId,
            status: ReferralBonusStatus.pending,
            bonusAmount: invitation.bonusAmount,
            createdAt: DateTime.now(),
            requiredTasks: requiredTasksForBonus,
          );

          transaction.set(
            _referralBonusesCollection.doc(referralBonusId),
            referralBonus.toMap(),
          );
        }

        return acceptedInvitation;
      });
    } catch (e) {
      throw Exception('Failed to accept invitation: $e');
    }
  }

  @override
  Future<List<Invitation>> getSentInvitations(String userId) async {
    try {
      final querySnapshot = await _invitationsCollection
          .where('inviterId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Invitation.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get sent invitations: $e');
    }
  }

  @override
  Future<List<Invitation>> getReceivedInvitations(String email) async {
    try {
      final querySnapshot = await _invitationsCollection
          .where('inviteeEmail', isEqualTo: email)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Invitation.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get received invitations: $e');
    }
  }

  @override
  Future<bool> isExistingUser(String email) async {
    try {
      final querySnapshot = await _usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      // If we can't check, assume it's a new user to be safe
      return false;
    }
  }

  @override
  Future<void> trackTaskCompletion(String userId) async {
    try {
      // Get pending referral bonus for this user (as invitee)
      final querySnapshot = await _referralBonusesCollection
          .where('inviteeId', isEqualTo: userId)
          .where('status', isEqualTo: ReferralBonusStatus.pending.name)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return; // No pending bonus for this user
      }

      final bonusDoc = querySnapshot.docs.first;
      final bonus = ReferralBonus.fromMap(bonusDoc.data());

      // Increment task completion count
      final updatedBonus = bonus.copyWith(
        tasksCompleted: bonus.tasksCompleted + 1,
      );

      await bonusDoc.reference.update(updatedBonus.toMap());

      // Check if bonus should be awarded
      if (updatedBonus.isReadyForAward) {
        await _awardReferralBonus(updatedBonus);
      }
    } catch (e) {
      // Don't throw here to avoid breaking task completion flow
      print('Failed to track task completion for referral: $e');
    }
  }

  @override
  Future<List<ReferralBonus>> checkAndAwardReferralBonuses(String userId) async {
    try {
      final querySnapshot = await _referralBonusesCollection
          .where('inviterId', isEqualTo: userId)
          .where('status', isEqualTo: ReferralBonusStatus.pending.name)
          .get();

      final awardedBonuses = <ReferralBonus>[];

      for (final doc in querySnapshot.docs) {
        final bonus = ReferralBonus.fromMap(doc.data());
        
        if (bonus.isReadyForAward) {
          final awardedBonus = await _awardReferralBonus(bonus);
          awardedBonuses.add(awardedBonus);
        }
      }

      return awardedBonuses;
    } catch (e) {
      throw Exception('Failed to check and award referral bonuses: $e');
    }
  }

  @override
  Future<List<ReferralBonus>> getReferralBonuses(String inviterId) async {
    try {
      final querySnapshot = await _referralBonusesCollection
          .where('inviterId', isEqualTo: inviterId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ReferralBonus.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get referral bonuses: $e');
    }
  }

  @override
  Future<ReferralBonus?> getReferralBonusStatus(String inviteeId) async {
    try {
      final querySnapshot = await _referralBonusesCollection
          .where('inviteeId', isEqualTo: inviteeId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return ReferralBonus.fromMap(querySnapshot.docs.first.data());
    } catch (e) {
      throw Exception('Failed to get referral bonus status: $e');
    }
  }

  @override
  String generateInviteCode() {
    // Generate a 8-character alphanumeric code
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      Iterable.generate(8, (_) => chars.codeUnitAt(_random.nextInt(chars.length))),
    );
  }

  @override
  bool isValidInviteCode(String code) {
    // Check if code is 8 characters and alphanumeric
    final regex = RegExp(r'^[A-Z0-9]{8}$');
    return regex.hasMatch(code);
  }

  @override
  Future<Invitation?> getInvitationByCode(String inviteCode) async {
    try {
      final querySnapshot = await _invitationsCollection
          .where('inviteCode', isEqualTo: inviteCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return Invitation.fromMap(querySnapshot.docs.first.data());
    } catch (e) {
      throw Exception('Failed to get invitation by code: $e');
    }
  }

  @override
  Future<Invitation> cancelInvitation(String invitationId) async {
    try {
      final doc = await _invitationsCollection.doc(invitationId).get();
      
      if (!doc.exists) {
        throw Exception('Invitation not found');
      }

      final invitation = Invitation.fromMap(doc.data()!);
      final cancelledInvitation = invitation.copyWith(
        status: InvitationStatus.cancelled,
      );

      await _invitationsCollection.doc(invitationId).update(cancelledInvitation.toMap());
      return cancelledInvitation;
    } catch (e) {
      throw Exception('Failed to cancel invitation: $e');
    }
  }

  @override
  Stream<List<Invitation>> watchSentInvitations(String userId) {
    return _invitationsCollection
        .where('inviterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Invitation.fromMap(doc.data()))
            .toList());
  }

  @override
  Stream<List<ReferralBonus>> watchReferralBonuses(String inviterId) {
    return _referralBonusesCollection
        .where('inviterId', isEqualTo: inviterId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReferralBonus.fromMap(doc.data()))
            .toList());
  }

  /// Helper method to award a referral bonus
  Future<ReferralBonus> _awardReferralBonus(ReferralBonus bonus) async {
    try {
      return await _firestore.runTransaction<ReferralBonus>((transaction) async {
        // Award FluxoCoins to inviter
        await _gamificationService.awardFluxoCoins(
          bonus.inviterId,
          bonus.bonusAmount,
          'Referral bonus for inviting new user',
        );

        // Update bonus status
        final awardedBonus = bonus.copyWith(
          status: ReferralBonusStatus.awarded,
          awardedAt: DateTime.now(),
        );

        transaction.update(
          _referralBonusesCollection.doc(bonus.id),
          awardedBonus.toMap(),
        );

        // Update invitation to mark bonus as awarded
        final invitationDoc = await _invitationsCollection.doc(bonus.invitationId).get();
        if (invitationDoc.exists) {
          final invitation = Invitation.fromMap(invitationDoc.data()!);
          final updatedInvitation = invitation.copyWith(bonusAwarded: true);
          transaction.update(invitationDoc.reference, updatedInvitation.toMap());
        }

        return awardedBonus;
      });
    } catch (e) {
      throw Exception('Failed to award referral bonus: $e');
    }
  }
}