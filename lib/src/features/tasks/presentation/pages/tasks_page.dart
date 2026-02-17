import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/main_layout.dart';
import '../../../../core/onboarding/onboarding_overlay.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../monetization/domain/models/user_limitations.dart';
import '../../../monetization/presentation/utils/premium_utils.dart';
import '../../../monetization/presentation/widgets/limitation_banner.dart';
import '../../../monetization/presentation/widgets/usage_indicator.dart';
import '../../domain/models/models.dart';
import '../providers/board_providers.dart';
import '../providers/task_providers.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/create_board_dialog.dart';
import '../widgets/task_filter_bar.dart';
import '../widgets/task_list_item.dart';

class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  TaskFilter _selectedFilter = TaskFilter.all;
  List<String> _selectedTags = [];
  bool _filtersExpanded = false; // Estado para controlar expansão dos filtros
  List<String> _selectedBoardIds = []; // IDs dos boards selecionados

  final List<String> _availableTags = [
    'Health',
    'Work',
    'Home',
    'Finance',
    'Personal'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const MainLayout(
        title: 'SyncLife',
        child: Center(
          child: Text('Please log in to access your tasks'),
        ),
      );
    }

    return MainLayout(
      title: 'SyncLife',
      actions: [
        IconButton(
          key: SyncLifeOnboardingSteps.addTaskButtonKey,
          icon: const Icon(Icons.add),
          onPressed: () => _showAddTaskDialog(currentUser.id),
        ),
      ],
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.task_alt), text: 'Tasks'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTasksTab(currentUser.id),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksTab(String userId) {
    final userBoardsAsync = ref.watch(userBoardsProvider);

    return userBoardsAsync.when(
      data: (boards) {
        if (boards.isEmpty) {
          return _buildNoBoardsView(userId);
        }

        // Initialize selected boards if empty (select first board by default)
        if (_selectedBoardIds.isEmpty && boards.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedBoardIds = [boards.first.id];
            });
          });
        }

        // Get tasks from all selected boards
        return _buildTasksListWithBoardSelector(boards, userId);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading boards: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(userBoardsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksListWithBoardSelector(List<Board> boards, String userId) {
    if (_selectedBoardIds.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // For simplicity, let's use the first selected board for now
    // and show tasks from all selected boards
    final firstBoardId = _selectedBoardIds.first;
    final tasksAsync = ref.watch(watchTasksProvider(firstBoardId));

    return tasksAsync.when(
      data: (firstBoardTasks) {
        // Get tasks from all selected boards
        final allTasks = <Task>[...firstBoardTasks];
        
        // Add tasks from other selected boards
        for (int i = 1; i < _selectedBoardIds.length; i++) {
          final otherBoardAsync = ref.watch(watchTasksProvider(_selectedBoardIds[i]));
          otherBoardAsync.whenData((tasks) => allTasks.addAll(tasks));
        }

        return Column(
          children: [
            // Board selector
            _buildBoardSelector(boards),
            
            // Usage indicator for tasks
            const UsageIndicator(
              limitationType: LimitationType.activeTasks,
              compact: true,
            ),

            // Limitation banner if at limit
            const LimitationBanner(
              limitationType: LimitationType.activeTasks,
            ),

            // Collapsible filter section
            _buildCollapsibleFilters(),
            
            const Divider(height: 1),
            
            Expanded(
              key: SyncLifeOnboardingSteps.taskListKey,
              child: _buildTasksContent(allTasks, userId),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading tasks: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(watchTasksProvider(firstBoardId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksContent(List<Task> allTasks, String userId) {
    final filteredTasks = _getFilteredTasks(allTasks);
    
    if (filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to create your first task',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        return TaskListItem(
          task: task,
          onComplete: () => _completeTask(task),
          onPostpone: () => _postponeTask(task),
          onTap: () => _showTaskDetails(task),
        );
      },
    );
  }

  Widget _buildNoBoardsView(String userId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dashboard,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No boards found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first board to start organizing tasks',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateBoardDialog(userId),
            icon: const Icon(Icons.add),
            label: const Text('Criar Primeiro Quadro'),
          ),
        ],
      ),
    );
  }

  List<Task> _getFilteredTasks(List<Task> tasks) {
    final filtered = tasks.where((task) {
      // Apply filter
      switch (_selectedFilter) {
        case TaskFilter.all:
          break;
        case TaskFilter.pending:
          if (task.isCompleted) return false;
        case TaskFilter.completed:
          if (!task.isCompleted) return false;
        case TaskFilter.overdue:
          if (task.isCompleted || task.dueDate == null) return false;
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final taskDate = DateTime(
              task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
          if (!taskDate.isBefore(today)) return false;
        case TaskFilter.today:
          if (task.dueDate == null) return false;
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final taskDate = DateTime(
              task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
          if (!taskDate.isAtSameMomentAs(today)) return false;
        case TaskFilter.thisWeek:
          if (task.dueDate == null) return false;
          final now = DateTime.now();
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          final weekEnd = weekStart.add(const Duration(days: 6));
          if (task.dueDate!.isBefore(weekStart) ||
              task.dueDate!.isAfter(weekEnd)) {
            return false;
          }
      }

      // Apply tag filter
      if (_selectedTags.isNotEmpty) {
        if (!task.tags.any((tag) => _selectedTags.contains(tag))) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort by due date, then by creation date
    filtered.sort((a, b) {
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      } else if (a.dueDate != null) {
        return -1;
      } else if (b.dueDate != null) {
        return 1;
      } else {
        return b.createdAt.compareTo(a.createdAt);
      }
    });

    return filtered;
  }

  Widget _buildBoardSelector(List<Board> boards) {
    final selectedBoards = boards.where((board) => _selectedBoardIds.contains(board.id)).toList();
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: () => _showBoardSelectionModal(boards),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.dashboard,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedBoards.length == 1 
                          ? selectedBoards.first.name
                          : '${selectedBoards.length} quadros selecionados',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (selectedBoards.length > 1) ...[
                      const SizedBox(height: 4),
                      Text(
                        selectedBoards.map((b) => b.name).join(', '),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showBoardSelectionModal(List<Board> boards) async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BoardSelectionModal(
        boards: boards,
        selectedBoardIds: _selectedBoardIds,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedBoardIds = result;
      });
    }
  }

  Widget _buildCollapsibleFilters() {
    return Column(
      children: [
        // Filter toggle button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _filtersExpanded = !_filtersExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filtros',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  // Show active filter count if any filters are applied
                  if (_selectedFilter != TaskFilter.all || _selectedTags.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _getActiveFilterCount().toString(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  
                  // Clear filters button (only show when filters are active)
                  if (_selectedFilter != TaskFilter.all || _selectedTags.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedFilter = TaskFilter.all;
                          _selectedTags.clear();
                        });
                      },
                      icon: const Icon(Icons.clear_all),
                      tooltip: 'Limpar todos os filtros',
                      iconSize: 20,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  AnimatedRotation(
                    turns: _filtersExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Expandable filter content
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: _filtersExpanded ? null : 0,
          child: _filtersExpanded
              ? TaskFilterBar(
                  selectedFilter: _selectedFilter,
                  onFilterChanged: (filter) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  selectedTags: _selectedTags,
                  onTagsChanged: (tags) {
                    setState(() {
                      _selectedTags = tags;
                    });
                  },
                  availableTags: _availableTags,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedFilter != TaskFilter.all) count++;
    count += _selectedTags.length;
    return count;
  }

  Future<void> _completeTask(Task task) async {
    try {
      final taskService = ref.read(taskServiceProvider);
      await taskService.completeTask(task.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task "${task.title}" completed! 🎉'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _postponeTask(Task task) async {
    try {
      // Calculate next occurrence based on recurrence
      DateTime? nextDueDate;
      if (task.dueDate != null) {
        switch (task.recurrence) {
          case TaskRecurrence.daily:
            nextDueDate = task.dueDate!.add(const Duration(days: 1));
          case TaskRecurrence.weekly:
            nextDueDate = task.dueDate!.add(const Duration(days: 7));
          case TaskRecurrence.monthly:
            nextDueDate = DateTime(
              task.dueDate!.year,
              task.dueDate!.month + 1,
              task.dueDate!.day,
            );
          case TaskRecurrence.none:
          case TaskRecurrence.custom:
            nextDueDate = task.dueDate!.add(const Duration(days: 1));
        }
      }

      final taskService = ref.read(taskServiceProvider);
      await taskService.updateTask(
        task.id,
        UpdateTaskRequest(dueDate: nextDueDate),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task "${task.title}" postponed'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error postponing task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTaskDetails(Task task) {
    context.push('/tasks/detail/${task.id}', extra: task);
  }

  void _showCreateBoardDialog(String userId) {
    showDialog<void>(
      context: context,
      builder: (context) => CreateBoardDialog(
        onCreateBoard: (request) => _createBoard(request, userId),
      ),
    );
  }

  Future<void> _createBoard(CreateBoardRequest request, String userId) async {
    try {
      final boardService = ref.read(boardServiceProvider);
      await boardService.createBoard(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quadro criado com sucesso! 🎉'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar quadro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createDefaultBoardSilently(String userId) async {
    try {
      final boardService = ref.read(boardServiceProvider);
      await boardService.createBoard(
        CreateBoardRequest(
          name: 'Minhas Tarefas',
          description: 'Quadro padrão para tarefas pessoais',
          type: BoardType.private,
          ownerId: userId,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar quadro padrão: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showAddTaskDialog(String userId) async {
    try {
      // Check if user can create more tasks
      final canCreate = await PremiumUtils.checkAndPromptForAction(
        context,
        ref,
        userId,
        LimitationType.activeTasks,
        customMessage:
            'You\'ve reached your task limit. Upgrade to Premium for unlimited tasks.',
      );

      if (!canCreate) return;

      // Get user's boards - since it's a StreamProvider, we need to read the current value
      final userBoardsAsync = ref.read(userBoardsProvider);

      await userBoardsAsync.when(
        data: (boards) async {
          if (boards.isEmpty) {
            // Create default board first
            await _createDefaultBoardSilently(userId);
            // Refresh boards and wait a bit for the update
            ref.invalidate(userBoardsProvider);
            await Future.delayed(const Duration(milliseconds: 500));

            // Try to get updated boards
            final updatedBoardsAsync = ref.read(userBoardsProvider);
            await updatedBoardsAsync.when(
              data: (updatedBoards) async {
                if (updatedBoards.isEmpty) {
                  throw Exception('Failed to create default board');
                }
                await _showTaskDialog(updatedBoards, userId);
              },
              loading: () async {
                throw Exception('Still loading boards after creation...');
              },
              error: (error, stack) async {
                throw Exception('Error loading updated boards: $error');
              },
            );
          } else {
            await _showTaskDialog(boards, userId);
          }
        },
        loading: () async {
          throw Exception('Loading boards...');
        },
        error: (error, stack) async {
          throw Exception('Error loading boards: $error');
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening task dialog: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showTaskDialog(List<Board> boards, String userId) async {
    if (mounted) {
      await showDialog(
        context: context,
        builder: (context) => AddTaskDialog(
          onCreateTask: (request) => _createTask(request),
          availableTags: _availableTags,
          availableBoards: boards,
          userId: userId,
          selectedBoardId: _selectedBoardIds.isNotEmpty ? _selectedBoardIds.first : null,
        ),
      );
    }
  }

  Future<void> _createTask(CreateTaskRequest request) async {
    try {
      final taskService = ref.read(taskServiceProvider);
      await taskService.createTask(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task "${request.title}" created successfully! 🎉'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Modal for selecting multiple boards
class _BoardSelectionModal extends StatefulWidget {
  const _BoardSelectionModal({
    required this.boards,
    required this.selectedBoardIds,
  });

  final List<Board> boards;
  final List<String> selectedBoardIds;

  @override
  State<_BoardSelectionModal> createState() => _BoardSelectionModalState();
}

class _BoardSelectionModalState extends State<_BoardSelectionModal> {
  late List<String> _tempSelectedIds;

  @override
  void initState() {
    super.initState();
    _tempSelectedIds = List.from(widget.selectedBoardIds);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      'Selecionar Quadros',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (_tempSelectedIds.length == widget.boards.length) {
                            _tempSelectedIds.clear();
                          } else {
                            _tempSelectedIds = widget.boards.map((b) => b.id).toList();
                          }
                        });
                      },
                      child: Text(
                        _tempSelectedIds.length == widget.boards.length 
                            ? 'Desmarcar Todos' 
                            : 'Selecionar Todos',
                      ),
                    ),
                  ],
                ),
              ),
              
              // Board list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: widget.boards.length,
                  itemBuilder: (context, index) {
                    final board = widget.boards[index];
                    final isSelected = _tempSelectedIds.contains(board.id);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _tempSelectedIds.add(board.id);
                            } else {
                              _tempSelectedIds.remove(board.id);
                            }
                          });
                        },
                        title: Text(
                          board.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: board.description != null 
                            ? Text(
                                board.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.dashboard,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    );
                  },
                ),
              ),
              
              // Action buttons
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _tempSelectedIds.isEmpty 
                            ? null 
                            : () => Navigator.of(context).pop(_tempSelectedIds),
                        child: Text(
                          'Aplicar (${_tempSelectedIds.length})',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}