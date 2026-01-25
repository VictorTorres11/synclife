import 'package:equatable/equatable.dart';

/// Represents an invitation to join a board
class BoardInvitation extends Equatable {
  const BoardInvitation({
    required this.id,
    required this.boardId,
    required this.boardName,
    required this.inviterId,
    required this.inviterName,
    required this.inviterEmail,
    required this.inviteeEmail,
    required this.inviteCode,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.expiresAt,
    this.message,
  });

  final String id;
  final String boardId;
  final String boardName;
  final String inviterId;
  final String inviterName;
  final String inviterEmail;
  final String inviteeEmail;
  final String inviteCode;
  final BoardInvitationStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? expiresAt;
  final String? message;

  /// Creates a BoardInvitation from Firestore document data
  factory BoardInvitation.fromMap(Map<String, dynamic> map) => BoardInvitation(
        id: map['id'] as String,
        boardId: map['boardId'] as String,
        boardName: map['boardName'] as String,
        inviterId: map['inviterId'] as String,
        inviterName: map['inviterName'] as String,
        inviterEmail: map['inviterEmail'] as String,
        inviteeEmail: map['inviteeEmail'] as String,
        inviteCode: map['inviteCode'] as String,
        status: BoardInvitationStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => BoardInvitationStatus.pending,
        ),
        createdAt: DateTime.parse(map['createdAt'] as String),
        acceptedAt: map['acceptedAt'] != null
            ? DateTime.parse(map['acceptedAt'] as String)
            : null,
        expiresAt: map['expiresAt'] != null
            ? DateTime.parse(map['expiresAt'] as String)
            : null,
        message: map['message'] as String?,
      );

  /// Converts BoardInvitation to Firestore document data
  Map<String, dynamic> toMap() => {
        'id': id,
        'boardId': boardId,
        'boardName': boardName,
        'inviterId': inviterId,
        'inviterName': inviterName,
        'inviterEmail': inviterEmail,
        'inviteeEmail': inviteeEmail,
        'inviteCode': inviteCode,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'acceptedAt': acceptedAt?.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'message': message,
      };

  /// Checks if the invitation is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Checks if the invitation is still valid
  bool get isValid => status == BoardInvitationStatus.pending && !isExpired;

  BoardInvitation copyWith({
    String? id,
    String? boardId,
    String? boardName,
    String? inviterId,
    String? inviterName,
    String? inviterEmail,
    String? inviteeEmail,
    String? inviteCode,
    BoardInvitationStatus? status,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? expiresAt,
    String? message,
  }) =>
      BoardInvitation(
        id: id ?? this.id,
        boardId: boardId ?? this.boardId,
        boardName: boardName ?? this.boardName,
        inviterId: inviterId ?? this.inviterId,
        inviterName: inviterName ?? this.inviterName,
        inviterEmail: inviterEmail ?? this.inviterEmail,
        inviteeEmail: inviteeEmail ?? this.inviteeEmail,
        inviteCode: inviteCode ?? this.inviteCode,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        acceptedAt: acceptedAt ?? this.acceptedAt,
        expiresAt: expiresAt ?? this.expiresAt,
        message: message ?? this.message,
      );

  @override
  List<Object?> get props => [
        id,
        boardId,
        boardName,
        inviterId,
        inviterName,
        inviterEmail,
        inviteeEmail,
        inviteCode,
        status,
        createdAt,
        acceptedAt,
        expiresAt,
        message,
      ];
}

/// Status of a board invitation
enum BoardInvitationStatus {
  pending,
  accepted,
  declined,
  expired,
  cancelled,
}
