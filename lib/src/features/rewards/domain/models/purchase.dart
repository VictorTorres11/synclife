import 'package:equatable/equatable.dart';

/// Represents a purchase transaction in the FluxoCoins store
class Purchase extends Equatable {
  const Purchase({
    required this.id,
    required this.userId,
    required this.storeItemId,
    required this.itemName,
    required this.price,
    required this.purchaseDate,
    required this.status,
    this.metadata = const {},
  });

  final String id;
  final String userId;
  final String storeItemId;
  final String itemName;
  final int price;
  final DateTime purchaseDate;
  final PurchaseStatus status;
  final Map<String, dynamic> metadata;

  /// Creates a Purchase from Firestore document data
  factory Purchase.fromMap(Map<String, dynamic> map) => Purchase(
    id: map['id'] as String,
    userId: map['userId'] as String,
    storeItemId: map['storeItemId'] as String,
    itemName: map['itemName'] as String,
    price: map['price'] as int,
    purchaseDate: DateTime.parse(map['purchaseDate'] as String),
    status: PurchaseStatus.values.firstWhere(
      (e) => e.name == map['status'],
      orElse: () => PurchaseStatus.pending,
    ),
    metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? {}),
  );

  /// Converts Purchase to Firestore document data
  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'storeItemId': storeItemId,
    'itemName': itemName,
    'price': price,
    'purchaseDate': purchaseDate.toIso8601String(),
    'status': status.name,
    'metadata': metadata,
  };

  Purchase copyWith({
    String? id,
    String? userId,
    String? storeItemId,
    String? itemName,
    int? price,
    DateTime? purchaseDate,
    PurchaseStatus? status,
    Map<String, dynamic>? metadata,
  }) => Purchase(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    storeItemId: storeItemId ?? this.storeItemId,
    itemName: itemName ?? this.itemName,
    price: price ?? this.price,
    purchaseDate: purchaseDate ?? this.purchaseDate,
    status: status ?? this.status,
    metadata: metadata ?? this.metadata,
  );

  @override
  List<Object?> get props => [
    id, userId, storeItemId, itemName, price, purchaseDate, status, metadata,
  ];
}

/// Status of a purchase transaction
enum PurchaseStatus {
  pending,
  completed,
  failed,
  refunded,
}