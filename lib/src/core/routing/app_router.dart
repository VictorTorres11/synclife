import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/screens/privacy_settings_screen.dart';
import '../../features/auth/presentation/screens/language_settings_screen.dart';
import '../../features/dashboard/presentation/screens/home_dashboard_screen.dart';
import '../../features/tasks/presentation/pages/tasks_page.dart';
import '../../features/tasks/presentation/screens/board_management_screen.dart';
import '../../features/notifications/presentation/screens/notification_center_screen.dart';
import '../../features/notifications/presentation/screens/notification_settings_screen.dart';
import '../../features/gamification/presentation/screens/gamification_dashboard_screen.dart';
import '../../features/gamification/presentation/screens/achievements_screen.dart';
import '../../features/monetization/presentation/screens/subscription_screen.dart';
import '../../features/monetization/presentation/screens/premium_features_screen.dart';
import '../../features/rewards/presentation/screens/rewards_store_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) =>
            const ProfileScreen(), // Usar ProfileScreen como settings por enquanto
      ),
      GoRoute(
        path: '/privacy-settings',
        builder: (context, state) => const PrivacySettingsScreen(),
      ),
      GoRoute(
        path: '/language-settings',
        builder: (context, state) => const LanguageSettingsScreen(),
      ),

      // Dashboard route (main home screen)
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeDashboardScreen(),
      ),

      // Tasks routes
      GoRoute(
        path: '/tasks',
        builder: (context, state) => const TasksPage(),
      ),
      GoRoute(
        path: '/boards',
        builder: (context, state) => const BoardManagementScreen(),
      ),

      // Notifications routes
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationCenterScreen(),
      ),
      GoRoute(
        path: '/notification-settings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),

      // Gamification routes
      GoRoute(
        path: '/gamification',
        builder: (context, state) => const GamificationDashboardScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const GamificationDashboardScreen(),
      ),
      GoRoute(
        path: '/achievements',
        builder: (context, state) => const AchievementsScreen(),
      ),

      // Monetization routes
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/premium',
        builder: (context, state) => const PremiumFeaturesScreen(),
      ),

      // Rewards routes
      GoRoute(
        path: '/rewards',
        builder: (context, state) => const RewardsStoreScreen(),
      ),
      GoRoute(
        path: '/store',
        builder: (context, state) => const RewardsStoreScreen(),
      ),

      // Default redirect
      GoRoute(
        path: '/',
        redirect: (context, state) => '/home',
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    ),
  );
});
