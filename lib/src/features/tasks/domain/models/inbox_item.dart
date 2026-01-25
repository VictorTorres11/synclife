import 'package:equatable/equatable.dart';

/// Represents an inbox item (quick note) in the SyncLife system
class InboxItem extends Equatable {
  const InboxItem({
    required this.id,
    required this.content,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String content;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Creates an InboxItem from Firestore document data
  factory InboxItem.fromMap(Map<String, dynamic> map) => InboxItem(
    id: map['id'] as String,
    content: map['content'] as String,
    userId: map['userId'] as String,
    createdAt: DateTime.parse(map['createdAt'] as String),
    updatedAt: DateTime.parse(map['updatedAt'] as String),
  );

  /// Converts InboxItem to Firestore document data
  Map<String, dynamic> toMap() => {
    'id': id,
    'content': content,
    'userId': userId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  InboxItem copyWith({
    String? id,
    String? content,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => InboxItem(
    id: id ?? this.id,
    content: content ?? this.content,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [id, content, userId, createdAt, updatedAt];
}