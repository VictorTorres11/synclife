# SyncLife Monetization Integration Guide

This guide explains how to integrate the monetization features (in-app purchases, ads, and user limitations) into the SyncLife app.

## Overview

The monetization system includes:
- **Premium subscriptions** via Google Play Billing / App Store Connect
- **User limitations** for free users (task/board limits)
- **Discrete advertisements** for free users
- **Subscription verification** and management

## Key Components

### 1. Domain Models

#### Subscription
```dart
class Subscription {
  final String userId;
  final SubscriptionStatus status;
  final SubscriptionPlan plan;
  final DateTime? expiryDate;
  final bool autoRenewing;
  // ... other fields
}
```

#### UserLimitations
```dart
class UserLimitations {
  final int maxActiveTasks;    // 50 for free, -1 for unlimited
  final int maxBoards;         // 3 for free, -1 for unlimited
  final bool adsEnabled;       // true for free, false for premium
  final bool canUseCalendarIntegration;
  // ... other premium features
}
```

### 2. Services

#### SubscriptionService
Manages subscriptions, limitations, and usage tracking:
```dart
abstract class SubscriptionService {
  Future<Subscription?> getUserSubscription(String userId);
  Future<UserLimitations> getUserLimitations(String userId);
  Future<bool> canPerformAction(String userId, LimitationType type);
  Future<void> incrementUsage(String userId, LimitationType type);
  // ... other methods
}
```

#### AdsService
Manages advertisement display:
```dart
abstract class AdsService {
  Future<void> loadBannerAd(String placementId);
  Future<bool> showInterstitialAd(String placementId);
  Future<bool> showRewardedAd(String placementId);
  // ... other methods
}
```

### 3. Service Wrappers

#### LimitedTaskService
Wraps the existing TaskService to enforce limitations:
```dart
class LimitedTaskService implements TaskService {
  @override
  Future<Task> createTask(CreateTaskRequest request) async {
    // Check if user can create more tasks
    final canCreate = await _subscriptionService.canPerformAction(
      request.createdBy, 
      LimitationType.activeTasks,
    );

    if (!canCreate) {
      throw TaskLimitExceededException('Task limit reached');
    }

    // Create task and increment usage
    final task = await _taskService.createTask(request);
    await _subscriptionService.incrementUsage(
      request.createdBy, 
      LimitationType.activeTasks,
    );

    return task;
  }
}
```

## Integration Steps

### 1. Add Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  in_app_purchase: ^3.1.13
  google_mobile_ads: ^5.1.0
```

### 2. Configure Providers

Add to your provider setup:
```dart
// Monetization providers
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return FirebaseSubscriptionService();
});

final adsServiceProvider = Provider<AdsService>((ref) {
  return GoogleAdsService();
});

// Wrap existing services with limitation enforcement
final limitedTaskServiceProvider = Provider<TaskService>((ref) {
  final baseTaskService = ref.watch(taskServiceProvider);
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return LimitedTaskService(
    taskService: baseTaskService,
    subscriptionService: subscriptionService,
  );
});
```

### 3. Initialize Services

In your app initialization:
```dart
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize ads service
    ref.read(adsServiceProvider).initialize();
    
    return MaterialApp(
      // ... app configuration
    );
  }
}
```

### 4. Add UI Components

#### Banner Ads
```dart
// Add to task lists, settings, etc.
const AdBannerWidget(
  placementId: AdPlacements.taskListBanner,
  height: 60,
)
```

#### Limitation Warnings
```dart
// Show warnings when approaching limits
const LimitationWarningWidget(
  limitationType: LimitationType.activeTasks,
)
```

#### Upgrade Prompts
```dart
// Encourage premium upgrades
const UpgradePromptWidget(
  message: 'Upgrade to Premium for unlimited access',
)
```

### 5. Handle Limitations

#### Check Before Actions
```dart
Future<void> createTask() async {
  final canCreate = await ref.read(canPerformActionProvider(
    ActionCheck(userId: userId, type: LimitationType.activeTasks),
  ).future);

  if (!canCreate) {
    // Show upgrade dialog
    _showUpgradeDialog();
    return;
  }

  // Proceed with task creation
  // The LimitedTaskService will handle usage tracking
}
```

#### Show Interstitial Ads
```dart
// Show ads after certain actions (for free users)
Future<void> onTaskCompleted() async {
  final shouldShowAds = await ref.read(shouldShowAdsProvider(userId).future);
  
  if (shouldShowAds) {
    await ref.read(adsServiceProvider).showInterstitialAd(
      AdPlacements.taskCompleteInterstitial,
    );
  }
}
```

## Configuration

### 1. Ad Unit IDs

Update `GoogleAdsService` with your actual ad unit IDs:
```dart
// Replace test IDs with your production IDs
static const String _bannerAdUnitId = Platform.isAndroid
    ? 'ca-app-pub-YOUR_PUBLISHER_ID/banner_android'
    : 'ca-app-pub-YOUR_PUBLISHER_ID/banner_ios';
