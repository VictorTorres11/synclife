import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/models/user.dart';
import '../../domain/models/board.dart';
import '../../domain/models/board_invitation.dart';
import '../providers/board_providers.dart';
import 'invite_history_tab.dart';
import 'pending_invites_tab.dart';
import 'send_invite_tab.dart';

/// Enhanced dialog for comprehensive invite management
class EnhancedInviteDialog extends ConsumerStatefulWidget {
  const EnhancedInviteDialog({
    super.key,
    required this.board,
  });

  final Board board;

  @override
  ConsumerState<EnhancedInviteDialog> createState() =>
      _EnhancedInviteDialogState();
}

class _EnhancedInviteDialogState extends ConsumerState<EnhancedInviteDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _inviteLink;
  bool _isGeneratingLink = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _generateInviteLink();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 16),

            // Invite Link Section
            _buildInviteLinkSection(),
            const SizedBox(height: 24),

            // Tab Bar
            _buildTabBar(),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  SendInviteTab(board: widget.board),
                  PendingInvitesTab(board: widget.board),
                  // InviteHistoryTab(board: widget.board), // Commented out until implemented
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: const Center(
                      child: Text('Invite History - Coming Soon'),
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.group_add,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Convidar para ${widget.board.name}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                'Gerencie convites e membros do quadro',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          tooltip: 'Fechar',
        ),
      ],
    );
  }

  Widget _buildInviteLinkSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Link de Convite',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Compartilhe este link para convidar pessoas para o quadro',
            style: TextStyle(
              color: Colors.blue[600],
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[300]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _isGeneratingLink
                      ? Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.blue[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('Gerando link...'),
                          ],
                        )
                      : Text(
                          _inviteLink ?? 'Erro ao gerar link',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _inviteLink != null ? _copyInviteLink : null,
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Copiar Link',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue[100],
                        foregroundColor: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: _inviteLink != null ? _shareInviteLink : null,
                      icon: const Icon(Icons.share, size: 18),
                      tooltip: 'Compartilhar',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue[100],
                        foregroundColor: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(6),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.w500),
        tabs: const [
          Tab(
            icon: Icon(Icons.send, size: 18),
            text: 'Enviar',
          ),
          Tab(
            icon: Icon(Icons.pending_actions, size: 18),
            text: 'Pendentes',
          ),
          Tab(
            icon: Icon(Icons.history, size: 18),
            text: 'Histórico',
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  Future<void> _generateInviteLink() async {
    setState(() {
      _isGeneratingLink = true;
    });

    try {
      final boardService = ref.read(boardServiceProvider);
      final link = await boardService.generateInviteLink(widget.board.id);

      if (mounted) {
        setState(() {
          _inviteLink = link;
          _isGeneratingLink = false;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _isGeneratingLink = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _copyInviteLink() async {
    if (_inviteLink != null) {
      await Clipboard.setData(ClipboardData(text: _inviteLink!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Link copiado para a área de transferência'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<void> _shareInviteLink() async {
    if (_inviteLink != null) {
      // This would integrate with platform sharing
      // For now, just copy to clipboard
      await _copyInviteLink();
    }
  }
}
