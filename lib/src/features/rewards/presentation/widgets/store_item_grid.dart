import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/models.dart';
import '../providers/store_providers.dart';
import '../../../gamification/presentation/providers/gamification_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'store_item_card.dart';

/// Widget displaying store items in a grid layout for a specific category
class StoreItemGrid extends ConsumerWidget {
  const StoreItemGrid({
    super.key,
    required this.category,
  });

  final StoreItemCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeItemsAsync = ref.watch(storeItemsByCategoryProvider(category));
    final theme = Theme.of(context);

    return storeItemsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return _buildEmptyState(context, theme);
        }
        return _buildItemsGrid(context, items, ref);
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading items',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getCategoryIcon(category),
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No ${category.name} items available',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new items!',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsGrid(
      BuildContext context, List<StoreItem> items, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return StoreItemCard(
            item: item,
            onPurchase: () => _handlePurchase(context, item, ref),
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(StoreItemCategory category) {
    switch (category) {
      case StoreItemCategory.functional:
        return Icons.extension;
      case StoreItemCategory.visual:
        return Icons.palette;
      case StoreItemCategory.utility:
        return Icons.build;
    }
  }

  Future<void> _handlePurchase(
      BuildContext context, StoreItem item, WidgetRef ref) async {
    final authState = ref.read(authStateProvider);
    final userStats = ref.read(userStatsProvider);
    final purchaseNotifier = ref.read(purchaseNotifierProvider.notifier);

    // Check if user is authenticated
    final user = authState.value;
    if (user == null) {
      _showErrorDialog(context, 'Please log in to make purchases');
      return;
    }

    // Check if user has enough FluxoCoins
    final currentCoins = userStats.value?.fluxoCoins ?? 0;
    if (currentCoins < item.price) {
      _showInsufficientFundsDialog(context, item.price, currentCoins);
      return;
    }

    // Show purchase confirmation
    final confirmed = await _showPurchaseConfirmation(context, item);
    if (!confirmed) return;

    // Perform purchase
    await purchaseNotifier.purchaseItem(user.uid, item.id);

    // Check for errors
    final purchaseState = ref.read(purchaseNotifierProvider);
    if (purchaseState.error != null) {
      _showErrorDialog(context, purchaseState.error!);
      purchaseNotifier.clearError();
    } else if (purchaseState.lastPurchase != null) {
      _showPurchaseSuccessDialog(context, item);
    }
  }

  Future<bool> _showPurchaseConfirmation(
      BuildContext context, StoreItem item) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Purchase'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to purchase:'),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(item.description),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.monetization_on, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${item.price} FluxoCoins',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Purchase'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showInsufficientFundsDialog(
      BuildContext context, int itemPrice, int currentCoins) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insufficient FluxoCoins'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 48,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
                'You need ${itemPrice - currentCoins} more FluxoCoins to purchase this item.'),
            const SizedBox(height: 16),
            const Text('Complete more tasks to earn FluxoCoins!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPurchaseSuccessDialog(BuildContext context, StoreItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Purchase Successful!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              size: 48,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text('You have successfully purchased:'),
            const SizedBox(height: 8),
            Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Check your inventory to use this item!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Purchase Failed'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
