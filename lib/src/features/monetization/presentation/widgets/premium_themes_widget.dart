import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/premium_theme.dart';
import '../providers/premium_theme_providers.dart';

/// Widget for managing premium themes
class PremiumThemesWidget extends ConsumerWidget {
  const PremiumThemesWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themesAsync = ref.watch(availableThemesProvider);
    final preferencesAsync = ref.watch(userThemePreferencesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Available Themes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            TextButton.icon(
              onPressed: () => _showCreateThemeDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Create Theme'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Theme preferences
        preferencesAsync.when(
          data: (preferences) => _buildThemeSettings(context, ref, preferences),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),

        // Available themes
        themesAsync.when(
          data: (themes) => _buildThemeGrid(context, ref, themes),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => _buildErrorState(context, error),
        ),
      ],
    );
  }

  Widget _buildThemeSettings(
    BuildContext context,
    WidgetRef ref,
    UserThemePreferences preferences,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme Settings',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Use dark theme'),
              value: preferences.isDarkMode,
              onChanged: (value) {
                ref
                    .read(premiumThemeServiceProvider)
                    .toggleDarkMode(preferences.userId, value);
              },
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Follow System Theme'),
              subtitle:
                  const Text('Automatically switch based on system settings'),
              value: preferences.followSystemTheme,
              onChanged: (value) {
                ref
                    .read(premiumThemeServiceProvider)
                    .toggleSystemTheme(preferences.userId, value);
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeGrid(
    BuildContext context,
    WidgetRef ref,
    List<PremiumTheme> themes,
  ) {
    final preferencesAsync = ref.watch(userThemePreferencesProvider);

    return preferencesAsync.when(
      data: (preferences) {
        // Group themes by category
        final groupedThemes = <ThemeCategory, List<PremiumTheme>>{};
        for (final theme in themes) {
          groupedThemes.putIfAbsent(theme.category, () => []).add(theme);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: groupedThemes.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _getCategoryName(entry.key),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: entry.value.length,
                  itemBuilder: (context, index) {
                    final theme = entry.value[index];
                    final isSelected = theme.id == preferences.selectedThemeId;

                    return _buildThemeCard(
                      context,
                      ref,
                      theme,
                      isSelected,
                      preferences.isDarkMode,
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildThemeCard(
    BuildContext context,
    WidgetRef ref,
    PremiumTheme theme,
    bool isSelected,
    bool isDarkMode,
  ) {
    final colorScheme = isDarkMode
        ? theme.colorScheme.darkScheme
        : theme.colorScheme.lightScheme;

    return GestureDetector(
      onTap: () {
        ref
            .read(premiumThemeServiceProvider)
            .setActiveTheme('current_user_id', theme.id);
      },
      child: Card(
        elevation: isSelected ? 4 : 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme preview
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Color preview
                      Positioned(
                        top: 8,
                        left: 8,
                        right: 8,
                        child: Row(
                          children: [
                            _buildColorDot(colorScheme.primary),
                            const SizedBox(width: 4),
                            _buildColorDot(colorScheme.secondary),
                            const SizedBox(width: 4),
                            _buildColorDot(colorScheme.surface),
                          ],
                        ),
                      ),

                      // Premium badge
                      if (theme.isPremium)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),

                      // Selected indicator
                      if (isSelected)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Theme info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        theme.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        theme.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 0.5,
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to load themes',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _getCategoryName(ThemeCategory category) {
    switch (category) {
      case ThemeCategory.standard:
        return 'Standard';
      case ThemeCategory.nature:
        return 'Nature';
      case ThemeCategory.minimal:
        return 'Minimal';
      case ThemeCategory.vibrant:
        return 'Vibrant';
      case ThemeCategory.professional:
        return 'Professional';
      case ThemeCategory.seasonal:
        return 'Seasonal';
      case ThemeCategory.custom:
        return 'Custom';
    }
  }

  void _showCreateThemeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Custom Theme'),
        content: const Text(
            'This would open a theme editor to create a custom theme.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Open theme editor
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
