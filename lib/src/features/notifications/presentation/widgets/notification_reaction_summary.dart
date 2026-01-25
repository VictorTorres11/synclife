import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/notification_reaction.dart';
import '../providers/notification_providers.dart';

/// Widget that displays a summary of reactions for a notification
class NotificationReactionSummaryWidget extends ConsumerWidget {
  const NotificationReactionSummaryWidget({
    super.key,
    required this.notificationId,
    this.maxReactionsToShow = 3,
    this.showUserNames = false,
  });

  final String notificationId;
  final int maxReactionsToShow;
  final bool showUserNames;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reactionSummaryAsync = ref.watch(
      watchNotificationReactionSummaryProvider(notificationId),
    );

    return reactionSummaryAsync.when(
      data: (summary) => _buildSummary(context, summary),
      loading: () => _buildLoadingState(context),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildSummary(
      BuildContext context, NotificationReactionSummary summary) {
    if (summary.totalReactions == 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final topReactions = summary.getTopReactions(limit: maxReactionsToShow);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reaction emojis with counts
          ...topReactions.map((entry) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.key.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      entry.value.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              )),

          // Total count if there are more reactions
          if (summary.reactionCounts.length > maxReactionsToShow) ...[
            Text(
              '+${summary.totalReactions - topReactions.fold<int>(0, (sum, entry) => sum + entry.value)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Loading...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Detailed reaction list widget for showing all reactions
class DetailedNotificationReactionList extends ConsumerWidget {
  const DetailedNotificationReactionList({
    super.key,
    required this.notificationId,
  });

  final String notificationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reactionSummaryAsync = ref.watch(
      watchNotificationReactionSummaryProvider(notificationId),
    );

    return reactionSummaryAsync.when(
      data: (summary) => _buildDetailedList(context, summary),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(context),
    );
  }

  Widget _buildDetailedList(
      BuildContext context, NotificationReactionSummary summary) {
    if (summary.totalReactions == 0) {
      return _buildEmptyState(context);
    }

    final theme = Theme.of(context);
    final sortedReactions = summary.reactionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reactions (${summary.totalReactions})',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...sortedReactions.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ReactionListItem(
                reaction: entry.key,
                count: entry.value,
                userIds: summary.userReactions.entries
                    .where((userEntry) => userEntry.value == entry.key)
                    .map((userEntry) => userEntry.key)
                    .toList(),
              ),
            )),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sentiment_neutral,
            size: 48,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No reactions yet',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to react!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load reactions',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual reaction list item
class _ReactionListItem extends StatelessWidget {
  const _ReactionListItem({
    required this.reaction,
    required this.count,
    required this.userIds,
  });

  final EmojiReaction reaction;
  final int count;
  final List<String> userIds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Emoji
          Text(
            reaction.emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),

          // Count and description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count ${count == 1 ? 'person' : 'people'} reacted',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (userIds.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatUserList(userIds),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatUserList(List<String> userIds) {
    if (userIds.isEmpty) return '';

    // In a real app, you'd fetch user names from the user service
    // For now, we'll just show user IDs or a generic message
    if (userIds.length == 1) {
      return 'Someone reacted';
    } else if (userIds.length <= 3) {
      return '${userIds.length} people reacted';
    } else {
      return '${userIds.length} people reacted';
    }
  }
}
