import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/models.dart';
import '../providers/store_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/layout/safe_area_wrapper.dart';

/// Bottom sheet drawer showing user's inventory
class UserInventoryDrawer extends ConsumerWidget {
  const UserInventoryDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(userInventoryProvider);
    final purchasesAsync = ref.watch(userPurchasesProvider);
    final theme = Theme.of(context);

    return SafeAreaWrapper(
      top: false, // Don't add top padding as it's a bottom sheet
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'My Inventory',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Content
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      indicatorColor: theme.colorScheme.primary,
                      tabs: const [
                        Tab(text: 'Owned Items'),
                        Tab(text: 'Purchase History'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildInventoryTab(context, inventoryAsync, ref),
                          _buildPurchaseHistoryTab(context, purchasesAsync),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryTab(
    BuildContext context,
    AsyncValue<UserInventory?> inventoryAsync,
    WidgetRef ref,
  ) {
    return inventoryAsync.when(
      data: (inventory) {
        if (inventory == null || inventory.ownedItems.isEmpty) {
          return _buildEmptyInventory(context);
        }
        return _buildInventoryList(context, inventory, ref);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading inventory: $error'),
      ),
    );
  }

  Widget _buildPurchaseHistoryTab(
    BuildContext context,
    AsyncValue<List<Purchase>> purchasesAsync,
  ) {
    return purchasesAsync.when(
      data: (purchases) {
        if (purchases.isEmpty) {
          return _buildEmptyPurchaseHistory(context);
        }
        return _buildPurchaseHistoryList(context, purchases);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading purchases: $error'),
      ),
    );
  }

  Widget _buildEmptyInventory(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Your inventory is empty',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Purchase items from the store to see them here!',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryList(
    BuildContext context,
    UserInventory inventory,
    WidgetRef ref,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: inventory.ownedItems.length,
      itemBuilder: (context, index) {
        final item = inventory.ownedItems[index];
        return _buildInventoryItemCard(context, item, inventory, ref);
      },
    );
  }

  Widget _buildInventoryItemCard(
    BuildContext context,
    InventoryItem item,
    UserInventory inventory,
    WidgetRef ref,
  ) {
    final theme = Theme.of(context);
    final isActive = inventory.activeItems.contains(item.storeItemId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Item Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.inventory,
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(width: 16),

            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Item ID: ${item.storeItemId}', // In real app, fetch item name
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (item.quantity > 1) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Quantity: ${item.quantity}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                  if (item.purchaseDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Purchased: ${item.purchaseDate!.day}/${item.purchaseDate!.month}/${item.purchaseDate!.year}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Action Buttons
            Column(
              children: [
                if (isActive) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ACTIVE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () => _activateItem(context, item, ref),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(80, 32),
                    ),
                    child: const Text('Activate'),
                  ),
                ],
                if (item.isStackable && item.quantity > 0) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => _consumeItem(context, item, ref),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(80, 32),
                    ),
                    child: const Text('Use'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPurchaseHistory(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No purchases yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your purchase history will appear here',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseHistoryList(
      BuildContext context, List<Purchase> purchases) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: purchases.length,
      itemBuilder: (context, index) {
        final purchase = purchases[index];
        return _buildPurchaseCard(context, purchase);
      },
    );
  }

  Widget _buildPurchaseCard(BuildContext context, Purchase purchase) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Status Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getStatusColor(purchase.status).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(purchase.status),
                color: _getStatusColor(purchase.status),
                size: 20,
              ),
            ),

            const SizedBox(width: 16),

            // Purchase Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    purchase.itemName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${purchase.purchaseDate.day}/${purchase.purchaseDate.month}/${purchase.purchaseDate.year}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Price and Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monetization_on,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${purchase.price}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  purchase.status.name.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _getStatusColor(purchase.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(PurchaseStatus status) {
    switch (status) {
      case PurchaseStatus.completed:
        return Colors.green;
      case PurchaseStatus.pending:
        return Colors.orange;
      case PurchaseStatus.failed:
        return Colors.red;
      case PurchaseStatus.refunded:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(PurchaseStatus status) {
    switch (status) {
      case PurchaseStatus.completed:
        return Icons.check_circle;
      case PurchaseStatus.pending:
        return Icons.schedule;
      case PurchaseStatus.failed:
        return Icons.error;
      case PurchaseStatus.refunded:
        return Icons.undo;
    }
  }

  Future<void> _activateItem(
      BuildContext context, InventoryItem item, WidgetRef ref) async {
    final authState = ref.read(authStateProvider);
    final user = authState.value;
    if (user == null) return;

    final purchaseNotifier = ref.read(purchaseNotifierProvider.notifier);
    await purchaseNotifier.activateItem(user.uid, item.storeItemId);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item activated!')),
      );
    }
  }

  Future<void> _consumeItem(
      BuildContext context, InventoryItem item, WidgetRef ref) async {
    final authState = ref.read(authStateProvider);
    final user = authState.value;
    if (user == null) return;

    final purchaseNotifier = ref.read(purchaseNotifierProvider.notifier);
    await purchaseNotifier.consumeItem(user.uid, item.storeItemId);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item used!')),
      );
    }
  }
}
