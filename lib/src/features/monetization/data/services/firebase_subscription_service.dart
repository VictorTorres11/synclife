import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../domain/models/models.dart';
import '../../domain/services/subscription_service.dart';

/// Firebase implementation of SubscriptionService
class FirebaseSubscriptionService implements SubscriptionService {
  FirebaseSubscriptionService({
    FirebaseFirestore? firestore,
    InAppPurchase? inAppPurchase,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  final FirebaseFirestore _firestore;
  final InAppPurchase _inAppPurchase;

  // Product IDs for different platforms
  static const String _premiumMonthlyAndroid = 'synclife_premium_monthly';
  static const String _premiumYearlyAndroid = 'synclife_premium_yearly';
  static const String _premiumMonthlyIOS = 'synclife_premium_monthly';
  static const String _premiumYearlyIOS = 'synclife_premium_yearly';

  @override
  Future<Subscription?> getUserSubscription(String userId) async {
    try {
      final doc =
          await _firestore.collection('subscriptions').doc(userId).get();

      if (!doc.exists) {
        // Create default free subscription
        final freeSubscription = Subscription(
          userId: userId,
          status: SubscriptionStatus.inactive,
          plan: SubscriptionPlan.free,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('subscriptions')
            .doc(userId)
            .set(freeSubscription.toMap());

        return freeSubscription;
      }

      return Subscription.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get user subscription: $e');
    }
  }

  @override
  Future<Subscription> purchaseSubscription(
      String userId, SubscriptionPlan plan) async {
    try {
      // Get available products
      final products = await getAvailableProducts();
      final product = products.firstWhere(
        (p) => p.plan == plan,
        orElse: () => throw Exception('Product not found for plan: $plan'),
      );

      // Get product details from store
      final productDetailsResponse =
          await _inAppPurchase.queryProductDetails({product.id});

      if (productDetailsResponse.error != null) {
        throw Exception(
            'Failed to get product details: ${productDetailsResponse.error}');
      }

      final productDetails = productDetailsResponse.productDetails.first;

      // Create purchase param
      final purchaseParam = PurchaseParam(productDetails: productDetails);

      // Initiate purchase
      final purchaseResult =
          await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

      if (!purchaseResult) {
        throw Exception('Failed to initiate purchase');
      }

      // The actual subscription will be updated via purchase stream listener
      // For now, return a pending subscription
      final subscription = Subscription(
        userId: userId,
        status: SubscriptionStatus.pendingRenewal,
        plan: plan,
        productId: product.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('subscriptions')
          .doc(userId)
          .set(subscription.toMap());

      return subscription;
    } catch (e) {
      throw Exception('Failed to purchase subscription: $e');
    }
  }

  @override
  Future<bool> verifySubscription(String userId, String purchaseToken) async {
    try {
      // In a real implementation, this would call your backend service
      // to verify the purchase with Google Play or App Store

      // For now, we'll simulate verification
      // In production, implement server-side verification

      final subscription = await getUserSubscription(userId);
      if (subscription == null) return false;

      // Update subscription status to active
      final updatedSubscription = subscription.copyWith(
        status: SubscriptionStatus.active,
        purchaseToken: purchaseToken,
        expiryDate: DateTime.now()
            .add(const Duration(days: 30)), // Monthly subscription
        autoRenewing: true,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('subscriptions')
          .doc(userId)
          .update(updatedSubscription.toMap());

      // Update user limitations
      await updateUserLimitations(userId, updatedSubscription.plan);

      return true;
    } catch (e) {
      throw Exception('Failed to verify subscription: $e');
    }
  }

  @override
  Future<List<Subscription>> restorePurchases(String userId) async {
    try {
      await _inAppPurchase.restorePurchases();

      // The restored purchases will be handled by the purchase stream listener
      // For now, return the current subscription
      final subscription = await getUserSubscription(userId);
      return subscription != null ? [subscription] : [];
    } catch (e) {
      throw Exception('Failed to restore purchases: $e');
    }
  }

  @override
  Future<void> cancelSubscription(String userId) async {
    try {
      final subscription = await getUserSubscription(userId);
      if (subscription == null) return;

      final updatedSubscription = subscription.copyWith(
        status: SubscriptionStatus.cancelled,
        autoRenewing: false,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('subscriptions')
          .doc(userId)
          .update(updatedSubscription.toMap());

      // Update user limitations to free plan
      await updateUserLimitations(userId, SubscriptionPlan.free);
    } catch (e) {
      throw Exception('Failed to cancel subscription: $e');
    }
  }

  @override
  Future<Subscription> updateSubscriptionStatus(
      String userId, SubscriptionStatus status,
      {DateTime? expiryDate}) async {
    try {
      final subscription = await getUserSubscription(userId);
      if (subscription == null) {
        throw Exception('Subscription not found for user: $userId');
      }

      final updatedSubscription = subscription.copyWith(
        status: status,
        expiryDate: expiryDate,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('subscriptions')
          .doc(userId)
          .update(updatedSubscription.toMap());

      return updatedSubscription;
    } catch (e) {
      throw Exception('Failed to update subscription status: $e');
    }
  }

  @override
  Future<UserLimitations> getUserLimitations(String userId) async {
    try {
      final doc =
          await _firestore.collection('user_limitations').doc(userId).get();

      if (!doc.exists) {
        // Create default limitations based on subscription
        final subscription = await getUserSubscription(userId);
        final plan = subscription?.effectivePlan ?? SubscriptionPlan.free;
        return await updateUserLimitations(userId, plan);
      }

      return UserLimitations.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get user limitations: $e');
    }
  }

  @override
  Future<UserLimitations> updateUserLimitations(
      String userId, SubscriptionPlan plan) async {
    try {
      final limitations = UserLimitations.forPlan(userId, plan);

      await _firestore
          .collection('user_limitations')
          .doc(userId)
          .set(limitations.toMap());

      return limitations;
    } catch (e) {
      throw Exception('Failed to update user limitations: $e');
    }
  }

  @override
  Future<bool> canPerformAction(String userId, LimitationType type) async {
    try {
      final limitations = await getUserLimitations(userId);

      switch (type) {
        case LimitationType.activeTasks:
          return limitations.canCreateMoreTasks;
        case LimitationType.boards:
          return limitations.canCreateMoreBoards;
        case LimitationType.boardMembers:
          // This would need additional logic to check current board member count
          return limitations.maxBoardMembers == -1 ||
              limitations.maxBoardMembers > 0;
      }
    } catch (e) {
      throw Exception('Failed to check action permission: $e');
    }
  }

  @override
  Future<void> incrementUsage(String userId, LimitationType type,
      {int count = 1}) async {
    try {
      final limitations = await getUserLimitations(userId);

      UserLimitations updatedLimitations;
      switch (type) {
        case LimitationType.activeTasks:
          updatedLimitations = limitations.copyWith(
            currentActiveTasks: limitations.currentActiveTasks + count,
            updatedAt: DateTime.now(),
          );
          break;
        case LimitationType.boards:
          updatedLimitations = limitations.copyWith(
            currentBoards: limitations.currentBoards + count,
            updatedAt: DateTime.now(),
          );
          break;
        case LimitationType.boardMembers:
          // Board members are tracked per board, not globally
          return;
      }

      await _firestore
          .collection('user_limitations')
          .doc(userId)
          .update(updatedLimitations.toMap());
    } catch (e) {
      throw Exception('Failed to increment usage: $e');
    }
  }

  @override
  Future<void> decrementUsage(String userId, LimitationType type,
      {int count = 1}) async {
    try {
      final limitations = await getUserLimitations(userId);

      UserLimitations updatedLimitations;
      switch (type) {
        case LimitationType.activeTasks:
          updatedLimitations = limitations.copyWith(
            currentActiveTasks: (limitations.currentActiveTasks - count)
                .clamp(0, double.infinity)
                .toInt(),
            updatedAt: DateTime.now(),
          );
          break;
        case LimitationType.boards:
          updatedLimitations = limitations.copyWith(
            currentBoards: (limitations.currentBoards - count)
                .clamp(0, double.infinity)
                .toInt(),
            updatedAt: DateTime.now(),
          );
          break;
        case LimitationType.boardMembers:
          // Board members are tracked per board, not globally
          return;
      }

      await _firestore
          .collection('user_limitations')
          .doc(userId)
          .update(updatedLimitations.toMap());
    } catch (e) {
      throw Exception('Failed to decrement usage: $e');
    }
  }

  @override
  Stream<Subscription?> watchUserSubscription(String userId) {
    return _firestore
        .collection('subscriptions')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? Subscription.fromMap(doc.data()!) : null);
  }

  @override
  Stream<UserLimitations> watchUserLimitations(String userId) {
    return _firestore
        .collection('user_limitations')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserLimitations.fromMap(doc.data()!);
      } else {
        // Return default free limitations if not found
        return UserLimitations.forPlan(userId, SubscriptionPlan.free);
      }
    });
  }

  @override
  Future<List<SubscriptionProduct>> getAvailableProducts() async {
    try {
      final products = <SubscriptionProduct>[];

      if (kIsWeb) {
        // For web platform, show demo products
        products.addAll([
          const SubscriptionProduct(
            id: 'synclife_premium_monthly_web',
            plan: SubscriptionPlan.premium,
            title: 'SyncLife Premium Monthly',
            description: 'Unlimited tasks, boards, and premium features',
            price: r'$4.99',
            currencyCode: 'USD',
            billingPeriod: BillingPeriod.monthly,
          ),
          const SubscriptionProduct(
            id: 'synclife_premium_yearly_web',
            plan: SubscriptionPlan.premium,
            title: 'SyncLife Premium Yearly',
            description:
                'Unlimited tasks, boards, and premium features (Save 20%)',
            price: r'$49.99',
            currencyCode: 'USD',
            billingPeriod: BillingPeriod.yearly,
          ),
        ]);
      } else if (Platform.isAndroid) {
        products.addAll([
          const SubscriptionProduct(
            id: _premiumMonthlyAndroid,
            plan: SubscriptionPlan.premium,
            title: 'SyncLife Premium Monthly',
            description: 'Unlimited tasks, boards, and premium features',
            price: r'$4.99',
            currencyCode: 'USD',
            billingPeriod: BillingPeriod.monthly,
          ),
          const SubscriptionProduct(
            id: _premiumYearlyAndroid,
            plan: SubscriptionPlan.premium,
            title: 'SyncLife Premium Yearly',
            description:
                'Unlimited tasks, boards, and premium features (Save 20%)',
            price: r'$49.99',
            currencyCode: 'USD',
            billingPeriod: BillingPeriod.yearly,
          ),
        ]);
      } else if (Platform.isIOS) {
        products.addAll([
          const SubscriptionProduct(
            id: _premiumMonthlyIOS,
            plan: SubscriptionPlan.premium,
            title: 'SyncLife Premium Monthly',
            description: 'Unlimited tasks, boards, and premium features',
            price: r'$4.99',
            currencyCode: 'USD',
            billingPeriod: BillingPeriod.monthly,
          ),
          const SubscriptionProduct(
            id: _premiumYearlyIOS,
            plan: SubscriptionPlan.premium,
            title: 'SyncLife Premium Yearly',
            description:
                'Unlimited tasks, boards, and premium features (Save 20%)',
            price: r'$49.99',
            currencyCode: 'USD',
            billingPeriod: BillingPeriod.yearly,
          ),
        ]);
      }

      return products;
    } catch (e) {
      throw Exception('Failed to get available products: $e');
    }
  }

  @override
  Future<bool> shouldShowAds(String userId) async {
    try {
      final limitations = await getUserLimitations(userId);
      return limitations.adsEnabled;
    } catch (e) {
      // Default to showing ads if there's an error
      return true;
    }
  }
}
