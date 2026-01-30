import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/main_layout.dart';
import '../../domain/models/models.dart';
import '../providers/gamification_providers.dart';

/// Full achievements screen showing all user achievements
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final achievementsAsync = ref.watch(userAchievementsProvider);
    final theme = Theme.of(context);

    return MainLayout(
      title: 'Conquistas',
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _showSearchDialog,
          tooltip: 'Buscar conquistas',
        ),
      ],
      child: Column(
        children: [
          // Tab Bar
          Container(
            color: theme.colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Todas', icon: Icon(Icons.emoji_events)),
                Tab(text: 'Desbloqueadas', icon: Icon(Icons.check_circle)),
                Tab(text: 'Bloqueadas', icon: Icon(Icons.lock)),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: achievementsAsync.when(
              data: (achievements) => _buildAchievementTabs(achievements),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementTabs(List<Achievement> allAchievements) {
    final filteredAchievements = _filterAchievements(allAchievements);
    final unlockedAchievements = filteredAchievements
        .where((achievement) => achievement.isUnlocked)
        .toList();
    final lockedAchievements = filteredAchievements
        .where((achievement) => !achievement.isUnlocked)
        .toList();

    return TabBarView(
      controller: _tabController,
      children: [
        _buildAchievementsList(
          filteredAchievements,
          'Nenhuma conquista encontrada',
        ),
        _buildAchievementsList(
          unlockedAchievements,
          'Nenhuma conquista desbloqueada ainda',
        ),
        _buildAchievementsList(
          lockedAchievements,
          'Todas as conquistas foram desbloqueadas!',
        ),
      ],
    );
  }

  Widget _buildAchievementsList(
      List<Achievement> achievements, String emptyMessage) {
    if (achievements.isEmpty) {
      return _buildEmptyState(emptyMessage);
    }

    // Group achievements by category
    final groupedAchievements = <String, List<Achievement>>{};
    for (final achievement in achievements) {
      final category = achievement.category;
      if (!groupedAchievements.containsKey(category)) {
        groupedAchievements[category] = [];
      }
      groupedAchievements[category]!.add(achievement);
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userAchievementsProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groupedAchievements.length,
        itemBuilder: (context, index) {
          final category = groupedAchievements.keys.elementAt(index);
          final categoryAchievements = groupedAchievements[category]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(category),
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _getCategoryDisplayName(category),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${categoryAchievements.where((a) => a.isUnlocked).length}/${categoryAchievements.length}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),

              // Achievements Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: categoryAchievements.length,
                itemBuilder: (context, achievementIndex) {
                  final achievement = categoryAchievements[achievementIndex];
                  return _buildAchievementCard(achievement);
                },
              ),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final theme = Theme.of(context);
    final isUnlocked = achievement.isUnlocked;

    return GestureDetector(
      onTap: () => _showAchievementDetails(achievement),
      child: Card(
        elevation: isUnlocked ? 4 : 1,
        shadowColor: isUnlocked
            ? theme.colorScheme.primary.withValues(alpha: 0.3)
            : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isUnlocked
                ? LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            border: Border.all(
              color: isUnlocked
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Achievement Icon
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                      boxShadow: isUnlocked
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      _getAchievementIcon(achievement.category),
                      color: isUnlocked
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      size: 28,
                    ),
                  ),
                  if (isUnlocked)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Achievement Title
              Text(
                achievement.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isUnlocked
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Achievement Description
              Text(
                achievement.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isUnlocked
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const Spacer(),

              // Rewards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildRewardChip(
                    icon: Icons.star,
                    value: '${achievement.xpReward}',
                    color: Colors.amber,
                    isUnlocked: isUnlocked,
                  ),
                  _buildRewardChip(
                    icon: Icons.monetization_on,
                    value: '${achievement.fluxoCoinReward}',
                    color: Colors.green,
                    isUnlocked: isUnlocked,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardChip({
    required IconData icon,
    required String value,
    required Color color,
    required bool isUnlocked,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isUnlocked ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isUnlocked ? color : color.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isUnlocked ? color : color.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 80,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Complete tarefas para desbloquear conquistas!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar conquistas',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.invalidate(userAchievementsProvider),
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  List<Achievement> _filterAchievements(List<Achievement> achievements) {
    if (_searchQuery.isEmpty) return achievements;

    return achievements.where((achievement) {
      return achievement.title
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          achievement.description
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          achievement.category
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _showSearchDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buscar Conquistas'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Digite o nome da conquista...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
              Navigator.of(context).pop();
            },
            child: const Text('Limpar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showAchievementDetails(Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getAchievementIcon(achievement.category),
              color: achievement.isUnlocked
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(achievement.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              achievement.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            // Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: achievement.isUnlocked
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    achievement.isUnlocked ? Icons.check_circle : Icons.lock,
                    color: achievement.isUnlocked ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    achievement.isUnlocked ? 'Desbloqueada' : 'Bloqueada',
                    style: TextStyle(
                      color: achievement.isUnlocked ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            if (achievement.isUnlocked && achievement.unlockedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Desbloqueada em ${achievement.unlockedAt!.day}/${achievement.unlockedAt!.month}/${achievement.unlockedAt!.year}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Rewards
            Text(
              'Recompensas:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text('${achievement.xpReward} XP'),
                const SizedBox(width: 16),
                Icon(Icons.monetization_on, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Text('${achievement.fluxoCoinReward} FluxoCoins'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  IconData _getAchievementIcon(String category) {
    switch (category.toLowerCase()) {
      case 'progress':
        return Icons.trending_up;
      case 'streak':
        return Icons.local_fire_department;
      case 'collaboration':
        return Icons.group;
      case 'completion':
        return Icons.check_circle;
      case 'productivity':
        return Icons.speed;
      case 'consistency':
        return Icons.schedule;
      default:
        return Icons.emoji_events;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'progress':
        return Icons.trending_up;
      case 'streak':
        return Icons.local_fire_department;
      case 'collaboration':
        return Icons.group;
      case 'completion':
        return Icons.check_circle;
      case 'productivity':
        return Icons.speed;
      case 'consistency':
        return Icons.schedule;
      default:
        return Icons.emoji_events;
    }
  }

  String _getCategoryDisplayName(String category) {
    switch (category.toLowerCase()) {
      case 'progress':
        return 'Progresso';
      case 'streak':
        return 'Sequências';
      case 'collaboration':
        return 'Colaboração';
      case 'completion':
        return 'Conclusão';
      case 'productivity':
        return 'Produtividade';
      case 'consistency':
        return 'Consistência';
      default:
        return category;
    }
  }
}