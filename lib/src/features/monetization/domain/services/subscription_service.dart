import '../models/models.dart';

/// Service interface for managing user subscriptions and in-app purchases
abstract class SubscriptionService {
  /// Gets the current subscription for a user
  Future<Subscription?> getUserSubscription(String userId);

  /// Initiates a subscription purchase
  Future<Subscription> purchaseSubscription(
      String userId, SubscriptionPlan plan);

  /// Verifies a subscription purchase with the app store
  Future<bool> verifySubscription(String userId, String purchaseToken);

  /// Restores previous purchases for a user
  Future<List<Subscription>> restorePurchases(String userId);

  /// Cancels a subscription
  Future<void> cancelSubscription(String userId);

  /// Updates subscription status (called by server-side verification)
  Future<Subscription> updateSubscriptionStatus(
      String userId, SubscriptionStatus status,
      {DateTime? expiryDate});

  /// Gets user limitations based on subscription status
  Future<UserLimitations> getUserLimitations(String userId);

  /// Updates user limitations when subscription changes
  Future<UserLimitations> updateUserLimitations(
      String userId, SubscriptionPlan plan);

  /// Checks if user can perform an action based on limitations
  Future<bool> canPerformAction(String userId, LimitationType type);

  /// Increments usage counters (tasks, boards, etc.)
  Future<void> incrementUsage(String userId, LimitationType type,
      {int count = 1});

  /// Decrements usage counters (when tasks/boards are deleted)
  Future<void> decrementUsage(String userId, LimitationType type,
      {int count = 1});

  /// Watches subscription changes in real-time
  Stream<Subscription?> watchUserSubscription(String userId);

  /// Watches user limitations changes in real-time
  Stream<UserLimitations> watchUserLimitations(String userId);

  /// Gets available subscription products from the store
  Future<List<SubscriptionProduct>> getAvailableProducts();

  /// Checks if ads should be shown for the user
  Future<bool> shouldShowAds(String userId);
}

/// Represents a subscription product available for purchase
class SubscriptionProduct {
  const SubscriptionProduct({
    required this.id,
    required this.plan,
    required this.title,
    required this.description,
    required this.price,
    required this.currencyCode,
    this.trialPeriod,
    this.billingPeriod = BillingPeriod.monthly,
  });

  final String id;
  final SubscriptionPlan plan;
  final String title;
  final String description;
  final String price;
  final String currencyCode;
  final Duration? trialPeriod;
  final BillingPeriod billingPeriod;
}

/// Billing periods for subscriptions
enum BillingPeriod {
  monthly,
  yearly,
}
