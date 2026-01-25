import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/board.dart';
import '../../domain/models/board_activity.dart';
import '../providers/board_providers.dart';

/// Widget that displays a real-time activity feed for a board
class BoardActivityFeed extends ConsumerWidget {
  const BoardActivityFeed({
    super.key,
    required this.board,
    this.maxItems = 10,
    this.showHeader = true,
  });

  final Board board;
  final int maxItems;
  final bool showHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(boardActivitiesProvider(board.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          _buildHeader(context),
          const SizedBox(height: 16),
        ],
        activitiesAsync.when(
          data: (activities) => _buildActivityList(context, activities),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(context, error),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.timeline,
            color: Colors.blue[700],
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Atividade Recente',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                'Acompanhe as últimas ações no quadro',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityList(
      BuildContext context, List<BoardActivity> activities) {
    if (activities.isEmpty) {
      return _buildEmptyState(context);
    }

    final displayActivities = activities.take(maxItems).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayActivities.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final activity = displayActivities[index];
        return _buildActivityItem(context, activity);
      },
    );
  }

  Widget _buildActivityItem(BuildContext context, BoardActivity activity) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Activity icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getActivityColor(activity.type).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getActivityIcon(activity.type),
              size: 16,
              color: _getActivityColor(activity.type),
            ),
          ),
          const SizedBox(width: 12),

          // Activity details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: activity.userName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: ' ${activity.description}'),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimeAgo(activity.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.timeline_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'Nenhuma atividade ainda',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'As atividades do quadro aparecerão aqui',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Erro ao carregar atividades: $error',
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(BoardActivityType type) {
    switch (type) {
      case BoardActivityType.taskCreated:
        return Icons.add_task;
      case BoardActivityType.taskCompleted:
        return Icons.task_alt;
      case BoardActivityType.taskUpdated:
        return Icons.edit;
      case BoardActivityType.taskDeleted:
        return Icons.delete;
      case BoardActivityType.userJoined:
        return Icons.person_add;
      case BoardActivityType.userLeft:
        return Icons.person_remove;
      case BoardActivityType.inviteSent:
        return Icons.send;
      case BoardActivityType.inviteAccepted:
        return Icons.check_circle;
      case BoardActivityType.boardUpdated:
        return Icons.edit_note;
      case BoardActivityType.other:
        return Icons.info;
    }
  }

  Color _getActivityColor(BoardActivityType type) {
    switch (type) {
      case BoardActivityType.taskCreated:
        return Colors.green;
      case BoardActivityType.taskCompleted:
        return Colors.blue;
      case BoardActivityType.taskUpdated:
        return Colors.orange;
      case BoardActivityType.taskDeleted:
        return Colors.red;
      case BoardActivityType.userJoined:
        return Colors.purple;
      case BoardActivityType.userLeft:
        return Colors.grey;
      case BoardActivityType.inviteSent:
        return Colors.indigo;
      case BoardActivityType.inviteAccepted:
        return Colors.teal;
      case BoardActivityType.boardUpdated:
        return Colors.amber;
      case BoardActivityType.other:
        return Colors.blueGrey;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'agora mesmo';
    } else if (difference.inMinutes < 60) {
      return 'há ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'há ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'há ${difference.inDays} dias';
    } else {
      return 'há ${(difference.inDays / 7).floor()} semanas';
    }
  }
}
