import 'package:flutter/material.dart';

/// Widget that shows real-time activity indicators
class ActivityIndicator extends StatefulWidget {
  const ActivityIndicator({
    super.key,
    required this.isActive,
    this.activeUsers = const [],
    this.lastActivity,
  });

  final bool isActive;
  final List<String> activeUsers;
  final DateTime? lastActivity;

  @override
  State<ActivityIndicator> createState() => _ActivityIndicatorState();
}

class _ActivityIndicatorState extends State<ActivityIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ActivityIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive && widget.activeUsers.isEmpty && widget.lastActivity == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isActive ? Colors.green : Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isActive) ...[
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
            Text(
              _getActivityText(),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            Icon(
              Icons.schedule,
              size: 12,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              _getLastActivityText(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getActivityText() {
    if (widget.activeUsers.isEmpty) {
      return 'Active';
    } else if (widget.activeUsers.length == 1) {
      return '${widget.activeUsers.first} is active';
    } else {
      return '${widget.activeUsers.length} users active';
    }
  }

  String _getLastActivityText() {
    if (widget.lastActivity == null) {
      return 'No recent activity';
    }

    final now = DateTime.now();
    final difference = now.difference(widget.lastActivity!);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Widget that shows typing indicators for real-time collaboration
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({
    super.key,
    required this.typingUsers,
  });

  final List<String> typingUsers;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _dotsController;
  late Animation<int> _dotsAnimation;

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _dotsAnimation = IntTween(begin: 0, end: 3).animate(_dotsController);

    if (widget.typingUsers.isNotEmpty) {
      _dotsController.repeat();
    }
  }

  @override
  void didUpdateWidget(TypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.typingUsers.isNotEmpty != oldWidget.typingUsers.isNotEmpty) {
      if (widget.typingUsers.isNotEmpty) {
        _dotsController.repeat();
      } else {
        _dotsController.stop();
      }
    }
  }

  @override
  void dispose() {
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getTypingText(),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.blue,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 4),
          AnimatedBuilder(
            animation: _dotsAnimation,
            builder: (context, child) {
              return Text(
                '.' * (_dotsAnimation.value + 1),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getTypingText() {
    if (widget.typingUsers.length == 1) {
      return '${widget.typingUsers.first} is typing';
    } else if (widget.typingUsers.length == 2) {
      return '${widget.typingUsers.first} and ${widget.typingUsers.last} are typing';
    } else {
      return '${widget.typingUsers.length} people are typing';
    }
  }
}