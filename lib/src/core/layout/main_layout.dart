import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/notifications/presentation/providers/notification_center_providers.dart';
import '../onboarding/onboarding_overlay.dart';
import '../onboarding/onboarding_wrapper.dart';
import '../sync/widgets/sync_status_indicator.dart';
import '../theme/app_theme.dart';
import '../theme/theme_settings_widget.dart';
import 'safe_area_wrapper.dart';

/// Main layout wrapper that provides consistent navigation and drawer
class MainLayout extends ConsumerWidget {
  const MainLayout({
    super.key,
    required this.child,
    this.title,
    this.showDrawer = true,
    this.actions,
  });

  final Widget child;
  final String? title;
  final bool showDrawer;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) => OnboardingWrapper(
        child: Scaffold(
          appBar: AppBar(
            title: title != null ? Text(title!) : null,
            leading: showDrawer ? const _DrawerMenuButton() : null,
            actions: [
              if (actions != null) ...actions!,
              const _StatusIndicators(),
              const ThemeToggleButton(),
            ],
          ),
          drawer: showDrawer ? const _AppDrawer() : null,
          body: SafeAreaWrapper(
            child: child,
          ),
        ),
      );
}

/// Status indicators showing notifications and sync status
class _StatusIndicators extends ConsumerWidget {
  const _StatusIndicators();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Notification indicator
        const _NotificationIndicator(),
        const SizedBox(width: AppTheme.spacingSm),
        // Sync status indicator
        SyncStatusIndicator(key: SyncLifeOnboardingSteps.syncStatusKey),
        const SizedBox(width: AppTheme.spacingSm),
      ],
    );
  }
}

/// Notification indicator with badge
class _NotificationIndicator extends ConsumerWidget {
  const _NotificationIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return unreadCount.when(
      data: (count) => Container(
        key: SyncLifeOnboardingSteps.notificationButtonKey,
        child: Stack(
          children: [
            IconButton(
              onPressed: () => context.go('/notifications'),
              icon: const Icon(Icons.notifications_outlined),
              tooltip: 'Notificações',
            ),
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
      loading: () => Container(
        key: SyncLifeOnboardingSteps.notificationButtonKey,
        child: IconButton(
          onPressed: () => context.go('/notifications'),
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notificações',
        ),
      ),
      error: (_, __) => Container(
        key: SyncLifeOnboardingSteps.notificationButtonKey,
        child: IconButton(
          onPressed: () => context.go('/notifications'),
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notificações',
        ),
      ),
    );
  }
}

/// Custom drawer menu button with stylized symbol
class _DrawerMenuButton extends StatefulWidget {
  const _DrawerMenuButton();

  @override
  State<_DrawerMenuButton> createState() => _DrawerMenuButtonState();
}

class _DrawerMenuButtonState extends State<_DrawerMenuButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _animation,
        builder: (context, child) => IconButton(
          onPressed: () {
            _animationController.forward().then((_) {
              _animationController.reverse();
            });
            Scaffold.of(context).openDrawer();
          },
          icon: Transform.scale(
            scale: 1 + (_animation.value * 0.1),
            child: Transform.rotate(
              angle: _animation.value * 0.1,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.primary.withValues(
                        alpha: _animation.value * 0.1,
                      ),
                ),
                child: const Icon(Icons.menu_rounded),
              ),
            ),
          ),
          tooltip: 'Menu',
        ),
      );
}

/// Main application drawer with navigation and settings
class _AppDrawer extends ConsumerWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);

    return Drawer(
      width: 280,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: Column(
          children: [
            // Drawer Header
            _DrawerHeader(
              user: userAsync.when(
                data: (user) => user,
                loading: () => null,
                error: (_, __) => null,
              ),
            ),

            // Navigation Items
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _DrawerSection(
                          title: 'Navegação',
                          items: [
                            _DrawerItem(
                              icon: Icons.task_alt,
                              title: 'Minhas Tarefas',
                              onTap: () {
                                _navigateWithAnimation(context, '/tasks');
                              },
                            ),
                            _DrawerItem(
                              icon: Icons.dashboard,
                              title: 'Quadros',
                              onTap: () {
                                _navigateWithAnimation(context, '/boards');
                              },
                            ),
                            _DrawerItem(
                              icon: Icons.notifications,
                              title: 'Notificações',
                              onTap: () {
                                _navigateWithAnimation(
                                    context, '/notifications');
                              },
                            ),
                          ],
                        ),
                        const Divider(),
                        _DrawerSection(
                          title: 'Gamificação',
                          items: [
                            _DrawerItem(
                              icon: Icons.emoji_events,
                              title: 'Dashboard',
                              onTap: () {
                                _navigateWithAnimation(
                                    context, '/gamification');
                              },
                            ),
                            _DrawerItem(
                              icon: Icons.store,
                              title: 'Loja FluxoCoins',
                              onTap: () {
                                _navigateWithAnimation(context, '/store');
                              },
                            ),
                          ],
                        ),
                        const Divider(),
                        _DrawerSection(
                          title: 'Configurações',
                          items: [
                            _DrawerItem(
                              icon: Icons.person,
                              title: 'Perfil',
                              onTap: () {
                                _navigateWithAnimation(context, '/profile');
                              },
                            ),
                            _DrawerItem(
                              icon: Icons.workspace_premium,
                              title: 'Assinatura Premium',
                              onTap: () {
                                _navigateWithAnimation(
                                    context, '/subscription');
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Logout Button - Always visible at bottom
                  SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        const Divider(),
                        _DrawerItem(
                          icon: Icons.logout,
                          title: 'Sair',
                          onTap: () async {
                            Navigator.pop(context);
                            await ref.read(authServiceProvider).signOut();
                            if (context.mounted) {
                              context.go('/login');
                            }
                          },
                          isDestructive: true,
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateWithAnimation(BuildContext context, String route) {
    Navigator.pop(context);
    Future.delayed(const Duration(milliseconds: 250), () {
      if (context.mounted) {
        context.go(route);
      }
    });
  }
}

/// Drawer header with user information
class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({this.user});

  final dynamic user; // Using dynamic to avoid import issues

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Logo/Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                ),
                child: const Icon(
                  Icons.sync,
                  size: 32,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: AppTheme.spacingMd),

              // App Name
              Text(
                'SyncLife',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: AppTheme.spacingXs),

              // User Info or Welcome Message
              Text(
                user != null ? 'Bem-vindo!' : 'Organize sua vida',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section header for drawer items
class _DrawerSection extends StatelessWidget {
  const _DrawerSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingMd,
              AppTheme.spacingMd,
              AppTheme.spacingMd,
              AppTheme.spacingSm,
            ),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.neutralGray600,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          ...items,
        ],
      );
}

/// Individual drawer item
class _DrawerItem extends StatefulWidget {
  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  State<_DrawerItem> createState() => _DrawerItemState();
}

class _DrawerItemState extends State<_DrawerItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.isDestructive ? theme.colorScheme.error : null;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingSm,
            vertical: AppTheme.spacing2xs,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            color: Colors.transparent,
          ),
          child: ListTile(
            leading: Icon(
              widget.icon,
              color: color,
            ),
            title: Text(
              widget.title,
              style: TextStyle(color: color),
            ),
            onTap: () {
              _animationController.forward().then((_) {
                _animationController.reverse();
              });
              widget.onTap();
            },
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacing2xs,
            ),
            hoverColor: Colors.transparent,
            splashColor: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
      ),
    );
  }
}
