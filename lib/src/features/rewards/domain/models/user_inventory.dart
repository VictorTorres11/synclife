import 'package:equatable/equatable.dart';

/// Represents a user's inventory of purchased items
class UserInventory extends Equatable {
  const UserInventory({
    required this.userId,
    required this.ownedItems,
    required this.activeItems,
    required this.updatedAt,
  });

  final String userId;
  final List<InventoryItem> ownedItems;
  final List<String> activeItems; // IDs of currently active items
  final DateTime updatedAt;

  /// Creates a UserInventory from Firestore document data
  factory UserInventory.fromMap(Map<String, dynamic> map) => UserInventory(
    userId: map['userId'] as String,
    ownedItems: (map['ownedItems'] as List<dynamic>?)
        ?.map((item) => InventoryItem.fromMap(item as Map<String, dynamic>))
        .toList() ?? [],
    activeItems: List<String>.from(map['activeItems'] as List? ?? []),
    updatedAt: DateTime.parse(map['updatedAt'] as String),
  );

  /// Converts UserInventory to Firestore document data
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'ownedItems': ownedItems.map((item) => item.toMap()).toList(),
    'activeItems': activeItems,
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// Creates initial inventory for a new user
  factory UserInventory.initial(String userId) => UserInventory(
    userId: userId,
    ownedItems: const [],
    activeItems: const [],
    updatedAt: DateTime.now(),
  );

  /// Adds an item to the inventory
  UserInventory addItem(InventoryItem item) {
    final newOwnedItems = List<InventoryItem>.from(ownedItems);
    
    // Check if item already exists (for stackable items)
    final existingIndex = newOwnedItems.indexWhere((i) => i.storeItemId == item.storeItemId);
    
    if (existingIndex != -1 && item.isStackable) {
      // Update quantity for stackable items
      newOwnedItems[existingIndex] = newOwnedItems[existingIndex].copyWith(
        quantity: newOwnedItems[existingIndex].quantity + item.quantity,
      );
    } else {
      // Add new item
      newOwnedItems.add(item);
    }

    return copyWith(
      ownedItems: newOwnedItems,
      updatedAt: DateTime.now(),
    );
  }

  /// Activates an item (for themes, sounds, etc.)
  UserInventory activateItem(String storeItemId) {
    final newActiveItems = List<String>.from(activeItems);
    
    if (!newActiveItems.contains(storeItemId)) {
      newActiveItems.add(storeItemId);
    }

    return copyWith(
      activeItems: newActiveItems,
      updatedAt: DateTime.now(),
    );
  }

  /// Consumes an item (reduces quantity by 1)
  UserInventory consumeItem(String storeItemId) {
    final newOwnedItems = List<InventoryItem>.from(ownedItems);
    final itemIndex = newOwnedItems.indexWhere((i) => i.storeItemId == storeItemId);
    
    if (itemIndex != -1) {
      final item = newOwnedItems[itemIndex];
      if (item.quantity > 1) {
        newOwnedItems[itemIndex] = item.copyWith(quantity: item.quantity - 1);
      } else {
        newOwnedItems.removeAt(itemIndex);
      }
    }

    return copyWith(
      ownedItems: newOwnedItems,
      updatedAt: DateTime.now(),
    );
  }

  /// Checks if user owns a specific item
  bool ownsItem(String storeItemId) {
    return ownedItems.any((item) => item.storeItemId == storeItemId);
  }

  /// Gets quantity of a specific item
  int getItemQuantity(String storeItemId) {
    final item = ownedItems.firstWhere(
      (item) => item.storeItemId == storeItemId,
      orElse: () => const InventoryItem(
        storeItemId: '',
        purchaseId: '',
        quantity: 0,
        purchaseDate: null,
        isStackable: false,
      ),
    );
    return item.quantity;
  }

  UserInventory copyWith({
    String? userId,
    List<InventoryItem>? ownedItems,
    List<String>? activeItems,
    DateTime? updatedAt,
  }) => UserInventory(
    userId: userId ?? this.userId,
    ownedItems: ownedItems ?? this.ownedItems,
    activeItems: activeItems ?? this.activeItems,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [userId, ownedItems, activeItems, updatedAt];
}

/// Represents an item in a user's inventory
class InventoryItem extends Equatable {
  const InventoryItem({
    required this.storeItemId,
    required this.purchaseId,
    required this.quantity,
    required this.purchaseDate,
    required this.isStackable,
    this.metadata = const {},
  });

  final String storeItemId;
  final String purchaseId;
  final int quantity;
  final DateTime? purchaseDate;
  final bool isStackable;
  final Map<String, dynamic> metadata;

  /// Creates an InventoryItem from map data
  factory InventoryItem.fromMap(Map<String, dynamic> map) => InventoryItem(
    storeItemId: map['storeItemId'] as String,
    purchaseId: map['purchaseId'] as String,
    quantity: map['quantity'] as int,
    purchaseDate: map['purchaseDate'] != null 
        ? DateTime.parse(map['purchaseDate'] as String)
        : null,
    isStackable: map['isStackable'] as bool? ?? false,
    metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? {}),
  );

  /// Converts InventoryItem to map data
  Map<String, dynamic> toMap() => {
    'storeItemId': storeItemId,
    'purchaseId': purchaseId,
    'quantity': quantity,
    'purchaseDate': purchaseDate?.toIso8601String(),
    'isStackable': isStackable,
    'metadata': metadata,
  };

  InventoryItem copyWith({
    String? storeItemId,
    String? purchaseId,
    int? quantity,
    DateTime? purchaseDate,
    bool? isStackable,
    Map<String, dynamic>? metadata,
  }) => InventoryItem(
    storeItemId: storeItemId ?? this.storeItemId,
    purchaseId: purchaseId ?? this.purchaseId,
    quantity: quantity ?? this.quantity,
    purchaseDate: purchaseDate ?? this.purchaseDate,
    isStackable: isStackable ?? this.isStackable,
    metadata: metadata ?? this.metadata,
  );

  @override
  List<Object?> get props => [
    storeItemId, purchaseId, quantity, purchaseDate, isStackable, metadata,
  ];
}