```

### 2. Subscription Products

Update `FirebaseSubscriptionService` with your product IDs:
```dart
static const String _premiumMonthlyAndroid = 'your_premium_monthly_id';
static const String _premiumYearlyAndroid = 'your_premium_yearly_id';
```

### 3. Free User Limits

Adjust limits in `UserLimitations.defaultFree`:
```dart
static UserLimitations get defaultFree => UserLimitations(
  maxActiveTasks: 50,    // Adjust as needed
  maxBoards: 3,          // Adjust as needed
  maxBoardMembers: 5,    // Adjust as needed
  adsEnabled: true,
  // ... other settings
);
```

## Testing

### Property-Based Tests
The system includes comprehensive property-based tests:
- Premium subscription benefits validation
- Free user limitations enforcement
- Usage counter consistency
- Subscription status logic

Run tests with:
```bash
flutter test test/property_tests/monetization_property_tests.dart
```

### Manual Testing
Use the `MonetizationDemoScreen` to test:
- Limitation enforcement
- Ad display
- Subscription status
- Usage tracking

## Backend Integration

### Purchase Verification
Implement server-side purchase verification:
```dart
// Use PurchaseVerificationService for secure validation
final verificationService = PurchaseVerificationService(
  baseUrl: 'https://your-backend.com/api',
);

final result = await verificationService.verifyAndroidPurchase(
  userId: userId,
  productId: productId,
  purchaseToken: purchaseToken,
  packageName: packageName,
);
```

### Firestore Security Rules
Add rules to protect subscription data:
```javascript
// Allow users to read their own subscription
match /subscriptions/{userId} {
  allow read: if request.auth != null && request.auth.uid == userId;
  allow write: if false; // Only server can write
}

// Allow users to read their own limitations
match /user_limitations/{userId} {
  allow read: if request.auth != null && request.auth.uid == userId;
  allow write: if false; // Only server can write
}
```

## Best Practices

1. **Graceful Degradation**: Always provide fallbacks when services fail
2. **User Experience**: Make limitations clear but not intrusive
3. **Security**: Verify all purchases server-side
4. **Performance**: Cache limitation data to avoid frequent queries
5. **Analytics**: Track conversion rates and user behavior
6. **Compliance**: Follow platform guidelines for ads and subscriptions

## Troubleshooting

### Common Issues

1. **Ads not showing**: Check ad unit IDs and test device configuration
2. **Purchase verification fails**: Ensure backend endpoints are working
3. **Limitations not enforced**: Verify service wrappers are being used
4. **Tests failing**: Check mock configurations and test data generators

### Debug Mode
Enable debug logging:
```dart
// In debug mode, use test ad unit IDs
const bool isDebug = !bool.fromEnvironment('dart.vm.product');
```

## Next Steps

1. **Implement server-side verification** for production security
2. **Add analytics tracking** for monetization metrics
3. **A/B test different limitation values** to optimize conversion
4. **Implement promotional offers** and trial periods
5. **Add subscription management** features (pause, cancel, etc.)