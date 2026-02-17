import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../features/tasks/domain/models/board.dart';
import '../../../../features/tasks/presentation/providers/board_providers.dart';
import '../providers/reminder_providers.dart';

/// Expandable board filter widget for filtering reminders by board
///
/// Displays a collapsible section with:
/// - "All Boards" option to show all reminders
/// - List of user's boards with reminder counts
/// - Highlights the currently selected board
class ReminderBoardFilter extends ConsumerStatefulWidget {
  const ReminderBoardFilter({super.key});

  @override
  ConsumerState<ReminderBoardFilter> createState() =>
      _ReminderBoardFilterState();
}

/// State for ReminderBoardFilter
class _ReminderBoardFilterState extends ConsumerState<ReminderBoardFilter> {
  /// Whether the filter section is expanded
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userBoardsAsync = ref.watch(userBoardsProvider);
    final selectedBoardId = ref.watch(selectedBoardFilterProvider);
    final remindersAsync = ref.watch(filteredRemindersProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header with expand/collapse button
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Filter by Board',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          if (_isExpanded)
            userBoardsAsync.when(
              data: (boards) => _buildBoardList(
                boards,
                selectedBoardId,
                remindersAsync,
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error loading boards',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBoardList(
    List<Board> boards,
    String? selectedBoardId,
    AsyncValue<List<dynamic>> remindersAsync,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const Divider(height: 1),

        // "All Boards" option
        _buildBoardOption(
          boardId: null,
          boardName: 'All Boards',
          isSelected: selectedBoardId == null,
          reminderCount: remindersAsync.when(
            data: (reminders) => reminders.length,
            loading: () => 0,
            error: (_, __) => 0,
          ),
          theme: theme,
        ),

        // Individual boards
        ...boards.map((board) {
          final reminderCount = _getReminderCountForBoard(
            board.id,
            remindersAsync,
          );

          return _buildBoardOption(
            boardId: board.id,
            boardName: board.name,
            isSelected: selectedBoardId == board.id,
            reminderCount: reminderCount,
            theme: theme,
          );
        }),
      ],
    );
  }

  Widget _buildBoardOption({
    required String? boardId,
    required String boardName,
    required bool isSelected,
    required int reminderCount,
    required ThemeData theme,
  }) {
    return Semantics(
      label: boardId == null
          ? 'Show all boards, $reminderCount reminders'
          : 'Filter by $boardName, $reminderCount reminders',
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: () {
          // Update the selected board filter
          ref.read(selectedBoardFilterProvider.notifier).state = boardId;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                : null,
            border: Border(
              left: BorderSide(
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          child: Row(
            children: [
              // Board icon
              Icon(
                boardId == null ? Icons.dashboard : Icons.folder,
                size: 20,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 12),

              // Board name
              Expanded(
                child: Text(
                  boardName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),

              // Reminder count badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  reminderCount.toString(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get the count of reminders for a specific board
  int _getReminderCountForBoard(
    String boardId,
    AsyncValue<List<dynamic>> remindersAsync,
  ) {
    return remindersAsync.when(
      data: (reminders) {
        // We need to get all reminders (not filtered) to show accurate counts
        // So we'll watch the unfiltered stream
        final user = ref.read(currentUserProvider);
        if (user == null) return 0;

        final allRemindersAsync = ref.read(remindersStreamProvider(user.id));
        return allRemindersAsync.when(
          data: (allReminders) =>
              allReminders.where((r) => r.boardId == boardId).length,
          loading: () => 0,
          error: (_, __) => 0,
        );
      },
      loading: () => 0,
      error: (_, __) => 0,
    );
  }
}
