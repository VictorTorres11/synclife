import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/main_layout.dart';
import '../../domain/models/board.dart';
import '../../domain/models/board_type.dart';
import '../../domain/models/create_board_request.dart';
import '../../domain/services/board_service.dart';
import '../providers/board_providers.dart';
import '../widgets/board_management_card.dart';
import '../widgets/create_board_dialog.dart';
import '../widgets/board_members_dialog.dart';
import '../widgets/board_settings_dialog.dart';

/// Enhanced board management screen with full CRUD operations
class BoardManagementScreen extends ConsumerStatefulWidget {
  const BoardManagementScreen({super.key});

  @override
  ConsumerState<BoardManagementScreen> createState() =>
      _BoardManagementScreenState();
}

class _BoardManagementScreenState extends ConsumerState<BoardManagementScreen>
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
    final boardsAsync = ref.watch(userBoardsProvider);

    return MainLayout(
      title: 'Gerenciar Quadros',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: _showCreateBoardDialog,
          tooltip: 'Criar Quadro',
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _showSearchDialog,
          tooltip: 'Buscar Quadros',
        ),
      ],
      child: Column(
        children: [
          // Tab Bar
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Todos', icon: Icon(Icons.dashboard)),
                Tab(text: 'Privados', icon: Icon(Icons.lock)),
                Tab(text: 'Compartilhados', icon: Icon(Icons.group)),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: boardsAsync.when(
              data: (boards) => _buildBoardTabs(boards),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardTabs(List<Board> allBoards) {
    final filteredBoards = _filterBoards(allBoards);
    final privateBoards =
        filteredBoards.where((b) => b.type == BoardType.private).toList();
    final sharedBoards =
        filteredBoards.where((b) => b.type == BoardType.shared).toList();

    return TabBarView(
      controller: _tabController,
      children: [
        _buildBoardList(filteredBoards, 'Nenhum quadro encontrado'),
        _buildBoardList(privateBoards, 'Nenhum quadro privado'),
        _buildBoardList(sharedBoards, 'Nenhum quadro compartilhado'),
      ],
    );
  }

  Widget _buildBoardList(List<Board> boards, String emptyMessage) {
    if (boards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dashboard_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crie um novo quadro para começar',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showCreateBoardDialog,
              icon: const Icon(Icons.add),
              label: const Text('Criar Quadro'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userBoardsProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: boards.length,
        itemBuilder: (context, index) {
          final board = boards[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: BoardManagementCard(
              board: board,
              onTap: () => _openBoard(board),
              onEdit: () => _editBoard(board),
              onMembers: board.type == BoardType.shared
                  ? () => _showMembersDialog(board)
                  : null,
              onSettings: () => _showSettingsDialog(board),
              onDelete: () => _confirmDeleteBoard(board),
            ),
          );
        },
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
            'Erro ao carregar quadros',
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
            onPressed: () => ref.invalidate(userBoardsProvider),
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  List<Board> _filterBoards(List<Board> boards) {
    if (_searchQuery.isEmpty) return boards;

    return boards.where((board) {
      return board.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (board.description
                  ?.toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ??
              false);
    }).toList();
  }

  void _showCreateBoardDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => CreateBoardDialog(
        onCreateBoard: _createBoard,
      ),
    );
  }

  void _showSearchDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buscar Quadros'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Digite o nome do quadro...',
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

  void _showMembersDialog(Board board) {
    showDialog<void>(
      context: context,
      builder: (context) => BoardMembersDialog(board: board),
    );
  }

  void _showSettingsDialog(Board board) {
    showDialog<void>(
      context: context,
      builder: (context) => BoardSettingsDialog(board: board),
    );
  }

  Future<void> _createBoard(CreateBoardRequest request) async {
    try {
      final boardService = ref.read(boardServiceProvider);
      await boardService.createBoard(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quadro criado com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on Exception catch (e) {
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

  void _editBoard(Board board) {
    showDialog<void>(
      context: context,
      builder: (context) => CreateBoardDialog(
        onCreateBoard: (request) => _updateBoard(board.id, request),
      ),
    );
  }

  Future<void> _updateBoard(String boardId, CreateBoardRequest request) async {
    try {
      final boardService = ref.read(boardServiceProvider);
      await boardService.updateBoard(boardId, {
        'name': request.name,
        'description': request.description,
        'type': request.type.toJson(),
        'settings': request.settings?.toMap(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quadro atualizado com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar quadro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDeleteBoard(Board board) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Quadro'),
        content: Text(
          'Tem certeza que deseja excluir o quadro "${board.name}"? '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteBoard(board);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBoard(Board board) async {
    try {
      final boardService = ref.read(boardServiceProvider);
      await boardService.leaveBoard(board.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quadro excluído com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir quadro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openBoard(Board board) {
    // Navigate to board tasks view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abrindo quadro: ${board.name}'),
      ),
    );
  }
}
