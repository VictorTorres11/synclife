import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/main_layout.dart';
import '../../../monetization/presentation/providers/monetization_providers.dart';
import '../../../monetization/presentation/widgets/premium_feature_indicator.dart';
import '../../../monetization/presentation/widgets/upgrade_prompt_dialog.dart';
import '../../domain/models/models.dart';
import '../widgets/fluxo_coins_header.dart';
import '../widgets/store_category_tabs.dart';
import '../widgets/store_item_grid.dart';
import '../widgets/user_inventory_drawer.dart';

/// Screen displaying the FluxoCoins rewards store
class RewardsStoreScreen extends ConsumerStatefulWidget {
  const RewardsStoreScreen({super.key});

  @override
  ConsumerState<RewardsStoreScreen> createState() => _RewardsStoreScreenState();
}

class _RewardsStoreScreenState extends ConsumerState<RewardsStoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);

    return MainLayout(
      title: 'FluxoCoins Store',
      actions: [
        if (!isPremium) ...[
          GestureDetector(
            onTap: () => _showPremiumStoreInfo(context),
            child: const PremiumFeatureIndicator(
              size: 20,
              showText: true,
            ),
          ),
          const SizedBox(width: 8),
        ],
        IconButton(
          onPressed: () => _showInventory(context),
          icon: const Icon(Icons.inventory),
          tooltip: 'My Inventory',
        ),
        if (!isPremium)
          IconButton(
            onPressed: () => _showPremiumStoreInfo(context),
            icon: const Icon(Icons.star_border),
            tooltip: 'Premium Store Features',
          ),
      ],
      child: Column(
        children: [
          // FluxoCoins Balance Header
          const FluxoCoinsHeader(),

          // Premium Store Banner for free users
          if (!isPremium) _buildPremiumStoreBanner(context),

          // Category Tabs
          StoreCategoryTabs(controller: _tabController),

          // Store Items Grid
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                StoreItemGrid(category: StoreItemCategory.functional),
                StoreItemGrid(category: StoreItemCategory.visual),
                StoreItemGrid(category: StoreItemCategory.utility),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInventory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const UserInventoryDrawer(),
    );
  }

  Widget _buildPremiumStoreBanner(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withOpacity(0.1),
            Colors.orange.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.star,
            color: Colors.amber,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium Store Features',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Unlock exclusive items, better discounts, and bonus FluxoCoins!',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.amber.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _showPremiumStoreInfo(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.amber.shade700,
              backgroundColor: Colors.amber.withOpacity(0.2),
            ),
            child: const Text('Learn More'),
          ),
        ],
      ),
    );
  }

  void _showPremiumStoreInfo(BuildContext context) {
    UpgradePromptDialog.show(
      context,
      feature: 'Premium Store Features',
      description:
          'Get more value from your FluxoCoins with Premium store benefits.',
      benefits: [
        'Exclusive Premium-only items',
        '20% discount on all store purchases',
        'Bonus FluxoCoins from daily activities',
        'Early access to new items',
        'Special seasonal collections',
        'Priority customer support',
      ],
    );
  }
}
