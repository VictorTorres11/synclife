import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/models/user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/board.dart';
import '../providers/board_providers.dart';
import 'invite_users_dialog.dart';

/// Dialog for managing board members and permissions
class BoardMembersDialog extends ConsumerStatefulWidget {
  const BoardMembersDialog({
    super.key,
    required this.board,
  });

  final Board board;

  @override
  ConsumerState<BoardMembersDialog> createState() => _BoardMembersDialogState();
}

class _BoardMembersDialogState extends ConsumerState<BoardMembersDialog> {
  List<User> _members = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final boardService = ref.read(boardServiceProvider);
      final authService = ref.read(authServiceProvider);

      // Get current user ID
      final currentUser = await authService.getCurrentUser();
      _currentUserId = currentUser?.uid;

      // Load member details
      final members = <User>[];
      for (final memberId in widget.board.memberIds) {
        try {
          final users = await boardService.searchUsers(memberId);
          if (users.isNotEmpty) {
            members.add(users.first);
          }
        } on Exception catch (_) {
          // If user not found, create a placeholder
          members.add(User(
            id: memberId,
            email: 'user@unknown.com',
            displayName: 'Unknown User',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }
      }

      if (mounted) {
        setState(() {
          _members = members;
          _isLoading = false;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar membros: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.group),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Membros - ${widget.board.name}'),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with member count and invite button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_members.length} ${_members.length == 1 ? 'membro' : 'membros'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                ElevatedButton.icon(
                  onPressed: _showInviteDialog,
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('Convidar'),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),

            // Members list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildMembersList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  Widget _buildMembersList() {
    if (_members.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum membro encontrado',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        final isOwner = member.uid == widget.board.ownerId;
        final isCurrentUser = member.uid == _currentUserId;
        final canRemove = !isOwner &&
            !isCurrentUser &&
            _currentUserId == widget.board.ownerId;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: member.photoURL != null
                  ? NetworkImage(member.photoURL!)
                  : null,
              child: member.photoURL == null
                  ? Text(
                      (member.displayName?.substring(0, 1) ?? 'U')
                          .toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    member.displayName ?? 'Nome não disponível',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                if (isOwner) _buildOwnerBadge(),
                if (isCurrentUser && !isOwner) _buildCurrentUserBadge(),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.email),
                const SizedBox(height: 4),
                _buildMemberStatus(member),
              ],
            ),
            trailing: canRemove
                ? PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'remove') {
                        _confirmRemoveMember(member);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(Icons.person_remove,
                                color: Colors.red, size: 16),
                            SizedBox(width: 8),
                            Text('Remover',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildOwnerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 12, color: Colors.amber[700]),
          const SizedBox(width: 2),
          Text(
            'Dono',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.amber[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentUserBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[300]!),
      ),
      child: Text(
        'Você',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  Widget _buildMemberStatus(User member) {
    // This would typically show online/offline status
    // For now, we'll show a placeholder
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.green[400], // Would be dynamic based on actual status
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'Online', // Would be dynamic
          style: TextStyle(
            fontSize: 12,
            color: Colors.green[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showInviteDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => InviteUsersDialog(
        board: widget.board,
        boardService: ref.read(boardServiceProvider),
      ),
    );
  }

  void _confirmRemoveMember(User member) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Membro'),
        content: Text(
          'Tem certeza que deseja remover ${member.displayName ?? member.email} '
          'do quadro "${widget.board.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeMember(member);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMember(User member) async {
    try {
      final boardService = ref.read(boardServiceProvider);
      await boardService.removeMember(widget.board.id, member.uid);

      // Refresh members list
      await _loadMembers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.displayName ?? member.email} foi removido'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover membro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
