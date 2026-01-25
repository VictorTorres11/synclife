import 'package:flutter/material.dart';
import '../../domain/models/inbox_item.dart';

/// Widget for displaying and managing inbox items
class InboxWidget extends StatelessWidget {
  const InboxWidget({
    super.key,
    required this.inboxItems,
    required this.onAddItem,
    required this.onEditItem,
    required this.onDeleteItem,
    required this.onConvertToTask,
  });

  final List<InboxItem> inboxItems;
  final ValueChanged<String> onAddItem;
  final Function(String itemId, String newContent) onEditItem;
  final ValueChanged<String> onDeleteItem;
  final ValueChanged<InboxItem> onConvertToTask;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.inbox),
              const SizedBox(width: 8),
              const Text(
                'Inbox',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddItemDialog(context),
              ),
            ],
          ),
        ),
        
        // Inbox items
        if (inboxItems.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No quick notes yet. Tap + to add one.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: inboxItems.length,
            itemBuilder: (context, index) {
              final item = inboxItems[index];
              return _InboxItemTile(
                item: item,
                onEdit: (newContent) => onEditItem(item.id, newContent),
                onDelete: () => onDeleteItem(item.id),
                onConvertToTask: () => onConvertToTask(item),
              );
            },
          ),
      ],
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Quick Note'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter your note...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final content = controller.text.trim();
              if (content.isNotEmpty) {
                onAddItem(content);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _InboxItemTile extends StatelessWidget {
  const _InboxItemTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onConvertToTask,
  });

  final InboxItem item;
  final ValueChanged<String> onEdit;
  final VoidCallback onDelete;
  final VoidCallback onConvertToTask;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 32,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Note'),
            content: const Text('Are you sure you want to delete this note?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: const Icon(Icons.note),
          title: Text(item.content),
          subtitle: Text(
            'Created ${_formatDate(item.createdAt)}',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _showEditDialog(context);
                  break;
                case 'convert':
                  onConvertToTask();
                  break;
                case 'delete':
                  onDelete();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'convert',
                child: Row(
                  children: [
                    Icon(Icons.task_alt),
                    SizedBox(width: 8),
                    Text('Convert to Task'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: item.content);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Note'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final content = controller.text.trim();
              if (content.isNotEmpty && content != item.content) {
                onEdit(content);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}