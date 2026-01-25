import 'package:equatable/equatable.dart';

/// Represents a user's subscription status and details
class Subscription extends Equatable {
  const Subscription({
    required this.userId,
    required this.status,
    required this.plan,
    this.productId,
    this.purchaseToken,
    this.originalTransactionId,
    this.expiryDate,
    this.autoRenewing = false,
    this.trialEndDate,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  final String userId;
  final SubscriptionStatus status;
  final SubscriptionPlan plan;
  final String? productId;
  final String? purchaseToken;
  final String? originalTransactionId;
  final DateTime? expiryDate;
  final bool autoRenewing;
  final DateTime? trialEndDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  /// Creates a Subscription from Firestore document data
  factory Subscription.fromMap(Map<String, dynamic> map) => Subscription(
        userId: map['userId'] as String,
        status: SubscriptionStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => SubscriptionStatus.inactive,
        ),
        plan: SubscriptionPlan.values.firstWhere(
          (e) => e.name == map['plan'],
          orElse: () => SubscriptionPlan.free,
        ),
        productId: map['productId'] as String?,
        purchaseToken: map['purchaseToken'] as String?,
        originalTransactionId: map['originalTransactionId'] as String?,
        expiryDate: map['expiryDate'] != null
            ? DateTime.parse(map['expiryDate'] as String)
            : null,
        autoRenewing: map['autoRenewing'] as bool? ?? false,
        trialEndDate: map['trialEndDate'] != null
            ? DateTime.parse(map['trialEndDate'] as String)
            : null,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
        metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? {}),
      );

  /// Converts Subscription to Firestore document data
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'status': status.name,
        'plan': plan.name,
        'productId': productId,
        'purchaseToken': purchaseToken,
        'originalTransactionId': originalTransactionId,
        'expiryDate': expiryDate?.toIso8601String(),
        'autoRenewing': autoRenewing,
        'trialEndDate': trialEndDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'metadata': metadata,
      };

  /// Checks if the subscription is currently active
  bool get isActive {
    if (status != SubscriptionStatus.active) return false;
    if (expiryDate == null) return true;
    return DateTime.now().isBefore(expiryDate!);
  }

  /// Checks if the subscription is in trial period
  bool get isInTrial {
    if (trialEndDate == null) return false;
    return DateTime.now().isBefore(trialEndDate!);
  }

  /// Checks if the subscription has expired
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  /// Gets the effective plan considering trial and expiry
  SubscriptionPlan get effectivePlan {
    if (isActive) return plan;
    return SubscriptionPlan.free;
  }

  Subscription copyWith({
    String? userId,
    SubscriptionStatus? status,
    SubscriptionPlan? plan,
    String? productId,
    String? purchaseToken,
    String? originalTransactionId,
    DateTime? expiryDate,
    bool? autoRenewing,
    DateTime? trialEndDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) =>
      Subscription(
        userId: userId ?? this.userId,
        status: status ?? this.status,
        plan: plan ?? this.plan,
        productId: productId ?? this.productId,
        purchaseToken: purchaseToken ?? this.purchaseToken,
        originalTransactionId:
            originalTransactionId ?? this.originalTransactionId,
        expiryDate: expiryDate ?? this.expiryDate,
        autoRenewing: autoRenewing ?? this.autoRenewing,
        trialEndDate: trialEndDate ?? this.trialEndDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        metadata: metadata ?? this.metadata,
      );

  @override
  List<Object?> get props => [
        userId,
        status,
        plan,
        productId,
        purchaseToken,
        originalTransactionId,
        expiryDate,
        autoRenewing,
        trialEndDate,
        createdAt,
        updatedAt,
        metadata,
      ];
}

/// Status of a subscription
enum SubscriptionStatus {
  inactive,
  active,
  expired,
  cancelled,
  pendingRenewal,
  gracePeriod,
}

/// Available subscription plans
enum SubscriptionPlan {
  free,
  premium,
}
