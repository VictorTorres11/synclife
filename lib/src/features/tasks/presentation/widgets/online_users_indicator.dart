import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/board.dart';
import '../../domain/models/board_activity.dart';
import '../providers/board_providers.dart';

/// Widget that shows online users for a board
class OnlineUsersIndicator extends ConsumerWidget {
  const OnlineUsersIndicator({
    super.key,
    required this.board,
    this.maxAvatars = 5,
    this.showCount = true,
  });

  final Board board;
  final int maxAvatars;
  final bool showCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlineUsersAsync = ref.watch(onlineUsersProvider(board.id));

    return onlineUsersAsync.when(
      data: (users) => _buildOnlineUsers(context, users),
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(),
    );
  }

  Widget _buildOnlineUsers(BuildContext context, List<UserPresence> users) {
    if (users.isEmpty) {
      return _buildOfflineState(context);
    }

    final displayUsers = users.take(maxAvatars).toList();
    final remainingCount = users.length - displayUsers.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // User avatars
        Stack(
          children: displayUsers.asMap().entries.map((entry) {
            final index = entry.key;
            final user = entry.value;
            return Positioned(
              left: index * 20.0,
              child: _buildUserAvatar(user),
            );
          }).toList(),
        ),

        // Spacing for stacked avatars
        if (displayUsers.isNotEmpty)
          SizedBox(width: (displayUsers.length - 1) * 20.0 + 32),

        // Remaining count
        if (remainingCount > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+$remainingCount',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],

        // Online count
        if (showCount) ...[
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${users.length} online',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildUserAvatar(UserPresence user) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Avatar
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.blue[100],
            child: Text(
              user.userName.isNotEmpty
                  ? user.userName.substring(0, 1).toUpperCase()
                  : 'U',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
          ),

          // Online indicator
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Carregando...',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          size: 16,
          color: Colors.red[400],
        ),
        const SizedBox(width: 4),
        Text(
          'Erro',
          style: TextStyle(
            fontSize: 12,
            color: Colors.red[600],
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineState(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'Ninguém online',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }
}
