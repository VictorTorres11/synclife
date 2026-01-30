import 'package:flutter/material.dart';

import '../../domain/models/board.dart';
import '../../domain/models/board_type.dart';

/// Statistics for a board
class BoardStats {
  const BoardStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.overdueTasks,
  });

  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int overdueTasks;

  int get completionPercentage => 
      totalTasks > 0 ? ((completedTasks / totalTasks) * 100).round() : 0;
}

/// Enhanced card widget for board management with actions and statistics
class BoardManagementCard extends StatelessWidget {
  const BoardManagementCard({
    super.key,
    required this.board,
    this.stats,
    this.onTap,
    this.onEdit,
    this.onMembers,
    this.onSettings,
    this.onDelete,
  });

  final Board board;
  final BoardStats? stats;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onMembers;
  final VoidCallback? onSettings;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and type indicator
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          board.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        if (board.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            board.description!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildTypeChip(context),
                ],
              ),

              const SizedBox(height: 12),

              // Task statistics (if available)
              if (stats != null) ...[
                _buildTaskStats(context),
                const SizedBox(height: 12),
              ],

              // Board info
              Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${board.memberIds.length} ${board.memberIds.length == 1 ? 'membro' : 'membros'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(board.updatedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onMembers != null) ...[
                    TextButton.icon(
                      onPressed: onMembers,
                      icon: const Icon(Icons.group, size: 16),
                      label: const Text('Membros'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Editar'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onSettings,
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text('Config'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete' && onDelete != null) {
                        onDelete!();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 16),
                            SizedBox(width: 8),
                            Text('Excluir',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    child: const Icon(Icons.more_vert, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(BuildContext context) {
    final isShared = board.type == BoardType.shared;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isShared ? Colors.blue[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isShared ? Colors.blue[200]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isShared ? Icons.group : Icons.lock,
            size: 12,
            color: isShared ? Colors.blue[700] : Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            isShared ? 'Compartilhado' : 'Privado',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isShared ? Colors.blue[700] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskStats(BuildContext context) {
    if (stats == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Progress bar
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progresso das Tarefas',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${stats!.completionPercentage}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: stats!.totalTasks > 0 
                          ? stats!.completedTasks / stats!.totalTasks 
                          : 0,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Task statistics
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.task_alt,
                  label: 'Total',
                  value: stats!.totalTasks.toString(),
                  color: Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.check_circle,
                  label: 'Concluídas',
                  value: stats!.completedTasks.toString(),
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.pending,
                  label: 'Pendentes',
                  value: stats!.pendingTasks.toString(),
                  color: Colors.orange,
                ),
              ),
              if (stats!.overdueTasks > 0)
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.warning,
                    label: 'Atrasadas',
                    value: stats!.overdueTasks.toString(),
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoje';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'semana' : 'semanas'} atrás';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'mês' : 'meses'} atrás';
    }
  }
}