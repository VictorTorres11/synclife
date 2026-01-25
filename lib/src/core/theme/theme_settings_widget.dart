import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme.dart';
import 'theme_provider.dart';

/// Widget for theme settings that allows users to change theme mode
class ThemeSettingsWidget extends ConsumerWidget {
  const ThemeSettingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tema do Aplicativo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            const Text(
              'Escolha como o aplicativo deve aparecer',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.neutralGray600,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            ...AppThemeMode.values.map((themeMode) {
              return RadioListTile<AppThemeMode>(
                title: Text(_getThemeModeTitle(themeMode)),
                subtitle: Text(_getThemeModeSubtitle(themeMode)),
                value: themeMode,
                groupValue: currentTheme,
                onChanged: (value) {
                  if (value != null) {
                    themeNotifier.setThemeMode(value);
                  }
                },
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getThemeModeTitle(AppThemeMode themeMode) {
    switch (themeMode) {
      case AppThemeMode.system:
        return 'Automático';
      case AppThemeMode.light:
        return 'Claro';
      case AppThemeMode.dark:
        return 'Escuro';
    }
  }

  String _getThemeModeSubtitle(AppThemeMode themeMode) {
    switch (themeMode) {
      case AppThemeMode.system:
        return 'Segue as configurações do sistema';
      case AppThemeMode.light:
        return 'Sempre usar tema claro';
      case AppThemeMode.dark:
        return 'Sempre usar tema escuro';
    }
  }
}

/// Simple theme toggle button for quick access
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      onPressed: () {
        // Cycle through theme modes
        switch (currentTheme) {
          case AppThemeMode.system:
            themeNotifier.setThemeMode(AppThemeMode.light);
            break;
          case AppThemeMode.light:
            themeNotifier.setThemeMode(AppThemeMode.dark);
            break;
          case AppThemeMode.dark:
            themeNotifier.setThemeMode(AppThemeMode.system);
            break;
        }
      },
      icon: Icon(
        _getThemeIcon(currentTheme, isDark),
      ),
      tooltip: _getThemeTooltip(currentTheme),
    );
  }

  IconData _getThemeIcon(AppThemeMode themeMode, bool isDark) {
    switch (themeMode) {
      case AppThemeMode.system:
        return Icons.brightness_auto;
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
    }
  }

  String _getThemeTooltip(AppThemeMode themeMode) {
    switch (themeMode) {
      case AppThemeMode.system:
        return 'Tema automático';
      case AppThemeMode.light:
        return 'Tema claro';
      case AppThemeMode.dark:
        return 'Tema escuro';
    }
  }
}