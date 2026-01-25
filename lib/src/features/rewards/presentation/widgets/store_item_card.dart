import 'package:flutter/material.dart';

import '../../domain/models/models.dart';

/// Widget displaying a single store item as a card
class StoreItemCard extends StatelessWidget {
  const StoreItemCard({
    super.key,
    required this.item,
    required this.onPurchase,
  });

  final StoreItem item;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Image/Icon
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _getCategoryColor(item.category).withOpacity(0.1),
              ),
              child: Center(
                child: Icon(
                  _getItemIcon(item),
                  size: 48,
                  color: _getCategoryColor(item.category),
                ),
              ),
            ),
          ),

          // Item Details
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Name
                  Text(
                    item.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Item Description
                  Expanded(
                    child: Text(
                      item.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Price and Purchase Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Row(
                        children: [
                          Icon(
                            Icons.monetization_on,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.price}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      // Purchase Button
                      SizedBox(
                        height: 32,
                        child: ElevatedButton(
                          onPressed: item.isAvailable ? onPurchase : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: Size.zero,
                          ),
                          child: Text(
                            'Buy',
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Item Type Badge
          if (item.type != StoreItemType.permanent)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: _getTypeColor(item.type).withOpacity(0.1),
              ),
              child: Center(
                child: Text(
                  _getTypeLabel(item.type),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _getTypeColor(item.type),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getCategoryColor(StoreItemCategory category) {
    switch (category) {
      case StoreItemCategory.functional:
        return Colors.blue;
      case StoreItemCategory.visual:
        return Colors.purple;
      case StoreItemCategory.utility:
        return Colors.orange;
    }
  }

  Color _getTypeColor(StoreItemType type) {
    switch (type) {
      case StoreItemType.consumable:
        return Colors.red;
      case StoreItemType.permanent:
        return Colors.green;
      case StoreItemType.upgrade:
        return Colors.blue;
    }
  }

  String _getTypeLabel(StoreItemType type) {
    switch (type) {
      case StoreItemType.consumable:
        return 'CONSUMABLE';
      case StoreItemType.permanent:
        return 'PERMANENT';
      case StoreItemType.upgrade:
        return 'UPGRADE';
    }
  }

  IconData _getItemIcon(StoreItem item) {
    // Map item IDs to specific icons
    switch (item.id) {
      case 'additional_board':
        return Icons.dashboard;
      case 'group_member_slot':
        return Icons.person_add;
      case 'task_templates':
        return Icons.description;
      case 'dark_theme_premium':
      case 'nature_theme':
      case 'ocean_theme':
        return Icons.palette;
      case 'achievement_sounds_pack':
        return Icons.volume_up;
      case 'avatar_icons_pack':
        return Icons.face;
      case 'streak_freeze':
        return Icons.ac_unit;
      case 'double_xp_boost':
        return Icons.flash_on;
      case 'task_reminder_plus':
        return Icons.notifications_active;
      case 'priority_support':
        return Icons.support_agent;
      default:
        return _getDefaultCategoryIcon(item.category);
    }
  }

  IconData _getDefaultCategoryIcon(StoreItemCategory category) {
    switch (category) {
      case StoreItemCategory.functional:
        return Icons.extension;
      case StoreItemCategory.visual:
        return Icons.palette;
      case StoreItemCategory.utility:
        return Icons.build;
    }
  }
}
