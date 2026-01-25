import '../models/models.dart';

/// Service interface for FluxoCoins store functionality
abstract class StoreService {
  /// Gets all available store items
  Future<List<StoreItem>> getStoreItems();

  /// Gets store items by category
  Future<List<StoreItem>> getStoreItemsByCategory(StoreItemCategory category);

  /// Gets a specific store item by ID
  Future<StoreItem?> getStoreItem(String itemId);

  /// Purchases an item from the store
  /// Returns the purchase record if successful
  Future<Purchase> purchaseItem(String userId, String storeItemId);

  /// Gets user's purchase history
  Future<List<Purchase>> getUserPurchases(String userId);

  /// Gets user's inventory
  Future<UserInventory> getUserInventory(String userId);

  /// Activates an item in user's inventory (for themes, sounds, etc.)
  Future<UserInventory> activateItem(String userId, String storeItemId);

  /// Consumes an item from user's inventory (for consumables like Streak Freeze)
  Future<UserInventory> consumeItem(String userId, String storeItemId);

  /// Validates if user can purchase an item
  Future<bool> canPurchaseItem(String userId, String storeItemId);

  /// Gets the effective price for an item (may include discounts)
  Future<int> getItemPrice(String userId, String storeItemId);

  /// Watches store items changes in real-time
  Stream<List<StoreItem>> watchStoreItems();

  /// Watches user inventory changes in real-time
  Stream<UserInventory> watchUserInventory(String userId);

  /// Watches user purchases in real-time
  Stream<List<Purchase>> watchUserPurchases(String userId);
}