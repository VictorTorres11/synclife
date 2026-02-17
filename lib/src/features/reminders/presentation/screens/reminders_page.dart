import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/main_layout.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../features/monetization/presentation/providers/monetization_providers.dart';
import '../../domain/models/reminder.dart';
import '../providers/reminder_providers.dart';
import '../widgets/widgets.dart';

/// Main screen for viewing and managing reminders
///
/// Displays:
/// - AppBar with search functionality
/// - Board filter component
/// - Usage indicator for free users
/// - List of reminders
/// - FAB for creating new reminders
class RemindersPage extends ConsumerStatefulWidget {
  const RemindersPage({super.key});

  @override
  ConsumerState<RemindersPage> createState() => _RemindersPageState();
}

/// State for RemindersPage
class _RemindersPageState extends ConsumerState<RemindersPage> {
  /// Whether search mode is active
  bool _isSearching = false;
  
  /// Controller for search input field
  final TextEditingController _searchController = TextEditingController();
  
  /// Timer for debouncing search input
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Handles search input changes with debouncing
  /// 
  /// Debounces search input by 300ms to avoid excessive filtering
  /// while the user is still typing.
  void _onSearchChanged() {
    // Cancel previous timer if it exists
    _debounceTimer?.cancel();
    
    // Create new timer with 300ms delay
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(reminderSearchQueryProvider.notifier).state =
          _searchController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const MainLayout(
        child: Center(
          child: Text('Please log in to view reminders'),
        ),
      );
    }

    return MainLayout(
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: Column(
            children: [
              // Board filter
              const ReminderBoardFilter(),

              // Usage indicator for free users
              _buildUsageIndicator(currentUser.id),

              // Reminders list
              Expanded(
                child: _buildRemindersList(currentUser.id),
              ),
            ],
          ),
        ),
        floatingActionButton: Semantics(
          label: 'Add new reminder',
          button: true,
          hint: 'Double tap to create a new reminder',
          child: FloatingActionButton(
            onPressed: () => _showAddReminderDialog(context, currentUser.id),
            tooltip: 'Add Reminder',
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  /// Builds the app bar with search functionality
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search reminders...',
                border: InputBorder.none,
              ),
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            )
          : const Text('Reminders'),
      actions: [
        Semantics(
          label: _isSearching ? 'Close search' : 'Search reminders',
          button: true,
          child: IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? 'Close search' : 'Search',
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  ref.read(reminderSearchQueryProvider.notifier).state = '';
                }
                _isSearching = !_isSearching;
              });
            },
            constraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the usage indicator widget for free users
  Widget _buildUsageIndicator(String userId) {
    final userLimitationsAsync = ref.watch(userLimitationsProvider(userId));

    return userLimitationsAsync.when(
      data: (limitations) {
        // Only show for free users
        if (limitations.maxReminders == -1) {
          return const SizedBox.shrink();
        }

        return const ReminderUsageIndicator();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Builds the main reminders list with loading and error states
  Widget _buildRemindersList(String userId) {
    final filteredRemindersAsync = ref.watch(filteredRemindersProvider);

    return filteredRemindersAsync.when(
      data: (reminders) {
        if (reminders.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reminders.length,
          itemBuilder: (context, index) {
            final reminder = reminders[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ReminderCard(
                reminder: reminder,
                onEdit: () => _showEditReminderDialog(context, reminder),
                onDelete: () => _showDeleteConfirmation(context, reminder),
                onConvert: () => _showConvertReminderDialog(context, reminder),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  /// Builds the empty state message
  /// 
  /// Shows different messages based on whether filters are active.
  Widget _buildEmptyState() {
    final searchQuery = ref.watch(reminderSearchQueryProvider);
    final selectedBoard = ref.watch(selectedBoardFilterProvider);

    String message;
    if (searchQuery.isNotEmpty) {
      message = 'No reminders found matching "$searchQuery"';
    } else if (selectedBoard != null) {
      message = 'No reminders in this board yet';
    } else {
      message = 'No reminders yet';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (searchQuery.isEmpty && selectedBoard == null) ...[
            const SizedBox(height: 8),
            Text(
              'Tap the + button to create your first reminder',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the error state with retry button
  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading reminders',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(remindersStreamProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Handles pull-to-refresh action
  Future<void> _onRefresh() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      ref.invalidate(remindersStreamProvider(currentUser.id));
      // Wait a bit for the refresh to complete
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  // Action methods

  /// Shows the add reminder dialog with limitation check
  /// 
  /// Checks if the user can create more reminders before showing the dialog.
  /// If the user has reached their limit, shows an upgrade prompt instead.
  Future<void> _showAddReminderDialog(
    BuildContext context,
    String userId,
  ) async {
    // Check limitations before showing dialog
    final userLimitationsAsync = ref.read(userLimitationsProvider(userId));

    await userLimitationsAsync.when(
      data: (limitations) async {
        if (!limitations.canCreateMoreReminders) {
          // Show upgrade prompt
          if (context.mounted) {
            _showUpgradePrompt(context);
          }
          return;
        }

        // Show add dialog
        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (context) => const AddReminderDialog(),
          );
        }
      },
      loading: () async {
        // Show loading indicator
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Loading...')),
          );
        }
      },
      error: (error, stack) async {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${error.toString()}')),
          );
        }
      },
    );
  }

  /// Shows the edit reminder dialog
  Future<void> _showEditReminderDialog(
    BuildContext context,
    Reminder reminder,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => EditReminderDialog(reminder: reminder),
    );
  }

  /// Shows delete confirmation dialog
  /// 
  /// Displays a confirmation dialog before deleting the reminder.
  /// If confirmed, calls [_deleteReminder] to perform the deletion.
  Future<void> _showDeleteConfirmation(
    BuildContext context,
    Reminder reminder,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Lembrete'),
        content: const Text(
          'Tem certeza que deseja excluir este lembrete? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _deleteReminder(context, reminder);
    }
  }

  /// Deletes a reminder and shows feedback
  /// 
  /// Performs the deletion and displays a success or error message.
  Future<void> _deleteReminder(
    BuildContext context,
    Reminder reminder,
  ) async {
    try {
      final reminderService = ref.read(reminderServiceProvider);
      await reminderService.deleteReminder(reminder.id, reminder.userId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lembrete excluído'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir lembrete: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Shows the convert reminder to task dialog
  /// 
  /// Displays a dialog to convert the reminder into a full task.
  /// Shows success feedback if the conversion is successful.
  Future<void> _showConvertReminderDialog(
    BuildContext context,
    Reminder reminder,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConvertReminderDialog(reminder: reminder),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Convertido em tarefa'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Shows upgrade prompt dialog for free users at limit
  /// 
  /// Displays information about the reminder limit and provides
  /// an option to upgrade to premium for unlimited reminders.
  void _showUpgradePrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limite de Lembretes Atingido'),
        content: const Text(
          'Você atingiu o limite de 30 lembretes. Faça upgrade para Premium e tenha lembretes ilimitados e muito mais!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to subscription screen
              // TODO: Implement navigation to subscription screen
              // context.go('/subscription');
            },
            child: const Text('Fazer Upgrade'),
          ),
        ],
      ),
    );
  }
}
