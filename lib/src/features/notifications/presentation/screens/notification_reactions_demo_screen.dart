import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/notification_reaction.dart';
import '../widgets/notification_reaction_buttons.dart';
import '../widgets/notification_reaction_summary.dart';

/// Demo screen to showcase notification emoji reactions
class NotificationReactionsDemoScreen extends ConsumerStatefulWidget {
  const NotificationReactionsDemoScreen({super.key});

  @override
  ConsumerState<NotificationReactionsDemoScreen> createState() =>
      _NotificationReactionsDemoScreenState();
}

class _NotificationReactionsDemoScreenState
    extends ConsumerState<NotificationReactionsDemoScreen> {
  final String _demoNotificationId = 'demo_notification_123';
  final String _currentUserId = 'current_user_456';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emoji Reactions Demo'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Demo notification card
            _buildDemoNotificationCard(context),

            const SizedBox(height: 24),

            // Reaction buttons section
            _buildSectionTitle(context, 'Interactive Reaction Buttons'),
            const SizedBox(height: 12),
            _buildReactionButtonsDemo(context),

            const SizedBox(height: 24),

            // Compact reaction buttons section
            _buildSectionTitle(context, 'Compact Reaction Buttons'),
            const SizedBox(height: 12),
            _buildCompactReactionButtonsDemo(context),

            const SizedBox(height: 24),

            // Reaction summary section
            _buildSectionTitle(context, 'Reaction Summary'),
            const SizedBox(height: 12),
            _buildReactionSummaryDemo(context),

            const SizedBox(height: 24),

            // Detailed reaction list section
            _buildSectionTitle(context, 'Detailed Reaction List'),
            const SizedBox(height: 12),
            _buildDetailedReactionListDemo(context),

            const SizedBox(height: 24),

            // Instructions
            _buildInstructions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoNotificationCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications, size: 20),
                const SizedBox(width: 8),
                Text(
                  '🌅 Good Morning!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'You have 3 tasks today (2 essential). Focus on your essential tasks to build your streak! 💪',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'React with emojis to show your mood or response!',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildReactionButtonsDemo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Full-size reaction buttons with counts and summary:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Center(
              child: NotificationReactionButtons(
                notificationId: _demoNotificationId,
                userId: _currentUserId,
                isCompact: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactReactionButtonsDemo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compact reaction buttons for notification tiles:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Center(
              child: CompactNotificationReactionButtons(
                notificationId: _demoNotificationId,
                userId: _currentUserId,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionSummaryDemo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reaction summary (shows top reactions):',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Center(
              child: NotificationReactionSummaryWidget(
                notificationId: _demoNotificationId,
                maxReactionsToShow: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedReactionListDemo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed reaction breakdown:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: DetailedNotificationReactionList(
                notificationId: _demoNotificationId,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'How to Use',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInstructionItem(
              context,
              '1. Tap any emoji button to react to the notification',
            ),
            _buildInstructionItem(
              context,
              '2. Tap the same emoji again to remove your reaction (toggle)',
            ),
            _buildInstructionItem(
              context,
              '3. Tap a different emoji to change your reaction',
            ),
            _buildInstructionItem(
              context,
              '4. View reaction counts and summaries in real-time',
            ),
            const SizedBox(height: 8),
            Text(
              'Note: This is a demo screen. In the real app, reactions would be synced across all users and stored in Firestore.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
