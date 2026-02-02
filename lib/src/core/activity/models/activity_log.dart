import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum ActivityType {
  taskCreated,
  taskCompleted,
  taskUpdated,
  taskDeleted,
  boardCreated,
  boardUpdated,
  achievementUnlocked,
  streakMaintained,
  rewardPurchased,
  profileUpdated,
  loginActivity,
}

class ActivityLog extends Equatable {
  const ActivityLog({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.metadata = const {},
    this.relatedEntityId,
  });

  final String id;
  final String userId;
  final ActivityType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final String? relatedEntityId;

  // Helper getters for UI display
  IconData get icon {
    switch (type) {
      case ActivityType.taskCreated:
        return Icons.add_circle;
      case ActivityType.taskCompleted:
        return Icons.task_alt;
      case ActivityType.taskUpdated:
        return Icons.edit;
      case ActivityType.taskDeleted:
        return Icons.delete;
      case ActivityType.boardCreated:
        return Icons.dashboard;
      case ActivityType.boardUpdated:
        return Icons.edit;
      case ActivityType.achievementUnlocked:
        return Icons.emoji_events;
      case ActivityType.streakMaintained:
        return Icons.local_fire_department;
      case ActivityType.rewardPurchased:
        return Icons.shopping_bag;
      case ActivityType.profileUpdated:
        return Icons.person;
      case ActivityType.loginActivity:
        return Icons.login;
    }
  }

  Color get color {
    switch (type) {
      case ActivityType.taskCreated:
        return Colors.blue;
      case ActivityType.taskCompleted:
        return Colors.green;
      case ActivityType.taskUpdated:
        return Colors.orange;
      case ActivityType.taskDeleted:
        return Colors.red;
      case ActivityType.boardCreated:
        return Colors.teal;
      case ActivityType.boardUpdated:
        return Colors.indigo;
      case ActivityType.achievementUnlocked:
        return Colors.amber;
      case ActivityType.streakMaintained:
        return Colors.deepOrange;
      case ActivityType.rewardPurchased:
        return Colors.purple;
      case ActivityType.profileUpdated:
        return Colors.cyan;
      case ActivityType.loginActivity:
        return Colors.grey;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Agora mesmo';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min atrás';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h atrás';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d atrás';
    } else {
      return '${difference.inDays ~/ 7}sem atrás';
    }
  }

  factory ActivityLog.fromMap(Map<String, dynamic> map) {
    return ActivityLog(
      id: map['id'] as String,
      userId: map['userId'] as String,
      type: ActivityType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ActivityType.taskCreated,
      ),
      title: map['title'] as String,
      description: map['description'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      relatedEntityId: map['relatedEntityId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'relatedEntityId': relatedEntityId,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        title,
        description,
        timestamp,
        metadata,
        relatedEntityId,
      ];
}