import 'package:equatable/equatable.dart';
import 'reminder_priority.dart';

/// Represents a reminder in the SyncLife system
/// 
/// Reminders are lightweight notes that can be organized by boards
/// and later converted to full tasks when needed.
class Reminder extends Equatable {
  const Reminder({
    required this.id,
    required this.content,
    required this.userId,
    required this.boardId,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.priority = ReminderPriority.medium,
  });

  /// Unique identifier for the reminder
  final String id;
  
  /// The reminder content/text
  final String content;
  
  /// ID of the user who owns this reminder
  final String userId;
  
  /// ID of the board this reminder belongs to
  final String boardId;
  
  /// Timestamp when the reminder was created
  final DateTime createdAt;
  
  /// Timestamp when the reminder was last updated
  final DateTime updatedAt;
  
  /// Optional list of tags for categorization
  final List<String> tags;
  
  /// Priority level of the reminder (default: medium)
  final ReminderPriority priority;

  /// Creates a Reminder from Firestore document data
  factory Reminder.fromMap(Map<String, dynamic> map) => Reminder(
    id: map['id'] as String,
    content: map['content'] as String,
    userId: map['userId'] as String,
    boardId: map['boardId'] as String,
    createdAt: DateTime.parse(map['createdAt'] as String),
    updatedAt: DateTime.parse(map['updatedAt'] as String),
    tags: List<String>.from(map['tags'] as List? ?? []),
    priority: map['priority'] != null
        ? ReminderPriority.fromJson(map['priority'] as String)
        : ReminderPriority.medium,
  );

  /// Converts Reminder to Firestore document data
  Map<String, dynamic> toMap() => {
    'id': id,
    'content': content,
    'userId': userId,
    'boardId': boardId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'tags': tags,
    'priority': priority.toJson(),
  };

  /// Creates a copy of this Reminder with the given fields replaced
  Reminder copyWith({
    String? id,
    String? content,
    String? userId,
    String? boardId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    ReminderPriority? priority,
  }) => Reminder(
    id: id ?? this.id,
    content: content ?? this.content,
    userId: userId ?? this.userId,
    boardId: boardId ?? this.boardId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    tags: tags ?? this.tags,
    priority: priority ?? this.priority,
  );

  @override
  List<Object?> get props => [
    id,
    content,
    userId,
    boardId,
    createdAt,
    updatedAt,
    tags,
    priority,
  ];
}
