import 'package:flutter/material.dart';

import '../../domain/models/board.dart';
import '../../domain/models/board_type.dart';

/// Widget for displaying a board in a list
class BoardListItem extends StatelessWidget {
  const BoardListItem({
    super.key,
    required this.board,
    required this.onTap,
    this.onInvite,
    this.onGenerateLink,
  });

  final Board board;
  final VoidCallback onTap;
  final VoidCallback? onInvite;
  final VoidCallback? onGenerateLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isShared = board.type == BoardType.shared;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isShared ? Icons.people : Icons.person,
                    color: isShared ? Colors.blue : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      board.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isShared) ...[
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        switch (value) {
                          case 'invite':
                            onInvite?.call();
                            break;
                          case 'link':
                            onGenerateLink?.call();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'invite',
                          child: Row(
                            children: [
                              Icon(Icons.person_add),
                              SizedBox(width: 8),
                              Text('Invite Users'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'link',
                          child: Row(
                            children: [
                              Icon(Icons.link),
                              SizedBox(width: 8),
                              Text('Copy Invite Link'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              if (board.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  board.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.schedule,
                    label: _formatDate(board.updatedAt),
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  if (isShared) ...[
                    _buildInfoChip(
                      icon: Icons.people,
                      label: '${board.memberIds.length} members',
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                  ],
                  _buildInfoChip(
                    icon: isShared ? Icons.public : Icons.lock,
                    label: isShared ? 'Shared' : 'Private',
                    color: isShared ? Colors.green : Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}