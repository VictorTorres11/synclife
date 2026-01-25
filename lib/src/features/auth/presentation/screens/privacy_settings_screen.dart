import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/main_layout.dart';

/// Screen for managing privacy and data settings
class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() =>
      _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  // Privacy settings state
  bool _analyticsEnabled = true;
  bool _crashReportingEnabled = true;
  bool _locationTrackingEnabled = true;
  bool _personalizedAdsEnabled = false;
  bool _dataExportEnabled = true;
  bool _profileVisibilityPublic = false;

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Privacy Settings',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data Collection
            _buildSectionHeader('Data Collection'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Analytics'),
                    subtitle: const Text(
                        'Help improve the app with anonymous usage data'),
                    value: _analyticsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _analyticsEnabled = value;
                      });
                      _showAnalyticsDialog(context, value);
                    },
                    secondary: const Icon(Icons.analytics),
                  ),
                  SwitchListTile(
                    title: const Text('Crash Reporting'),
                    subtitle: const Text(
                        'Automatically send crash reports to help fix bugs'),
                    value: _crashReportingEnabled,
                    onChanged: (value) {
                      setState(() {
                        _crashReportingEnabled = value;
                      });
                    },
                    secondary: const Icon(Icons.bug_report),
                  ),
                  SwitchListTile(
                    title: const Text('Location Tracking'),
                    subtitle: const Text(
                        'Use location for timezone detection and regional features'),
                    value: _locationTrackingEnabled,
                    onChanged: (value) {
                      setState(() {
                        _locationTrackingEnabled = value;
                      });
                      if (!value) {
                        _showLocationWarningDialog(context);
                      }
                    },
                    secondary: const Icon(Icons.location_on),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Advertising
            _buildSectionHeader('Advertising'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Personalized Ads'),
                    subtitle: const Text(
                        'Show ads based on your interests and activity'),
                    value: _personalizedAdsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _personalizedAdsEnabled = value;
                      });
                    },
                    secondary: const Icon(Icons.ads_click),
                  ),
                  ListTile(
                    title: const Text('Ad Preferences'),
                    subtitle: const Text('Manage your advertising preferences'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showAdPreferencesDialog(context),
                    leading: const Icon(Icons.tune),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Profile & Sharing
            _buildSectionHeader('Profile & Sharing'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Public Profile'),
                    subtitle: const Text(
                        'Allow others to find you by email or username'),
                    value: _profileVisibilityPublic,
                    onChanged: (value) {
                      setState(() {
                        _profileVisibilityPublic = value;
                      });
                    },
                    secondary: const Icon(Icons.public),
                  ),
                  ListTile(
                    title: const Text('Blocked Users'),
                    subtitle: const Text('Manage blocked users and boards'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showBlockedUsersDialog(context),
                    leading: const Icon(Icons.block),
                  ),
                  ListTile(
                    title: const Text('Data Sharing'),
                    subtitle: const Text(
                        'Control what data is shared with board members'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showDataSharingDialog(context),
                    leading: const Icon(Icons.share),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Data Management
            _buildSectionHeader('Data Management'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Data Export'),
                    subtitle: const Text('Allow exporting your data'),
                    value: _dataExportEnabled,
                    onChanged: (value) {
                      setState(() {
                        _dataExportEnabled = value;
                      });
                    },
                    secondary: const Icon(Icons.download),
                  ),
                  ListTile(
                    title: const Text('Data Retention'),
                    subtitle: const Text('How long we keep your data'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showDataRetentionDialog(context),
                    leading: const Icon(Icons.schedule),
                  ),
                  ListTile(
                    title: const Text('Delete All Data'),
                    subtitle: const Text('Permanently delete all your data'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showDeleteDataDialog(context),
                    leading:
                        const Icon(Icons.delete_forever, color: Colors.red),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Legal
            _buildSectionHeader('Legal'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Privacy Policy'),
                    subtitle: const Text('Read our privacy policy'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _openPrivacyPolicy(context),
                    leading: const Icon(Icons.policy),
                  ),
                  ListTile(
                    title: const Text('Terms of Service'),
                    subtitle: const Text('Read our terms of service'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _openTermsOfService(context),
                    leading: const Icon(Icons.description),
                  ),
                  ListTile(
                    title: const Text('Data Processing Agreement'),
                    subtitle: const Text('How we process your data'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _openDataProcessingAgreement(context),
                    leading: const Icon(Icons.gavel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
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

  void _showAnalyticsDialog(BuildContext context, bool enabled) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(enabled ? 'Analytics Enabled' : 'Analytics Disabled'),
        content: Text(
          enabled
              ? 'Thank you for helping us improve SyncLife! We collect anonymous usage data to understand how the app is used and identify areas for improvement.'
              : 'Analytics has been disabled. We will not collect usage data, but this may limit our ability to improve the app experience.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLocationWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Tracking Disabled'),
        content: const Text(
          'Disabling location tracking may affect timezone detection and some regional features. You can manually set your timezone in Language & Region settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAdPreferencesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ad Preferences'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manage your advertising preferences:'),
            SizedBox(height: 16),
            Text('• Ad frequency: Minimal'),
            Text('• Ad types: Non-intrusive only'),
            Text('• Personalization: Based on app usage'),
            Text('• Third-party ads: Limited'),
            SizedBox(height: 16),
            Text('Advanced ad controls will be available in a future update.'),
          ],
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

  void _showBlockedUsersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Blocked Users'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You have not blocked any users.'),
            SizedBox(height: 16),
            Text('Blocked users cannot:'),
            Text('• Send you board invitations'),
            Text('• See your public profile'),
            Text('• Find you in user search'),
          ],
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

  void _showDataSharingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Sharing'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data shared with board members:'),
            SizedBox(height: 16),
            Text('• Display name and avatar'),
            Text('• Task completion status'),
            Text('• Activity timestamps'),
            Text('• Comments on shared tasks'),
            SizedBox(height: 16),
            Text('Data NOT shared:'),
            Text('• Email address'),
            Text('• Private boards'),
            Text('• Personal statistics'),
          ],
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

  void _showDataRetentionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Retention'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How long we keep your data:'),
            SizedBox(height: 16),
            Text('• Account data: Until account deletion'),
            Text('• Task data: Until manually deleted'),
            Text('• Analytics: 2 years (anonymized)'),
            Text('• Crash reports: 1 year'),
            Text('• Backup data: 30 days after deletion'),
            SizedBox(height: 16),
            Text('You can request data deletion at any time.'),
          ],
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

  void _showDeleteDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'This will permanently delete all your data including tasks, boards, and account information. This action cannot be undone.\n\n'
          'To delete your account and all data, use the "Delete Account" option in your profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/profile');
            },
            child: const Text('Go to Profile'),
          ),
        ],
      ),
    );
  }

  void _openPrivacyPolicy(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Privacy Policy would open in browser'),
      ),
    );
  }

  void _openTermsOfService(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Terms of Service would open in browser'),
      ),
    );
  }

  void _openDataProcessingAgreement(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data Processing Agreement would open in browser'),
      ),
    );
  }
}
