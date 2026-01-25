import 'package:equatable/equatable.dart';

/// Represents an item available for purchase in the FluxoCoins store
class StoreItem extends Equatable {
  const StoreItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.type,
    required this.iconPath,
    required this.isAvailable,
    this.metadata = const {},
  });

  final String id;
  final String name;
  final String description;
  final StoreItemCategory category;
  final int price;
  final StoreItemType type;
  final String iconPath;
  final bool isAvailable;
  final Map<String, dynamic> metadata;

  /// Creates a StoreItem from Firestore document data
  factory StoreItem.fromMap(Map<String, dynamic> map) => StoreItem(
    id: map['id'] as String,
    name: map['name'] as String,
    description: map['description'] as String,
    category: StoreItemCategory.values.firstWhere(
      (e) => e.name == map['category'],
      orElse: () => StoreItemCategory.utility,
    ),
    price: map['price'] as int,
    type: StoreItemType.values.firstWhere(
      (e) => e.name == map['type'],
      orElse: () => StoreItemType.consumable,
    ),
    iconPath: map['iconPath'] as String,
    isAvailable: map['isAvailable'] as bool? ?? true,
    metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? {}),
  );

  /// Converts StoreItem to Firestore document data
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category.name,
    'price': price,
    'type': type.name,
    'iconPath': iconPath,
    'isAvailable': isAvailable,
    'metadata': metadata,
  };

  StoreItem copyWith({
    String? id,
    String? name,
    String? description,
    StoreItemCategory? category,
    int? price,
    StoreItemType? type,
    String? iconPath,
    bool? isAvailable,
    Map<String, dynamic>? metadata,
  }) => StoreItem(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    category: category ?? this.category,
    price: price ?? this.price,
    type: type ?? this.type,
    iconPath: iconPath ?? this.iconPath,
    isAvailable: isAvailable ?? this.isAvailable,
    metadata: metadata ?? this.metadata,
  );

  @override
  List<Object?> get props => [
    id, name, description, category, price, type, iconPath, isAvailable, metadata,
  ];
}

/// Categories of items available in the store
enum StoreItemCategory {
  functional,  // Additional boards, group members, etc.
  visual,      // Themes, avatar icons, achievement sounds
  utility,     // Streak Freeze, task templates, etc.
}

/// Types of store items based on usage
enum StoreItemType {
  consumable,  // One-time use items (Streak Freeze)
  permanent,   // Permanent unlocks (themes, sounds)
  upgrade,     // Feature upgrades (additional boards)
}