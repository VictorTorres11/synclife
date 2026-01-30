import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/main_layout.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/quick_stats_widget.dart';
import '../widgets/recent_activity_widget.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (user == null) {
      return const MainLayout(
        title: 'Dashboard',
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return MainLayout(
      title: 'Bem-vindo ao SyncLife',
      actions: [
        IconButton(
          onPressed: () => context.push('/notifications'),
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notificações',
        ),
        IconButton(
          onPressed: () => context.push('/profile'),
          icon: const Icon(Icons.person_outline),
          tooltip: 'Perfil',
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Olá, ${user.displayName ?? user.email}! 👋',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pronto para ser mais produtivo hoje?',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick stats
            const QuickStatsWidget(),

            const SizedBox(height: 24),

            // Main feature cards
            Text(
              'Principais Recursos',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Feature cards grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                DashboardCard(
                  title: 'Minhas Tarefas',
                  subtitle: 'Gerencie suas atividades',
                  icon: Icons.task_alt,
                  color: Colors.blue,
                  onTap: () => context.push('/tasks'),
                ),
                DashboardCard(
                  title: 'Quadros',
                  subtitle: 'Organize seus projetos',
                  icon: Icons.dashboard,
                  color: Colors.green,
                  onTap: () => context.push('/boards'),
                ),
                DashboardCard(
                  title: 'Gamificação',
                  subtitle: 'Conquistas e progresso',
                  icon: Icons.emoji_events,
                  color: Colors.orange,
                  onTap: () => context.push('/gamification'),
                ),
                DashboardCard(
                  title: 'Loja FluxoCoins',
                  subtitle: 'Troque por recompensas',
                  icon: Icons.store,
                  color: Colors.purple,
                  onTap: () => context.push('/rewards'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent activity
            Text(
              'Atividade Recente',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const RecentActivityWidget(),

            const SizedBox(height: 24),

            // Quick actions
            Text(
              'Ações Rápidas',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Quick action buttons
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    context: context,
                    icon: Icons.add_task,
                    label: 'Nova Tarefa',
                    color: colorScheme.primary,
                    onTap: () => context.push('/tasks'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    context: context,
                    icon: Icons.notifications,
                    label: 'Notificações',
                    color: colorScheme.secondary,
                    onTap: () => context.push('/notifications'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    context: context,
                    icon: Icons.settings,
                    label: 'Configurações',
                    color: colorScheme.tertiary,
                    onTap: () => context.push('/profile'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    context: context,
                    icon: Icons.star,
                    label: 'Premium',
                    color: Colors.amber,
                    onTap: () => context.push('/premium'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}