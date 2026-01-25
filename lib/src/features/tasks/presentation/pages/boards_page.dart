import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/board.dart';
import '../../domain/models/board_type.dart';
import '../../domain/models/create_board_request.dart';
import '../../domain/services/board_service.dart';
import '../widgets/board_list_item.dart';
import '../widgets/create_board_dialog.dart';
import '../widgets/invite_users_dialog.dart';
import '../../../../core/layout/main_layout.dart';

/// Page for managing boards (private and shared)
class BoardsPage extends StatefulWidget {
  const BoardsPage({
    super.key,
    required this.boardService,
  });

  final BoardService boardService;

  @override
  State<BoardsPage> createState() => _BoardsPageState();
}

class _BoardsPageState extends State<BoardsPage> {
  late Stream<List<Board>> _boardsStream;
  
  @override
  void initState() {
    super.initState();
    _boardsStream = widget.boardService.watchUserBoards();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Meus Quadros',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: _showCreateBoardDialog,
          tooltip: 'Criar Quadro',
        ),
      ],
      child: StreamBuilder<List<Board>>(
        stream: _boardsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading boards: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _boardsStream = widget.boardService.watchUserBoards();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final boards = snapshot.data ?? [];

          if (boards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.dashboard_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No boards yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your first board to get started',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showCreateBoardDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Board'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: boards.length,
            itemBuilder: (context, index) {
              final board = boards[index];
              return BoardListItem(
                board: board,
                onTap: () => _openBoard(board),
                onInvite: board.type == BoardType.shared 
                    ? () => _showInviteDialog(board) 
                    : null,
                onGenerateLink: board.type == BoardType.shared 
                    ? () => _generateInviteLink(board) 
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateBoardDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => CreateBoardDialog(
        onCreateBoard: _createBoard,
      ),
    );
  }

  void _showInviteDialog(Board board) {
    showDialog<void>(
      context: context,
      builder: (context) => InviteUsersDialog(
        board: board,
        boardService: widget.boardService,
      ),
    );
  }

  Future<void> _createBoard(CreateBoardRequest request) async {
    try {
      await widget.boardService.createBoard(request);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Board created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create board: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateInviteLink(Board board) async {
    try {
      final inviteLink = await widget.boardService.generateInviteLink(board.id);
      
      if (mounted) {
        await Clipboard.setData(ClipboardData(text: inviteLink));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invite link copied to clipboard'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate invite link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openBoard(Board board) {
    // Navigate to board details/tasks page
    // This would be implemented based on the app's navigation structure
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening board: ${board.name}'),
      ),
    );
  }
}