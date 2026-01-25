import 'package:equatable/equatable.dart';
import 'board_type.dart';
import 'board_settings.dart';

/// Represents a board in the SyncLife system
class Board extends Equatable {
  const Board({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.ownerId,
    required this.memberIds,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final BoardType type;
  final String ownerId;
  final List<String> memberIds;
  final BoardSettings settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Creates a Board from Firestore document data
  factory Board.fromMap(Map<String, dynamic> map) => Board(
    id: map['id'] as String,
    name: map['name'] as String,
    description: map['description'] as String?,
    type: BoardType.fromJson(map['type'] as String),
    ownerId: map['ownerId'] as String,
    memberIds: List<String>.from(map['memberIds'] as List),
    settings: BoardSettings.fromMap(map['settings'] as Map<String, dynamic>),
    createdAt: DateTime.parse(map['createdAt'] as String),
    updatedAt: DateTime.parse(map['updatedAt'] as String),
  );

  /// Converts Board to Firestore document data
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type.toJson(),
    'ownerId': ownerId,
    'memberIds': memberIds,
    'settings': settings.toMap(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  Board copyWith({
    String? id,
    String? name,
    String? description,
    BoardType? type,
    String? ownerId,
    List<String>? memberIds,
    BoardSettings? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Board(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    type: type ?? this.type,
    ownerId: ownerId ?? this.ownerId,
    memberIds: memberIds ?? this.memberIds,
    settings: settings ?? this.settings,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    id, name, description, type, ownerId, memberIds, 
    settings, createdAt, updatedAt,
  ];
}