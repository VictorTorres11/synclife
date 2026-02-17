import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../monetization/domain/models/user_limitations.dart';
import '../../../monetization/domain/services/subscription_service.dart';

/// Service to enforce reminder limitations for free users
/// 
/// This service checks user limitations before allowing reminder creation
/// and manages reminder count tracking in Firestore.
class LimitedReminderService {
  LimitedReminderService({
    required SubscriptionService subscriptionService,
    required FirebaseFirestore firestore,
  })  : _subscriptionService = subscriptionService,
        _firestore = firestore;

  final SubscriptionService _subscriptionService;
  final FirebaseFirestore _firestore;

  /// Check if user can create more reminders
  /// 
  /// Verifies that the user has not exceeded their reminder limit.
  /// Premium users have unlimited reminders (maxReminders = -1).
  /// Free users are limited to 30 reminders by default.
  /// 
  /// Throws [ReminderLimitExceededException] if limit reached
  Future<void> checkReminderLimit(String userId) async {
    final canCreate = await _subscriptionService.canPerformAction(
      userId,
      LimitationType.reminders,
    );

    if (!canCreate) {
      final limitations = await _getUserLimitations(userId);
      throw ReminderLimitExceededException(
        limitationType: LimitationType.reminders,
        currentCount: limitations.currentReminders,
        maxCount: limitations.maxReminders,
      );
    }
  }

  /// Increment reminder count after creation
  /// 
  /// Uses atomic increment operation to ensure consistency in concurrent scenarios.
  /// This is called automatically after a reminder is successfully created.
  Future<void> incrementReminderCount(String userId) async {
    await _subscriptionService.incrementUsage(
      userId,
      LimitationType.reminders,
    );
  }

  /// Decrement reminder count after deletion
  /// 
  /// Uses atomic decrement operation to ensure consistency in concurrent scenarios.
  /// This is called automatically after a reminder is successfully deleted.
  Future<void> decrementReminderCount(String userId) async {
    await _subscriptionService.decrementUsage(
      userId,
      LimitationType.reminders,
    );
  }

  /// Get user limitations from Firestore
  /// 
  /// Returns the user's limitation document, or default free limitations
  /// if the document doesn't exist yet.
  Future<UserLimitations> _getUserLimitations(String userId) async {
    final doc = await _firestore
        .collection('userLimitations')
        .doc(userId)
        .get();
    
    if (!doc.exists) {
      // Return default free limitations if document doesn't exist
      return UserLimitations.defaultFree.copyWith(userId: userId);
    }
    
    return UserLimitations.fromMap(doc.data()!);
  }
}

/// Exception thrown when user exceeds reminder limits
/// 
/// Contains information about the current count, maximum allowed count,
/// and the type of limitation that was exceeded.
class ReminderLimitExceededException implements Exception {
  const ReminderLimitExceededException({
    required this.limitationType,
    required this.currentCount,
    required this.maxCount,
  });

  /// The type of limitation that was exceeded (reminders)
  final LimitationType limitationType;
  
  /// The current count of reminders the user has
  final int currentCount;
  
  /// The maximum number of reminders allowed
  final int maxCount;

  @override
  String toString() =>
      'ReminderLimitExceededException: $currentCount/$maxCount $limitationType';
}
