import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/tasks/presentation/pages/tasks_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/tasks',
        builder: (context, state) => const TasksPage(),
      ),
      GoRoute(
        path: '/',
        redirect: (context, state) => '/login',
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
      ),
      GoRoute(
        path: '/tasks',
        builder: (context, state) => const TasksPage(),
        routes: [
          GoRoute(
            path: 'detail/:taskId',
            builder: (context, state) {
              final task = state.extra as Task?;

              if (task == null) {
                // If no task is passed, redirect back to tasks
                return const TasksPage();
              }

              return TaskDetailPage(
                task: task,
                onUpdateTask: (taskId, request) {
                  // TODO(dev): Implement task update logic
                },
                onDeleteTask: (taskId) {
                  // TODO(dev): Implement task delete logic
                },
                availableTags: const [
                  'Health',
                  'Work',
                  'Home',
                  'Finance',
                  'Personal'
                ],
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/boards',
        builder: (context, state) => const BoardManagementScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationCenterScreen(),
      ),
      GoRoute(
        path: '/gamification',
        builder: (context, state) => const GamificationDashboardScreen(),
      ),
      GoRoute(
        path: '/store',
        builder: (context, state) => const RewardsStoreScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: Consumer(
            builder: (context, ref, child) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('Notifications'),
                      subtitle: const Text('Manage notification preferences'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/settings/notifications'),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.language),
                      title: const Text('Language & Region'),
                      subtitle:
                          const Text('Change language and region settings'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/settings/language'),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.privacy_tip),
                      title: const Text('Privacy'),
                      subtitle: const Text('Manage privacy and data settings'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/settings/privacy'),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.storage),
                      title: const Text('Data & Storage'),
                      subtitle: const Text('Manage app data and storage'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/settings/data'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        routes: [
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const NotificationSettingsScreen(),
          ),
          GoRoute(
            path: 'language',
            builder: (context, state) => const LanguageSettingsScreen(),
          ),
          GoRoute(
            path: 'privacy',
            builder: (context, state) => const PrivacySettingsScreen(),
          ),
          GoRoute(
            path: 'data',
            builder: (context, state) => const DataSettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionManagementScreen(),
      ),
    ],
  );
});
