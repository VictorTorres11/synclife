import 'package:equatable/equatable.dart';

/// Types of scheduled notifications
enum ScheduledNotificationType {
  morningSummary,
  teamActivity,
  nightSummary,
  taskReminder,
}

/// Represents a scheduled notification in the system
class ScheduledNotification extends Equatable {
  const ScheduledNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.scheduledTime,
    required this.data,
    this.isProcessed = false,
    this.processedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final ScheduledNotificationType type;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final Map<String, dynamic> data;
  final bool isProcessed;
  final DateTime? processedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Creates a ScheduledNotification from Firestore document data
  factory ScheduledNotification.fromMap(Map<String, dynamic> map) =>
      ScheduledNotification(
        id: map['id'] as String,
        userId: map['userId'] as String,
        type: ScheduledNotificationType.values.firstWhere(
          (e) => e.name == map['type'] as String,
        ),
        title: map['title'] as String,
        body: map['body'] as String,
        scheduledTime: DateTime.parse(map['scheduledTime'] as String),
        data: Map<String, dynamic>.from(map['data'] as Map),
        isProcessed: map['isProcessed'] as bool? ?? false,
        processedAt: map['processedAt'] != null
            ? DateTime.parse(map['processedAt'] as String)
            : null,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );

  /// Converts ScheduledNotification to Firestore document data
  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'type': type.name,
        'title': title,
        'body': body,
        'scheduledTime': scheduledTime.toIso8601String(),
        'data': data,
        'isProcessed': isProcessed,
        'processedAt': processedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  ScheduledNotification copyWith({
    String? id,
    String? userId,
    ScheduledNotificationType? type,
    String? title,
    String? body,
    DateTime? scheduledTime,
    Map<String, dynamic>? data,
    bool? isProcessed,
    DateTime? processedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      ScheduledNotification(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        type: type ?? this.type,
        title: title ?? this.title,
        body: body ?? this.body,
        scheduledTime: scheduledTime ?? this.scheduledTime,
        data: data ?? this.data,
        isProcessed: isProcessed ?? this.isProcessed,
        processedAt: processedAt ?? this.processedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        title,
        body,
        scheduledTime,
        data,
        isProcessed,
        processedAt,
        createdAt,
        updatedAt,
      ];
}

/// Extension methods for ScheduledNotificationType
extension ScheduledNotificationTypeExtension on ScheduledNotificationType {
  String get displayName {
    switch (this) {
      case ScheduledNotificationType.morningSummary:
        return 'Morning Summary';
      case ScheduledNotificationType.teamActivity:
        return 'Team Activity';
      case ScheduledNotificationType.nightSummary:
        return 'Night Summary';
      case ScheduledNotificationType.taskReminder:
        return 'Task Reminder';
    }
  }

  String get emoji {
    switch (this) {
      case ScheduledNotificationType.morningSummary:
        return '🌅';
      case ScheduledNotificationType.teamActivity:
        return '👥';
      case ScheduledNotificationType.nightSummary:
        return '🌙';
      case ScheduledNotificationType.taskReminder:
        return '⏰';
    }
  }
}
