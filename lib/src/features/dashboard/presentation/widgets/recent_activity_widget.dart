import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecentActivityWidget extends ConsumerWidget {
  const RecentActivityWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Por enquanto, vamos mostrar atividades de exemplo
    // Futuramente, isso pode ser conectado a um provider real
    final activities = _getMockActivities();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Atividade Recente',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navegar para tela de atividades completa
                },
                child: const Text('Ver todas'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (activities.isEmpty)
            _buildEmptyState(context)
          else
            ...activities.map((activity) => _buildActivityItem(
              context: context,
              activity: activity,
            )),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required BuildContext context,
    required ActivityItem activity,
  }) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: activity.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              activity.icon,
              color: activity.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  activity.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            activity.time,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma atividade recente',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comece criando suas primeiras tarefas!',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<ActivityItem> _getMockActivities() {
    // Retorna atividades de exemplo
    // Em uma implementação real, isso viria de um provider
    return [
      ActivityItem(
        icon: Icons.task_alt,
        title: 'Tarefa concluída',
        subtitle: 'Revisar documentação do projeto',
        time: '2h atrás',
        color: Colors.green,
      ),
      ActivityItem(
        icon: Icons.emoji_events,
        title: 'Conquista desbloqueada',
        subtitle: 'Primeira tarefa concluída!',
        time: '3h atrás',
        color: Colors.amber,
      ),
      ActivityItem(
        icon: Icons.add_circle,
        title: 'Nova tarefa criada',
        subtitle: 'Preparar apresentação',
        time: '5h atrás',
        color: Colors.blue,
      ),
      ActivityItem(
        icon: Icons.local_fire_department,
        title: 'Sequência mantida',
        subtitle: '3 dias consecutivos',
        time: '1 dia atrás',
        color: Colors.orange,
      ),
    ];
  }
}

class ActivityItem {
  const ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;
}