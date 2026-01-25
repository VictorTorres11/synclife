import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/main_layout.dart';
import '../../domain/models/notification_preferences.dart';
import '../providers/notification_providers.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesAsync = ref.watch(notificationPreferencesNotifierProvider);
    final permissionsAsync = ref.watch(notificationPermissionsProvider);

    return MainLayout(
      title: 'Notification Settings',
      child: preferencesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading preferences: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.refresh(notificationPreferencesNotifierProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (preferences) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Permissions status
              permissionsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (hasPermissions) => !hasPermissions
                    ? Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.notifications_off,
                                  color: Colors.orange),
                              const SizedBox(height: 8),
                              const Text(
                                'Notifications are disabled',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Enable notifications in your device settings to receive updates.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () async {
                                  final notificationService =
                                      ref.read(notificationServiceProvider);
                                  await notificationService
                                      .openNotificationSettings();
                                },
                                child: const Text('Open Settings'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 16),

              // General Settings
              _buildSectionHeader('General'),
              _buildSwitchTile(
                title: 'Push Notifications',
                subtitle: 'Receive notifications on this device',
                value: preferences.enablePushNotifications,
                onChanged: (_) => ref
                    .read(notificationPreferencesNotifierProvider.notifier)
                    .togglePushNotifications(),
                icon: Icons.notifications,
              ),

              const SizedBox(height: 24),

              // Notification Types
              _buildSectionHeader('Notification Types'),
              _buildSwitchTile(
                title: 'Daily Summary',
                subtitle: 'Morning summary of your tasks',
                value: preferences.enableDailySummary,
                onChanged: (_) => ref
                    .read(notificationPreferencesNotifierProvider.notifier)
                    .toggleDailySummary(),
                icon: Icons.wb_sunny,
                enabled: preferences.enablePushNotifications,
              ),
              _buildSwitchTile(
                title: 'Team Updates',
                subtitle: 'When team members complete tasks',
                value: preferences.enableTeamUpdates,
                onChanged: (_) => ref
                    .read(notificationPreferencesNotifierProvider.notifier)
                    .toggleTeamUpdates(),
                icon: Icons.group,
                enabled: preferences.enablePushNotifications,
              ),
              _buildSwitchTile(
                title: 'Night Summary',
                subtitle: 'Evening progress and streak updates',
                value: preferences.enableNightSummary,
                onChanged: (_) => ref
                    .read(notificationPreferencesNotifierProvider.notifier)
                    .toggleNightSummary(),
                icon: Icons.nightlight_round,
                enabled: preferences.enablePushNotifications,
              ),
              _buildSwitchTile(
                title: 'Task Reminders',
                subtitle: 'Reminders for upcoming tasks',
                value: preferences.enableTaskReminders,
                onChanged: (_) => ref
                    .read(notificationPreferencesNotifierProvider.notifier)
                    .toggleTaskReminders(),
                icon: Icons.alarm,
                enabled: preferences.enablePushNotifications,
              ),

              const SizedBox(height: 24),

              // Timing Settings
              _buildSectionHeader('Timing'),
              _buildTimeTile(
                title: 'Morning Summary Time',
                subtitle: 'When to send daily summary',
                time: preferences.morningTime,
                onChanged: (time) => ref
                    .read(notificationPreferencesNotifierProvider.notifier)
                    .updateMorningTime(time),
                icon: Icons.wb_sunny,
                enabled: preferences.enablePushNotifications &&
                    preferences.enableDailySummary,
              ),
              _buildTimeTile(
                title: 'Night Summary Time',
                subtitle: 'When to send evening summary',
                time: preferences.nightTime,
                onChanged: (time) => ref
                    .read(notificationPreferencesNotifierProvider.notifier)
                    .updateNightTime(time),
                icon: Icons.nightlight_round,
                enabled: preferences.enablePushNotifications &&
                    preferences.enableNightSummary,
              ),

              const SizedBox(height: 24),

              // Quiet Hours
              _buildSectionHeader('Quiet Hours'),
              _buildSwitchTile(
                title: 'Enable Quiet Hours',
                subtitle: 'Silence notifications during specified hours',
                value: preferences.enableQuietHours,
                onChanged: (_) => ref
                    .read(notificationPreferencesNotifierProvider.notifier)
                    .toggleQuietHours(),
                icon: Icons.do_not_disturb,
                enabled: preferences.enablePushNotifications,
              ),
              if (preferences.enableQuietHours &&
                  preferences.enablePushNotifications) ...[
                _buildQuietHoursTile(
                  title: 'Quiet Hours Period',
                  subtitle: 'No notifications during this time',
                  startTime: preferences.quietHoursStart,
                  endTime: preferences.quietHoursEnd,
                  onChanged: (start, end) => ref
                      .read(notificationPreferencesNotifierProvider.notifier)
                      .updateQuietHours(start, end),
                  icon: Icons.schedule,
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    bool enabled = true,
  }) {
    return ListTile(
      leading: Icon(icon, color: enabled ? null : Colors.grey),
      title: Text(
        title,
        style: TextStyle(color: enabled ? null : Colors.grey),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: enabled ? null : Colors.grey),
      ),
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
      ),
      enabled: enabled,
    );
  }

  Widget _buildTimeTile({
    required String title,
    required String subtitle,
    required TimeOfDay time,
    required Function(TimeOfDay) onChanged,
    required IconData icon,
    bool enabled = true,
  }) {
    return ListTile(
      leading: Icon(icon, color: enabled ? null : Colors.grey),
      title: Text(
        title,
        style: TextStyle(color: enabled ? null : Colors.grey),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: enabled ? null : Colors.grey),
      ),
      trailing: Text(
        time.toString(),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: enabled ? Colors.blue : Colors.grey,
        ),
      ),
      enabled: enabled,
      onTap: enabled
          ? () async {
              // This would open a time picker in a real implementation
              // For now, we'll just show a placeholder
            }
          : null,
    );
  }

  Widget _buildQuietHoursTile({
    required String title,
    required String subtitle,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required Function(TimeOfDay, TimeOfDay) onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text(
        '${startTime.toString()} - ${endTime.toString()}',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
      onTap: () async {
        // This would open time pickers in a real implementation
        // For now, we'll just show a placeholder
      },
    );
  }
}
