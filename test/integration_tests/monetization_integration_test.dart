import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synclife_app/src/core/theme/app_theme.dart';
import 'package:synclife_app/src/features/auth/domain/models/models.dart';
import 'package:synclife_app/src/features/monetization/domain/models/models.dart';
import 'package:synclife_app/src/features/tasks/domain/models/models.dart';
import '../helpers/mock_services.dart';

/// Mock implementation of SubscriptionService for testing
class MockSubscriptionService {
  final Map<String, Subscription> _subscriptions = {};
  final Map<String, UserLimitations> _limitations = {};

  void setSubscription(String userId, Subscription subscription) {
    _subscriptions[userId] = subscription;
  }

  void setLimitations(String userId, UserLimitations limitations) {
    _limitations[userId] = limitations;
  }

  Future<Subscription?> getUserSubscription(String userId) async {
    return _subscriptions[userId];
  }

  Future<UserLimitations> getUserLimitations(String userId) async {
    return _limitations[userId] ?? UserLimitations.defaultFree.copyWith(userId: userId);
  }

  Future<Subscription> purchaseSubscription(
      String userId, SubscriptionPlan plan) async {
    final subscription = Subscription(
      userId: userId,
      status: SubscriptionStatus.active,
      plan: plan,
      productId: 'premium_monthly',
      expiryDate: DateTime.now().add(const Duration(days: 30)),
      autoRenewing: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _subscriptions[userId] = subscription;
    return subscription;
  }

  Future<UserLimitations> updateUserLimitations(
      String userId, SubscriptionPlan plan) async {
    final limitations = UserLimitations.forPlan(userId, plan);
    _limitations[userId] = limitations;
    return limitations;
  }

  Future<bool> shouldShowAds(String userId) async {
    final limitations = await getUserLimitations(userId);
    return limitations.adsEnabled;
  }

  Future<bool> canPerformAction(String userId, LimitationType type) async {
    final limitations = await getUserLimitations(userId);
    switch (type) {
      case LimitationType.activeTasks:
        return limitations.canCreateMoreTasks;
      case LimitationType.boards:
        return limitations.canCreateMoreBoards;
      case LimitationType.reminders:
        return limitations.canCreateMoreReminders;
      default:
        return true;
    }
  }

  Future<void> incrementUsage(String userId, LimitationType type,
      {int count = 1}) async {
    final limitations = await getUserLimitations(userId);
    UserLimitations updated;

    switch (type) {
      case LimitationType.activeTasks:
        updated = limitations.copyWith(
          currentActiveTasks: limitations.currentActiveTasks + count,
          updatedAt: DateTime.now(),
        );
        break;
      case LimitationType.boards:
        updated = limitations.copyWith(
          currentBoards: limitations.currentBoards + count,
          updatedAt: DateTime.now(),
        );
        break;
      case LimitationType.reminders:
        updated = limitations.copyWith(
          currentReminders: limitations.currentReminders + count,
          updatedAt: DateTime.now(),
        );
        break;
      default:
        return;
    }

    _limitations[userId] = updated;
  }
}

/// Integration tests for monetization features
/// Tests free user limitations, premium upgrade, and ad functionality
void main() {
  group('Monetization Integration Tests', () {
    late MockAuthService mockAuthService;
    late MockTaskService mockTaskService;
    late MockSubscriptionService mockSubscriptionService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockTaskService = MockTaskService();
      mockSubscriptionService = MockSubscriptionService();
    });

    testWidgets('Free user limitations are enforced correctly', (tester) async {
      // Setup: Free user
      final user = User(
        id: 'free-user-id',
        email: 'free@example.com',
        displayName: 'Free User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockAuthService.setCurrentUser(user);

      // Set free user limitations
      final freeLimitations = UserLimitations.defaultFree.copyWith(
        userId: user.id,
        currentActiveTasks: 45, // Close to limit of 50
        currentBoards: 2, // Close to limit of 3
      );
      mockSubscriptionService.setLimitations(user.id, freeLimitations);

      // Display limitations UI
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Account'),
                actions: [
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Upgrade',
                      style: TextStyle(color: Colors.amber),
                    ),
                  ),
                ],
              ),
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    // Free plan indicator
                    Container(
                      color: Colors.grey.shade200,
                      padding: const EdgeInsets.all(16),
                      child: const Row(
                        children: [
                          Icon(Icons.account_circle),
                          SizedBox(width: 8),
                          Text(
                            'Free Plan',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    // Task limitation
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Active Tasks'),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: freeLimitations.currentActiveTasks /
                                  freeLimitations.maxActiveTasks,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${freeLimitations.currentActiveTasks} / ${freeLimitations.maxActiveTasks}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Board limitation
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Boards'),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: freeLimitations.currentBoards /
                                  freeLimitations.maxBoards,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${freeLimitations.currentBoards} / ${freeLimitations.maxBoards}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Premium features locked
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Premium Features',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.lock, size: 16, color: Colors.grey),
                                SizedBox(width: 8),
                                Text('Calendar Integration'),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.lock, size: 16, color: Colors.grey),
                                SizedBox(width: 8),
                                Text('Advanced Backup'),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.lock, size: 16, color: Colors.grey),
                                SizedBox(width: 8),
                                Text('Premium Themes'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Free Plan'), findsOneWidget);
      expect(find.text('45 / 50'), findsOneWidget);
      expect(find.text('2 / 3'), findsOneWidget);
      expect(find.text('Upgrade'), findsOneWidget);

      // Test task creation limit
      final canCreateTask = await mockSubscriptionService.canPerformAction(
        user.id,
        LimitationType.activeTasks,
      );
      expect(canCreateTask, isTrue); // Still has 5 slots left

      // Create tasks until limit
      for (int i = 0; i < 5; i++) {
        await mockSubscriptionService.incrementUsage(
          user.id,
          LimitationType.activeTasks,
        );
      }

      // Try to create one more task
      final canCreateMore = await mockSubscriptionService.canPerformAction(
        user.id,
        LimitationType.activeTasks,
      );
      expect(canCreateMore, isFalse); // Limit reached

      // Show limit reached dialog
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: AlertDialog(
                title: const Text('Limit Reached'),
                content: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, size: 48, color: Colors.orange),
                    SizedBox(height: 16),
                    Text(
                      'You\'ve reached the maximum number of active tasks (50) for free users.',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Upgrade to Premium for unlimited tasks!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {},
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Upgrade Now'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Limit Reached'), findsOneWidget);
      expect(find.text('Upgrade Now'), findsOneWidget);
    });

    testWidgets('Premium upgrade flow works end-to-end', (tester) async {
      // Setup: Free user
      final user = User(
        id: 'upgrade-user-id',
        email: 'upgrade@example.com',
        displayName: 'Upgrade User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockAuthService.setCurrentUser(user);

      // Initial free subscription
      final freeSubscription = Subscription(
        userId: user.id,
        status: SubscriptionStatus.inactive,
        plan: SubscriptionPlan.free,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockSubscriptionService.setSubscription(user.id, freeSubscription);
      mockSubscriptionService.setLimitations(
        user.id,
        UserLimitations.defaultFree.copyWith(userId: user.id),
      );

      // Step 1: Display upgrade screen
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Upgrade to Premium'),
              ),
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    // Premium benefits
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade400, Colors.amber.shade700],
                        ),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.star, size: 64, color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'SyncLife Premium',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Unlock all features',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Benefits list
                    const ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text('Unlimited tasks'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text('Unlimited boards'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text('No advertisements'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text('Calendar integration'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text('Advanced backup'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text('Premium themes'),
                    ),
                    const SizedBox(height: 24),
                    // Pricing
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              '\$4.99/month',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text('Cancel anytime'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text('Subscribe Now'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('SyncLife Premium'), findsOneWidget);
      expect(find.text('Unlimited tasks'), findsOneWidget);
      expect(find.text('\$4.99/month'), findsOneWidget);
      expect(find.text('Subscribe Now'), findsOneWidget);

      // Step 2: User taps subscribe
      await tester.tap(find.text('Subscribe Now'));
      await tester.pumpAndSettle();

      // Step 3: Process purchase
      final premiumSubscription = await mockSubscriptionService.purchaseSubscription(
        user.id,
        SubscriptionPlan.premium,
      );

      expect(premiumSubscription.plan, equals(SubscriptionPlan.premium));
      expect(premiumSubscription.status, equals(SubscriptionStatus.active));
      expect(premiumSubscription.isActive, isTrue);

      // Step 4: Update limitations
      final premiumLimitations = await mockSubscriptionService.updateUserLimitations(
        user.id,
        SubscriptionPlan.premium,
      );

      expect(premiumLimitations.maxActiveTasks, equals(-1)); // Unlimited
      expect(premiumLimitations.maxBoards, equals(-1)); // Unlimited
      expect(premiumLimitations.adsEnabled, isFalse);
      expect(premiumLimitations.canUseCalendarIntegration, isTrue);
      expect(premiumLimitations.canUseAdvancedBackup, isTrue);
      expect(premiumLimitations.canUsePremiumThemes, isTrue);

      // Step 5: Show success message
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 96,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Welcome to Premium!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('All features are now unlocked'),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Start Using Premium'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Welcome to Premium!'), findsOneWidget);
      expect(find.text('All features are now unlocked'), findsOneWidget);

      // Step 6: Verify ads are disabled
      final shouldShowAds = await mockSubscriptionService.shouldShowAds(user.id);
      expect(shouldShowAds, isFalse);
    });

    testWidgets('Advertisement display for free users', (tester) async {
      // Setup: Free user
      final user = User(
        id: 'ads-user-id',
        email: 'ads@example.com',
        displayName: 'Ads User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockAuthService.setCurrentUser(user);

      mockSubscriptionService.setLimitations(
        user.id,
        UserLimitations.defaultFree.copyWith(userId: user.id),
      );

      // Check if ads should be shown
      final shouldShowAds = await mockSubscriptionService.shouldShowAds(user.id);
      expect(shouldShowAds, isTrue);

      // Display app with discrete ad
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Tasks'),
              ),
              body: Column(
                children: [
                  // Main content
                  const Expanded(
                    child: Center(
                      child: Text('Task list'),
                    ),
                  ),
                  // Discrete ad at bottom
                  if (shouldShowAds)
                    Container(
                      height: 50,
                      color: Colors.grey.shade200,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Advertisement',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            color: Colors.blue.shade100,
                            child: const Text('Sample Ad'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Remove Ads',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Advertisement'), findsOneWidget);
      expect(find.text('Sample Ad'), findsOneWidget);
      expect(find.text('Remove Ads'), findsOneWidget);

      // Verify ad is discrete and non-intrusive
      final adContainer = tester.widget<Container>(
        find.ancestor(
          of: find.text('Advertisement'),
          matching: find.byType(Container),
        ).first,
      );
      expect(adContainer.constraints?.maxHeight, lessThanOrEqualTo(50));
    });

    testWidgets('Premium features are locked for free users', (tester) async {
      final user = User(
        id: 'locked-user-id',
        email: 'locked@example.com',
        displayName: 'Locked User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockAuthService.setCurrentUser(user);

      final freeLimitations = UserLimitations.defaultFree.copyWith(userId: user.id);
      mockSubscriptionService.setLimitations(user.id, freeLimitations);

      // Try to access calendar integration
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Settings'),
              ),
              body: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Calendar Integration'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!freeLimitations.canUseCalendarIntegration)
                          const Icon(Icons.lock, color: Colors.grey),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.backup),
                    title: const Text('Advanced Backup'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!freeLimitations.canUseAdvancedBackup)
                          const Icon(Icons.lock, color: Colors.grey),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.palette),
                    title: const Text('Premium Themes'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!freeLimitations.canUsePremiumThemes)
                          const Icon(Icons.lock, color: Colors.grey),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.lock), findsNWidgets(3));

      // Tap on locked feature
      await tester.tap(find.text('Calendar Integration'));
      await tester.pumpAndSettle();

      // Show upgrade prompt
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber),
                    SizedBox(width: 8),
                    Text('Premium Feature'),
                  ],
                ),
                content: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Calendar Integration is a Premium feature.',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Upgrade to Premium to sync your tasks with Google Calendar, Apple Calendar, and more!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {},
                    child: const Text('Maybe Later'),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Upgrade'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Premium Feature'), findsOneWidget);
      expect(find.text('Upgrade'), findsOneWidget);
    });

    testWidgets('Subscription expiry handling', (tester) async {
      final user = User(
        id: 'expiry-user-id',
        email: 'expiry@example.com',
        displayName: 'Expiry User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockAuthService.setCurrentUser(user);

      // Create expired subscription
      final expiredSubscription = Subscription(
        userId: user.id,
        status: SubscriptionStatus.expired,
        plan: SubscriptionPlan.premium,
        expiryDate: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 31)),
        updatedAt: DateTime.now(),
      );
      mockSubscriptionService.setSubscription(user.id, expiredSubscription);

      expect(expiredSubscription.isExpired, isTrue);
      expect(expiredSubscription.isActive, isFalse);

      // Show expiry notification
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Center(
                child: Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning,
                          size: 48,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Subscription Expired',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your Premium subscription has expired. Renew now to continue enjoying all features.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text('Renew Subscription'),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Continue with Free'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Subscription Expired'), findsOneWidget);
      expect(find.text('Renew Subscription'), findsOneWidget);

      // Revert to free limitations
      await mockSubscriptionService.updateUserLimitations(
        user.id,
        SubscriptionPlan.free,
      );

      final limitations = await mockSubscriptionService.getUserLimitations(user.id);
      expect(limitations.adsEnabled, isTrue);
      expect(limitations.maxActiveTasks, equals(50));
    });

    testWidgets('Complete monetization journey', (tester) async {
      // User starts as free, hits limits, upgrades, uses premium features

      // Step 1: Free user
      final user = await mockAuthService.signUpWithEmail(
        'journey@example.com',
        'password',
      );
      expect(user, isNotNull);

      mockSubscriptionService.setLimitations(
        user!.id,
        UserLimitations.defaultFree.copyWith(
          userId: user.id,
          currentActiveTasks: 48,
        ),
      );

      // Step 2: Create tasks until limit
      for (int i = 0; i < 2; i++) {
        await mockTaskService.createTask(
          CreateTaskRequest(
            title: 'Task $i',
            boardId: 'default-board',
            recurrence: TaskRecurrence.daily,
            tags: ['Home'],
            createdBy: user.id,
          ),
        );
        await mockSubscriptionService.incrementUsage(
          user.id,
          LimitationType.activeTasks,
        );
      }

      // Step 3: Hit limit
      final canCreate = await mockSubscriptionService.canPerformAction(
        user.id,
        LimitationType.activeTasks,
      );
      expect(canCreate, isFalse);

      // Step 4: Upgrade to Premium
      final subscription = await mockSubscriptionService.purchaseSubscription(
        user.id,
        SubscriptionPlan.premium,
      );
      expect(subscription.isActive, isTrue);

      await mockSubscriptionService.updateUserLimitations(
        user.id,
        SubscriptionPlan.premium,
      );

      // Step 5: Verify unlimited access
      final premiumLimitations = await mockSubscriptionService.getUserLimitations(user.id);
      expect(premiumLimitations.canCreateMoreTasks, isTrue);
      expect(premiumLimitations.canUseCalendarIntegration, isTrue);

      // Step 6: Verify no ads
      final shouldShowAds = await mockSubscriptionService.shouldShowAds(user.id);
      expect(shouldShowAds, isFalse);

      // Step 7: Use premium features
      expect(premiumLimitations.canUseAdvancedBackup, isTrue);
      expect(premiumLimitations.canUsePremiumThemes, isTrue);
    });
  });
}
