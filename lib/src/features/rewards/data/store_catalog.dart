import '../domain/models/models.dart';

/// Predefined catalog of store items for the FluxoCoins store
class StoreCatalog {
  static const List<StoreItem> defaultItems = [
    // Functional Items
    StoreItem(
      id: 'additional_board',
      name: 'Additional Board',
      description: 'Unlock an extra board to organize more projects',
      category: StoreItemCategory.functional,
      price: 500,
      type: StoreItemType.upgrade,
      iconPath: 'assets/store/additional_board.png',
      isAvailable: true,
      metadata: {'maxPurchases': 5},
    ),
    
    StoreItem(
      id: 'group_member_slot',
      name: 'Group Member Slot',
      description: 'Add one more member to your shared boards',
      category: StoreItemCategory.functional,
      price: 300,
      type: StoreItemType.upgrade,
      iconPath: 'assets/store/group_member.png',
      isAvailable: true,
      metadata: {'maxPurchases': 10},
    ),

    StoreItem(
      id: 'task_templates',
      name: 'Task Templates Pack',
      description: 'Pre-made task templates for common routines',
      category: StoreItemCategory.functional,
      price: 200,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/task_templates.png',
      isAvailable: true,
    ),

    // Visual Items
    StoreItem(
      id: 'dark_theme_premium',
      name: 'Premium Dark Theme',
      description: 'Elegant dark theme with custom colors',
      category: StoreItemCategory.visual,
      price: 150,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/dark_theme.png',
      isAvailable: true,
    ),

    StoreItem(
      id: 'nature_theme',
      name: 'Nature Theme',
      description: 'Calming green theme inspired by nature',
      category: StoreItemCategory.visual,
      price: 150,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/nature_theme.png',
      isAvailable: true,
    ),

    StoreItem(
      id: 'ocean_theme',
      name: 'Ocean Theme',
      description: 'Soothing blue theme with ocean vibes',
      category: StoreItemCategory.visual,
      price: 150,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/ocean_theme.png',
      isAvailable: true,
    ),

    StoreItem(
      id: 'achievement_sounds_pack',
      name: 'Achievement Sounds Pack',
      description: 'Collection of satisfying completion sounds',
      category: StoreItemCategory.visual,
      price: 100,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/sounds_pack.png',
      isAvailable: true,
    ),

    StoreItem(
      id: 'avatar_icons_pack',
      name: 'Avatar Icons Pack',
      description: 'Unique avatar icons to personalize your profile',
      category: StoreItemCategory.visual,
      price: 75,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/avatar_pack.png',
      isAvailable: true,
    ),

    // Utility Items
    StoreItem(
      id: 'streak_freeze',
      name: 'Streak Freeze',
      description: 'Protect your streak for one day if you miss tasks',
      category: StoreItemCategory.utility,
      price: 50,
      type: StoreItemType.consumable,
      iconPath: 'assets/store/streak_freeze.png',
      isAvailable: true,
      metadata: {'maxQuantity': 5},
    ),

    StoreItem(
      id: 'double_xp_boost',
      name: 'Double XP Boost',
      description: 'Earn double XP for 24 hours',
      category: StoreItemCategory.utility,
      price: 100,
      type: StoreItemType.consumable,
      iconPath: 'assets/store/xp_boost.png',
      isAvailable: true,
      metadata: {'duration': '24h'},
    ),

    StoreItem(
      id: 'task_reminder_plus',
      name: 'Task Reminder Plus',
      description: 'Advanced reminder system with custom notifications',
      category: StoreItemCategory.utility,
      price: 250,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/reminder_plus.png',
      isAvailable: true,
    ),

    StoreItem(
      id: 'priority_support',
      name: 'Priority Support',
      description: 'Get priority customer support for 30 days',
      category: StoreItemCategory.utility,
      price: 200,
      type: StoreItemType.consumable,
      iconPath: 'assets/store/priority_support.png',
      isAvailable: true,
      metadata: {'duration': '30d'},
    ),
  ];

  /// Gets items by category
  static List<StoreItem> getItemsByCategory(StoreItemCategory category) {
    return defaultItems.where((item) => item.category == category).toList();
  }

  /// Gets functional items (boards, members, etc.)
  static List<StoreItem> get functionalItems => 
      getItemsByCategory(StoreItemCategory.functional);

  /// Gets visual items (themes, sounds, avatars)
  static List<StoreItem> get visualItems => 
      getItemsByCategory(StoreItemCategory.visual);

  /// Gets utility items (streak freeze, boosts, etc.)
  static List<StoreItem> get utilityItems => 
      getItemsByCategory(StoreItemCategory.utility);
}