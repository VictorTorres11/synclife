import 'package:flutter/material.dart';

/// Widget displaying category tabs for the store
class StoreCategoryTabs extends StatelessWidget {
  const StoreCategoryTabs({
    super.key,
    required this.controller,
  });

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: controller,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        indicatorColor: theme.colorScheme.primary,
        indicatorWeight: 3,
        tabs: const [
          Tab(
            icon: Icon(Icons.extension),
            text: 'Functional',
          ),
          Tab(
            icon: Icon(Icons.palette),
            text: 'Visual',
          ),
          Tab(
            icon: Icon(Icons.build),
            text: 'Utility',
          ),
        ],
      ),
    );
  }
}
