import '../models/models.dart';

/// Service interface for invitation and referral system
abstract class InvitationService {
  /// Creates an invitation for a new user
  Future<Invitation> createInvitation(String inviterId, String inviterEmail, String inviteeEmail);

  /// Accepts an invitation using invite code
  Future<Invitation> acceptInvitation(String inviteCode, String inviteeId);

  /// Gets invitations sent by a user
  Future<List<Invitation>> getSentInvitations(String userId);

  /// Gets invitations received by a user (by email)
  Future<List<Invitation>> getReceivedInvitations(String email);

  /// Checks if an email already has an account
  Future<bool> isExistingUser(String email);

  /// Tracks task completion for referral bonus
  Future<void> trackTaskCompletion(String userId);

  /// Checks and awards pending referral bonuses
  Future<List<ReferralBonus>> checkAndAwardReferralBonuses(String userId);

  /// Gets referral bonuses for a user (as inviter)
  Future<List<ReferralBonus>> getReferralBonuses(String inviterId);

  /// Gets referral bonus status for a user (as invitee)
  Future<ReferralBonus?> getReferralBonusStatus(String inviteeId);

  /// Generates a unique invite code
  String generateInviteCode();

  /// Validates an invite code format
  bool isValidInviteCode(String code);

  /// Gets invitation by invite code
  Future<Invitation?> getInvitationByCode(String inviteCode);

  /// Cancels an invitation
  Future<Invitation> cancelInvitation(String invitationId);

  /// Watches invitations sent by a user in real-time
  Stream<List<Invitation>> watchSentInvitations(String userId);

  /// Watches referral bonuses for a user in real-time
  Stream<List<ReferralBonus>> watchReferralBonuses(String inviterId);
}