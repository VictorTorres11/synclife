import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/main_layout.dart';
import '../widgets/achievements_grid.dart';
import '../widgets/category_progress_chart.dart';
import '../widgets/leaderboard_widget.dart';
import '../widgets/user_stats_card.dart';

/// Dashboard screen showing user gamification statistics and progress
class GamificationDashboardScreen extends ConsumerWidget {
  const GamificationDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MainLayout(
      title: 'Dashboard',
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Stats Overview
            UserStatsCard(),
            SizedBox(height: 24),

            // Category Progress
            CategoryProgressChart(),
            SizedBox(height: 24),

            // Achievements Section
            AchievementsGrid(),
            SizedBox(height: 24),

            // Leaderboard Section
            LeaderboardWidget(),
          ],
        ),
      ),
    );
  }
}
