import 'package:equatable/equatable.dart';

/// Represents an achievement in the SyncLife gamification system
class Achievement extends Equatable {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.xpReward,
    required this.fluxoCoinReward,
    required this.iconPath,
    required this.isUnlocked,
    this.unlockedAt,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final int xpReward;
  final int fluxoCoinReward;
  final String iconPath;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  /// Creates an Achievement from Firestore document data
  factory Achievement.fromMap(Map<String, dynamic> map) => Achievement(
    id: map['id'] as String,
    title: map['title'] as String,
    description: map['description'] as String,
    category: map['category'] as String,
    xpReward: map['xpReward'] as int,
    fluxoCoinReward: map['fluxoCoinReward'] as int,
    iconPath: map['iconPath'] as String,
    isUnlocked: map['isUnlocked'] as bool,
    unlockedAt: map['unlockedAt'] != null 
        ? DateTime.parse(map['unlockedAt'] as String)
        : null,
  );

  /// Converts Achievement to Firestore document data
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'xpReward': xpReward,
    'fluxoCoinReward': fluxoCoinReward,
    'iconPath': iconPath,
    'isUnlocked': isUnlocked,
    'unlockedAt': unlockedAt?.toIso8601String(),
  };

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    int? xpReward,
    int? fluxoCoinReward,
    String? iconPath,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) => Achievement(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    category: category ?? this.category,
    xpReward: xpReward ?? this.xpReward,
    fluxoCoinReward: fluxoCoinReward ?? this.fluxoCoinReward,
    iconPath: iconPath ?? this.iconPath,
    isUnlocked: isUnlocked ?? this.isUnlocked,
    unlockedAt: unlockedAt ?? this.unlockedAt,
  );

  @override
  List<Object?> get props => [
    id, title, description, category, xpReward, fluxoCoinReward,
    iconPath, isUnlocked, unlockedAt,
  ];
}