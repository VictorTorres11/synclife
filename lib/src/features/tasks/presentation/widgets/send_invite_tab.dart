import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/models/user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/board.dart';
import '../providers/board_providers.dart';

/// Tab for sending new invitations
class SendInviteTab extends ConsumerStatefulWidget {
  const SendInviteTab({
    super.key,
    required this.board,
  });

  final Board board;

  @override
  ConsumerState<SendInviteTab> createState() => _SendInviteTabState();
}

class _SendInviteTabState extends ConsumerState<SendInviteTab> {
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();
  final _bulkEmailsController = TextEditingController();

  List<User> _searchResults = [];
  List<String> _selectedEmails = [];
  bool _isSearching = false;
  bool _isSendingInvite = false;
  bool _showBulkInvite = false;

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    _bulkEmailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle between single and bulk invite
            _buildInviteTypeToggle(),
            const SizedBox(height: 16),

            if (_showBulkInvite) ...[
              _buildBulkInviteSection(),
            ] else ...[
              _buildSingleInviteSection(),
              const SizedBox(height: 24),
              _buildUserSearchSection(),
            ],

            const SizedBox(height: 24),
            _buildMessageSection(),
            const SizedBox(height: 24),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showBulkInvite = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !_showBulkInvite ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: !_showBulkInvite
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Convite Individual',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight:
                        !_showBulkInvite ? FontWeight.w600 : FontWeight.normal,
                    color: !_showBulkInvite ? Colors.black : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showBulkInvite = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _showBulkInvite ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: _showBulkInvite
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Convite em Massa',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight:
                        _showBulkInvite ? FontWeight.w600 : FontWeight.normal,
                    color: _showBulkInvite ? Colors.black : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleInviteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Convite Direto',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Envie um convite direto para um endereço de email específico',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Endereço de Email',
            hintText: 'usuario@exemplo.com',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: _validateEmail,
        ),
      ],
    );
  }

  Widget _buildBulkInviteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Convite em Massa',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Envie convites para múltiplos emails de uma vez (separados por vírgula ou quebra de linha)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bulkEmailsController,
          decoration: const InputDecoration(
            labelText: 'Endereços de Email',
            hintText:
                'email1@exemplo.com, email2@exemplo.com\nemail3@exemplo.com',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
          maxLines: 4,
          keyboardType: TextInputType.multiline,
        ),
        const SizedBox(height: 8),
        if (_selectedEmails.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _selectedEmails
                .map((email) => Chip(
                      label: Text(email),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _selectedEmails.remove(email);
                        });
                      },
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildUserSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Buscar Usuários',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Procure por usuários existentes por email ou nome',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Buscar',
            hintText: 'Digite email ou nome do usuário',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _searchUsers,
                  ),
          ),
          onFieldSubmitted: (_) => _searchUsers(),
        ),
        if (_searchResults.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child: user.photoURL == null
                        ? Text(
                            user.displayName?.substring(0, 1).toUpperCase() ??
                                'U')
                        : null,
                  ),
                  title: Text(user.displayName ?? 'Nome não disponível'),
                  subtitle: Text(user.email),
                  trailing: ElevatedButton(
                    onPressed: () => _selectUser(user),
                    child: const Text('Selecionar'),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMessageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mensagem Personalizada (Opcional)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Adicione uma mensagem pessoal ao convite',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _messageController,
          decoration: const InputDecoration(
            labelText: 'Mensagem',
            hintText:
                'Olá! Gostaria de convidá-lo para colaborar no nosso quadro...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.message),
          ),
          maxLines: 3,
          maxLength: 200,
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    final hasEmails = _showBulkInvite
        ? _bulkEmailsController.text.trim().isNotEmpty ||
            _selectedEmails.isNotEmpty
        : _emailController.text.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: hasEmails && !_isSendingInvite ? _sendInvites : null,
        icon: _isSendingInvite
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.send),
        label: Text(_showBulkInvite ? 'Enviar Convites' : 'Enviar Convite'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira um email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Por favor, insira um email válido';
    }
    return null;
  }

  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final invitationService = ref.read(boardInvitationServiceProvider);
      final results = await invitationService.searchUsers(query);

      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro na busca: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _selectUser(User user) {
    setState(() {
      _emailController.text = user.email;
      _searchResults = [];
      _searchController.clear();
    });
  }

  Future<void> _sendInvites() async {
    setState(() {
      _isSendingInvite = true;
    });

    try {
      final invitationService = ref.read(boardInvitationServiceProvider);
      final currentUser = ref.read(currentUserProvider);

      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      if (_showBulkInvite) {
        // Parse bulk emails
        final emailsText = _bulkEmailsController.text.trim();
        final emails = <String>[];

        if (emailsText.isNotEmpty) {
          emails.addAll(
            emailsText
                .split(RegExp(r'[,\n]'))
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty && _validateEmail(e) == null),
          );
        }

        emails.addAll(_selectedEmails);

        // Send bulk invites
        final invitations = await invitationService.bulkInviteToBoard(
          boardId: widget.board.id,
          boardName: widget.board.name,
          inviterId: currentUser.id,
          inviterName: currentUser.displayName ?? 'Usuário',
          inviterEmail: currentUser.email,
          inviteeEmails: emails,
          message: _messageController.text.trim().isNotEmpty
              ? _messageController.text.trim()
              : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('${invitations.length} convites enviados com sucesso'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Send single invite
        final email = _emailController.text.trim();
        await invitationService.createBoardInvitation(
          boardId: widget.board.id,
          boardName: widget.board.name,
          inviterId: currentUser.id,
          inviterName: currentUser.displayName ?? 'Usuário',
          inviterEmail: currentUser.email,
          inviteeEmail: email,
          message: _messageController.text.trim().isNotEmpty
              ? _messageController.text.trim()
              : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Convite enviado com sucesso'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      // Clear form
      _emailController.clear();
      _bulkEmailsController.clear();
      _messageController.clear();
      _selectedEmails.clear();
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar convite: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingInvite = false;
        });
      }
    }
  }
}
