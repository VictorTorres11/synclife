import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/notification_reaction.dart';
import '../providers/notification_providers.dart';

/// Widget that displays emoji reaction buttons for notifications
class NotificationReactionButtons extends ConsumerWidget {
  const NotificationReactionButtons({
    super.key,
    required this.notificationId,
    required this.userId,
    this.isCompact = false,
  });

  final String notificationId;
  final String userId;
  final bool isCompact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reactionSummaryAsync = ref.watch(
      watchNotificationReactionSummaryProvider(notificationId),
    );

    return reactionSummaryAsync.when(
      data: (summary) => _buildReactionButtons(context, ref, summary),
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(),
    );
  }

  Widget _buildReactionButtons(
    BuildContext context,
    WidgetRef ref,
    NotificationReactionSummary summary,
  ) {
    final theme = Theme.of(context);
    final userReaction = summary.getUserReaction(userId);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8.0 : 12.0,
        vertical: isCompact ? 4.0 : 8.0,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(isCompact ? 16.0 : 20.0),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reaction buttons row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: EmojiReaction.values.map((reaction) {
              final count = summary.getReactionCount(reaction);
              final isSelected = userReaction == reaction;

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 2.0 : 4.0,
                ),
                child: _ReactionButton(
                  reaction: reaction,
                  count: count,
                  isSelected: isSelected,
                  isCompact: isCompact,
                  onTap: () => _handleReactionTap(ref, reaction, isSelected),
                ),
              );
            }).toList(),
          ),

          // Summary text if there are reactions
          if (summary.totalReactions > 0 && !isCompact) ...[
            const SizedBox(height: 4),
            _buildReactionSummaryText(context, summary),
          ],
        ],
      ),
    );
  }

  Widget _buildReactionSummaryText(
    BuildContext context,
    NotificationReactionSummary summary,
  ) {
    final theme = Theme.of(context);
    final topReactions = summary.getTopReactions(limit: 2);

    if (topReactions.isEmpty) return const SizedBox.shrink();

    final summaryText = topReactions
        .map((entry) => '${entry.key.emoji} ${entry.value}')
        .join('  ');

    return Text(
      summaryText,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.7),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: EdgeInsets.all(isCompact ? 8.0 : 12.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: isCompact ? 12.0 : 16.0,
            height: isCompact ? 12.0 : 16.0,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          const Text('Loading reactions...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: EdgeInsets.all(isCompact ? 8.0 : 12.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: isCompact ? 16.0 : 20.0,
            color: Colors.red,
          ),
          const SizedBox(width: 8),
          const Text('Failed to load reactions'),
        ],
      ),
    );
  }

  Future<void> _handleReactionTap(
    WidgetRef ref,
    EmojiReaction reaction,
    bool isSelected,
  ) async {
    try {
      if (isSelected) {
        // Remove reaction if already selected
        final removeReaction = ref.read(
          removeReactionProvider((
            notificationId: notificationId,
            userId: userId,
          )),
        );
        await removeReaction();
      } else {
        // Send new reaction
        final sendReaction = ref.read(
          sendReactionProvider((
            notificationId: notificationId,
            userId: userId,
          )),
        );
        await sendReaction(reaction);
      }
    } catch (e) {
      // Handle error silently or show a snackbar
      debugPrint('Error handling reaction: $e');
    }
  }
}

/// Individual reaction button widget
class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.reaction,
    required this.count,
    required this.isSelected,
    required this.isCompact,
    required this.onTap,
  });

  final EmojiReaction reaction;
  final int count;
  final bool isSelected;
  final bool isCompact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = isCompact ? 32.0 : 40.0;
    final fontSize = isCompact ? 16.0 : 20.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(size / 2),
            border: isSelected
                ? Border.all(
                    color: theme.colorScheme.primary,
                    width: 1.5,
                  )
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Emoji
              Text(
                reaction.emoji,
                style: TextStyle(fontSize: fontSize),
              ),

              // Count badge
              if (count > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      count.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact version for use in notification tiles
class CompactNotificationReactionButtons extends StatelessWidget {
  const CompactNotificationReactionButtons({
    super.key,
    required this.notificationId,
    required this.userId,
  });

  final String notificationId;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return NotificationReactionButtons(
      notificationId: notificationId,
      userId: userId,
      isCompact: true,
    );
  }
}
