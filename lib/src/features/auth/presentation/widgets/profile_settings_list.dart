import 'package:flutter/material.dart';

import '../../../../core/theme/theme_settings_widget.dart';

/// Widget displaying profile-related settings options
class ProfileSettingsList extends StatelessWidget {
  const ProfileSettingsList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Preferences',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildSettingsTile(
            context,
            'Notifications',
            'Manage notification preferences',
            Icons.notifications,
            () => _navigateToNotificationSettings(context),
          ),
          _buildSettingsTile(
            context,
            'Language & Region',
            'Change language and region settings',
            Icons.language,
            () => _navigateToLanguageSettings(context),
          ),
          _buildSettingsTile(
            context,
            'Privacy',
            'Manage privacy and data settings',
            Icons.privacy_tip,
            () => _navigateToPrivacySettings(context),
          ),
          _buildSettingsTile(
            context,
            'Theme',
            'Customize app appearance',
            Icons.palette,
            () => _navigateToThemeSettings(context),
          ),
          _buildSettingsTile(
            context,
            'Data & Storage',
            'Manage app data and storage',
            Icons.storage,
            () => _navigateToDataSettings(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _navigateToNotificationSettings(BuildContext context) {
    Navigator.of(context).pushNamed('/notification-settings');
  }

  void _navigateToLanguageSettings(BuildContext context) {
    Navigator.of(context).pushNamed('/language-settings');
  }

  void _navigateToPrivacySettings(BuildContext context) {
    Navigator.of(context).pushNamed('/privacy-settings');
  }

  void _navigateToThemeSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme Settings'),
        content: SizedBox(
          width: double.maxFinite,
          child: ThemeSettingsWidget(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _navigateToDataSettings(BuildContext context) {
    Navigator.of(context).pushNamed('/data-settings');
  }
}
