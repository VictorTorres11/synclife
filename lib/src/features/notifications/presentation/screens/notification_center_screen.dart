import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/main_layout.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/services/firebase_notification_service.dart';
import '../../domain/models/app_notification.dart';
import '../providers/notification_center_providers.dart';
import '../providers/notification_providers.dart' as notif_providers;
import '../widgets/notification_filter_chips.dart';
import '../widgets/notification_list.dart';
import '../widgets/team_activity_feed.dart';

/// Screen displaying the notification center with all user notifications
class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  NotificationType? _selectedFilter;
  bool _filtersExpanded = false; // Estado para controlar expansão dos filtros

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);

    return MainLayout(
      title: 'Notifications',
      actions: [
        IconButton(
          onPressed: _markAllAsRead,
          icon: const Icon(Icons.done_all),
          tooltip: 'Mark all as read',
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'clear_read',
              child: Text('Clear read notifications'),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Text('Notification settings'),
            ),
          ],
        ),
      ],
      child: Column(
        children: [
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor:
                  theme.colorScheme.onSurface.withOpacity(0.6),
              indicatorColor: theme.colorScheme.primary,
              tabs: const [
                Tab(
                  icon: Icon(Icons.notifications),
                  text: 'All Notifications',
                ),
                Tab(
                  icon: Icon(Icons.group),
                  text: 'Team Activity',
                ),
              ],
            ),
          ),

          // Collapsible Filter Section (only for All Notifications tab)
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              if (_tabController.index == 0) {
                return _buildCollapsibleFilters();
              }
              return const SizedBox.shrink();
            },
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                NotificationList(filter: _selectedFilter),
                const TeamActivityFeed(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleFilters() {
    return Column(
      children: [
        // Filter toggle button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _filtersExpanded = !_filtersExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filtros',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  // Show active filter indicator if any filter is applied
                  if (_selectedFilter != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '1',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  
                  // Clear filters button (only show when filters are active)
                  if (_selectedFilter != null)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedFilter = null;
                        });
                      },
                      icon: const Icon(Icons.clear_all),
                      tooltip: 'Limpar filtros',
                      iconSize: 20,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  
                  AnimatedRotation(
                    turns: _filtersExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Expandable filter content
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: _filtersExpanded ? null : 0,
          child: _filtersExpanded
              ? NotificationFilterChips(
                  selectedFilter: _selectedFilter,
                  onFilterChanged: (filter) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  void _markAllAsRead() {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      final notificationService =
          ref.read(notif_providers.notificationServiceProvider)
              as FirebaseNotificationService;
      notificationService.setCurrentUserId(user.id);
      notificationService.markAllAsRead();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'clear_read':
        _clearReadNotifications();
        break;
      case 'settings':
        _openNotificationSettings();
        break;
    }
  }

  void _clearReadNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Read Notifications'),
        content: const Text(
            'Are you sure you want to clear all read notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              final user = ref.read(authStateProvider).value;
              if (user != null) {
                final notificationService =
                    ref.read(notif_providers.notificationServiceProvider)
                        as FirebaseNotificationService;
                notificationService.setCurrentUserId(user.id);
                notificationService.clearReadNotifications();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Read notifications cleared')),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _openNotificationSettings() {
    Navigator.of(context).pushNamed('/notification-settings');
  }
}
