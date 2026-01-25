import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../auth/domain/models/user.dart';
import '../../domain/models/board.dart';
import '../../domain/services/board_service.dart';

/// Dialog for inviting users to a board
class InviteUsersDialog extends StatefulWidget {
  const InviteUsersDialog({
    super.key,
    required this.board,
    required this.boardService,
  });

  final Board board;
  final BoardService boardService;

  @override
  State<InviteUsersDialog> createState() => _InviteUsersDialogState();
}

class _InviteUsersDialogState extends State<InviteUsersDialog> {
  final _searchController = TextEditingController();
  final _emailController = TextEditingController();
  List<User> _searchResults = [];
  bool _isSearching = false;
  bool _isSendingInvite = false;
  String? _inviteLink;

  @override
  void initState() {
    super.initState();
    _generateInviteLink();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Invite to ${widget.board.name}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invite Link Section
            _buildInviteLinkSection(),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            
            // Direct Invitation Section
            _buildDirectInviteSection(),
            const SizedBox(height: 16),
            
            // User Search Section
            _buildUserSearchSection(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildInviteLinkSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Invite Link',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        const Text(
          'Share this link with anyone you want to invite to the board.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _inviteLink ?? 'Generating link...',
                  style: const TextStyle(fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: _inviteLink != null ? _copyInviteLink : null,
                tooltip: 'Copy Link',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDirectInviteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Direct Invitation',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        const Text(
          'Send a direct invitation to a specific email address.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'user@example.com',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isSendingInvite ? null : _sendDirectInvite,
              child: _isSendingInvite
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Search Users',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        const Text(
          'Search for users by email or user ID.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Search',
            hintText: 'Enter email or user ID',
            border: const OutlineInputBorder(),
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
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
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
                        ? Text(user.displayName?.substring(0, 1).toUpperCase() ?? 'U')
                        : null,
                  ),
                  title: Text(user.displayName ?? 'Unknown User'),
                  subtitle: Text(user.email),
                  trailing: ElevatedButton(
                    onPressed: () => _inviteUser(user),
                    child: const Text('Invite'),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _generateInviteLink() async {
    try {
      final link = await widget.boardService.generateInviteLink(widget.board.id);
      if (mounted) {
        setState(() {
          _inviteLink = link;
        });
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

  Future<void> _copyInviteLink() async {
    if (_inviteLink != null) {
      await Clipboard.setData(ClipboardData(text: _inviteLink!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invite link copied to clipboard'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _sendDirectInvite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSendingInvite = true;
    });

    try {
      await widget.boardService.sendDirectInvitation(widget.board.id, email);
      if (mounted) {
        _emailController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send invitation: $e'),
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

  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final results = await widget.boardService.searchUsers(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
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

  Future<void> _inviteUser(User user) async {
    try {
      await widget.boardService.sendDirectInvitation(widget.board.id, user.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitation sent to ${user.displayName ?? user.email}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to invite user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}