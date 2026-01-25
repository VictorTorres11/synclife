import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/board.dart';
import '../../domain/models/board_invitation.dart';
import '../providers/board_providers.dart';

/// Tab for managing pending invitations
class PendingInvitesTab extends ConsumerStatefulWidget {
  const PendingInvitesTab({
    super.key,
    required this.board,
  });

  final Board board;

  @override
  ConsumerState<PendingInvitesTab> createState() => _PendingInvitesTabState();
}

class _PendingInvitesTabState extends ConsumerState<PendingInvitesTab> {
  List<BoardInvitation> _pendingInvites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingInvites();
  }

  Future<void> _loadPendingInvites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final invitationService = ref.read(boardInvitationServiceProvider);
      final invites =
          await invitationService.getPendingInvitations(widget.board.id);

      if (mounted) {
        setState(() {
          _pendingInvites = invites;
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
            content: Text('Erro ao carregar convites: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingInvites.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadPendingInvites,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingInvites.length,
        itemBuilder: (context, index) {
          final invite = _pendingInvites[index];
          return _buildInviteCard(invite);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pending_actions,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum convite pendente',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Todos os convites foram aceitos ou expirados',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCard(BoardInvitation invite) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with email and status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invite.inviteeEmail,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Convidado por ${invite.inviterName}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(invite.status),
              ],
            ),

            const SizedBox(height: 12),

            // Invite details
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Enviado ${_formatTimeAgo(invite.createdAt)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.code, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  invite.inviteCode,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),

            if (invite.message != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  invite.message!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _resendInvite(invite),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reenviar'),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _cancelInvite(invite),
                  icon: const Icon(Icons.cancel, size: 16, color: Colors.red),
                  label: const Text('Cancelar',
                      style: TextStyle(color: Colors.red)),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BoardInvitationStatus status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case BoardInvitationStatus.pending:
        color = Colors.orange;
        label = 'Pendente';
        icon = Icons.pending;
        break;
      case BoardInvitationStatus.accepted:
        color = Colors.green;
        label = 'Aceito';
        icon = Icons.check_circle;
        break;
      case BoardInvitationStatus.declined:
        color = Colors.red;
        label = 'Recusado';
        icon = Icons.cancel;
        break;
      case BoardInvitationStatus.expired:
        color = Colors.grey;
        label = 'Expirado';
        icon = Icons.access_time;
        break;
      case BoardInvitationStatus.cancelled:
        color = Colors.grey;
        label = 'Cancelado';
        icon = Icons.block;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return 'há ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'há ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'há ${difference.inDays} dias';
    } else {
      return 'há ${(difference.inDays / 7).floor()} semanas';
    }
  }

  Future<void> _resendInvite(BoardInvitation invite) async {
    try {
      final invitationService = ref.read(boardInvitationServiceProvider);
      await invitationService.resendInvitation(invite.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Convite reenviado para ${invite.inviteeEmail}'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload the list to show updated data
        _loadPendingInvites();
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao reenviar convite: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelInvite(BoardInvitation invite) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Convite'),
        content: Text(
          'Tem certeza que deseja cancelar o convite para ${invite.inviteeEmail}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancelar Convite'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        final invitationService = ref.read(boardInvitationServiceProvider);
        await invitationService.cancelBoardInvitation(invite.id);

        setState(() {
          _pendingInvites.removeWhere((i) => i.id == invite.id);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Convite para ${invite.inviteeEmail} foi cancelado'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } on Exception catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao cancelar convite: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
