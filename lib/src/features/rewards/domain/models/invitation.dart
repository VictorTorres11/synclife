import 'package:equatable/equatable.dart';

/// Represents an invitation sent by a user to another user
class Invitation extends Equatable {
  const Invitation({
    required this.id,
    required this.inviterId,
    required this.inviterEmail,
    required this.inviteeEmail,
    required this.inviteCode,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.bonusAwarded = false,
    this.bonusAmount = 0,
    this.metadata = const {},
  });

  final String id;
  final String inviterId;
  final String inviterEmail;
  final String inviteeEmail;
  final String inviteCode;
  final InvitationStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final bool bonusAwarded;
  final int bonusAmount;
  final Map<String, dynamic> metadata;

  /// Creates an Invitation from Firestore document data
  factory Invitation.fromMap(Map<String, dynamic> map) => Invitation(
    id: map['id'] as String,
    inviterId: map['inviterId'] as String,
    inviterEmail: map['inviterEmail'] as String,
    inviteeEmail: map['inviteeEmail'] as String,
    inviteCode: map['inviteCode'] as String,
    status: InvitationStatus.values.firstWhere(
      (e) => e.name == map['status'],
      orElse: () => InvitationStatus.pending,
    ),
    createdAt: DateTime.parse(map['createdAt'] as String),
    acceptedAt: map['acceptedAt'] != null 
        ? DateTime.parse(map['acceptedAt'] as String)
        : null,
    bonusAwarded: map['bonusAwarded'] as bool? ?? false,
    bonusAmount: map['bonusAmount'] as int? ?? 0,
    metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? {}),
  );

  /// Converts Invitation to Firestore document data
  Map<String, dynamic> toMap() => {
    'id': id,
    'inviterId': inviterId,
    'inviterEmail': inviterEmail,
    'inviteeEmail': inviteeEmail,
    'inviteCode': inviteCode,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'acceptedAt': acceptedAt?.toIso8601String(),
    'bonusAwarded': bonusAwarded,
    'bonusAmount': bonusAmount,
    'metadata': metadata,
  };

  Invitation copyWith({
    String? id,
    String? inviterId,
    String? inviterEmail,
    String? inviteeEmail,
    String? inviteCode,
    InvitationStatus? status,
    DateTime? createdAt,
    DateTime? acceptedAt,
    bool? bonusAwarded,
    int? bonusAmount,
    Map<String, dynamic>? metadata,
  }) => Invitation(
    id: id ?? this.id,
    inviterId: inviterId ?? this.inviterId,
    inviterEmail: inviterEmail ?? this.inviterEmail,
    inviteeEmail: inviteeEmail ?? this.inviteeEmail,
    inviteCode: inviteCode ?? this.inviteCode,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    acceptedAt: acceptedAt ?? this.acceptedAt,
    bonusAwarded: bonusAwarded ?? this.bonusAwarded,
    bonusAmount: bonusAmount ?? this.bonusAmount,
    metadata: metadata ?? this.metadata,
  );

  @override
  List<Object?> get props => [
    id, inviterId, inviterEmail, inviteeEmail, inviteCode, status,
    createdAt, acceptedAt, bonusAwarded, bonusAmount, metadata,
  ];
}

/// Status of an invitation
enum InvitationStatus {
  pending,
  accepted,
  expired,
  cancelled,
}

/// Represents a referral bonus tracking record
class ReferralBonus extends Equatable {
  const ReferralBonus({
    required this.id,
    required this.invitationId,
    required this.inviterId,
    required this.inviteeId,
    required this.status,
    required this.bonusAmount,
    required this.createdAt,
    this.awardedAt,
    this.tasksCompleted = 0,
    this.requiredTasks = 5,
  });

  final String id;
  final String invitationId;
  final String inviterId;
  final String inviteeId;
  final ReferralBonusStatus status;
  final int bonusAmount;
  final DateTime createdAt;
  final DateTime? awardedAt;
  final int tasksCompleted;
  final int requiredTasks;

  /// Creates a ReferralBonus from Firestore document data
  factory ReferralBonus.fromMap(Map<String, dynamic> map) => ReferralBonus(
    id: map['id'] as String,
    invitationId: map['invitationId'] as String,
    inviterId: map['inviterId'] as String,
    inviteeId: map['inviteeId'] as String,
    status: ReferralBonusStatus.values.firstWhere(
      (e) => e.name == map['status'],
      orElse: () => ReferralBonusStatus.pending,
    ),
    bonusAmount: map['bonusAmount'] as int,
    createdAt: DateTime.parse(map['createdAt'] as String),
    awardedAt: map['awardedAt'] != null 
        ? DateTime.parse(map['awardedAt'] as String)
        : null,
    tasksCompleted: map['tasksCompleted'] as int? ?? 0,
    requiredTasks: map['requiredTasks'] as int? ?? 5,
  );

  /// Converts ReferralBonus to Firestore document data
  Map<String, dynamic> toMap() => {
    'id': id,
    'invitationId': invitationId,
    'inviterId': inviterId,
    'inviteeId': inviteeId,
    'status': status.name,
    'bonusAmount': bonusAmount,
    'createdAt': createdAt.toIso8601String(),
    'awardedAt': awardedAt?.toIso8601String(),
    'tasksCompleted': tasksCompleted,
    'requiredTasks': requiredTasks,
  };

  /// Checks if the bonus is ready to be awarded
  bool get isReadyForAward => tasksCompleted >= requiredTasks && status == ReferralBonusStatus.pending;

  ReferralBonus copyWith({
    String? id,
    String? invitationId,
    String? inviterId,
    String? inviteeId,
    ReferralBonusStatus? status,
    int? bonusAmount,
    DateTime? createdAt,
    DateTime? awardedAt,
    int? tasksCompleted,
    int? requiredTasks,
  }) => ReferralBonus(
    id: id ?? this.id,
    invitationId: invitationId ?? this.invitationId,
    inviterId: inviterId ?? this.inviterId,
    inviteeId: inviteeId ?? this.inviteeId,
    status: status ?? this.status,
    bonusAmount: bonusAmount ?? this.bonusAmount,
    createdAt: createdAt ?? this.createdAt,
    awardedAt: awardedAt ?? this.awardedAt,
    tasksCompleted: tasksCompleted ?? this.tasksCompleted,
    requiredTasks: requiredTasks ?? this.requiredTasks,
  );

  @override
  List<Object?> get props => [
    id, invitationId, inviterId, inviteeId, status, bonusAmount,
    createdAt, awardedAt, tasksCompleted, requiredTasks,
  ];
}

/// Status of a referral bonus
enum ReferralBonusStatus {
  pending,
  awarded,
  expired,
  cancelled,
}