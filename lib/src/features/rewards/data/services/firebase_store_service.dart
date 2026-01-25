import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/models.dart';
import '../../domain/services/services.dart';
import '../../../gamification/domain/services/services.dart';
import '../store_catalog.dart';

/// Firebase implementation of StoreService
class FirebaseStoreService implements StoreService {
  FirebaseStoreService({
    required FirebaseFirestore firestore,
    required GamificationService gamificationService,
  }) : _firestore = firestore,
       _gamificationService = gamificationService,
       _uuid = const Uuid();

  final FirebaseFirestore _firestore;
  final GamificationService _gamificationService;
  final Uuid _uuid;

  CollectionReference<Map<String, dynamic>> get _storeItemsCollection =>
      _firestore.collection('storeItems');

  CollectionReference<Map<String, dynamic>> get _purchasesCollection =>
      _firestore.collection('purchases');

  CollectionReference<Map<String, dynamic>> get _inventoriesCollection =>
      _firestore.collection('userInventories');

  @override
  Future<List<StoreItem>> getStoreItems() async {
    try {
      final querySnapshot = await _storeItemsCollection
          .where('isAvailable', isEqualTo: true)
          .orderBy('category')
          .orderBy('price')
          .get();

      return querySnapshot.docs
          .map((doc) => StoreItem.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get store items: $e');
    }
  }

  @override
  Future<List<StoreItem>> getStoreItemsByCategory(StoreItemCategory category) async {
    try {
      final querySnapshot = await _storeItemsCollection
          .where('category', isEqualTo: category.name)
          .where('isAvailable', isEqualTo: true)
          .orderBy('price')
          .get();

      return querySnapshot.docs
          .map((doc) => StoreItem.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get store items by category: $e');
    }
  }

  @override
  Future<StoreItem?> getStoreItem(String itemId) async {
    try {
      final doc = await _storeItemsCollection.doc(itemId).get();
      if (!doc.exists) return null;
      return StoreItem.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get store item: $e');
    }
  }

  @override
  Future<Purchase> purchaseItem(String userId, String storeItemId) async {
    try {
      // Use Firestore transaction to ensure atomicity
      return await _firestore.runTransaction<Purchase>((transaction) async {
        // Get store item
        final storeItemDoc = await transaction.get(_storeItemsCollection.doc(storeItemId));
        if (!storeItemDoc.exists) {
          throw Exception('Store item not found');
        }
        
        final storeItem = StoreItem.fromMap(storeItemDoc.data()!);
        if (!storeItem.isAvailable) {
          throw Exception('Store item is not available');
        }

        // Check if user can purchase (has enough FluxoCoins)
        final canPurchase = await canPurchaseItem(userId, storeItemId);
        if (!canPurchase) {
          throw Exception('Insufficient FluxoCoins');
        }

        // Deduct FluxoCoins
        await _gamificationService.deductFluxoCoins(
          userId, 
          storeItem.price, 
          'Store purchase: ${storeItem.name}',
        );

        // Create purchase record
        final purchaseId = _uuid.v4();
        final purchase = Purchase(
          id: purchaseId,
          userId: userId,
          storeItemId: storeItemId,
          itemName: storeItem.name,
          price: storeItem.price,
          purchaseDate: DateTime.now(),
          status: PurchaseStatus.completed,
        );

        // Save purchase
        transaction.set(
          _purchasesCollection.doc(purchaseId),
          purchase.toMap(),
        );

        // Add item to user inventory
        await _addItemToInventory(userId, storeItem, purchaseId);

        return purchase;
      });
    } catch (e) {
      throw Exception('Failed to purchase item: $e');
    }
  }

  @override
  Future<List<Purchase>> getUserPurchases(String userId) async {
    try {
      final querySnapshot = await _purchasesCollection
          .where('userId', isEqualTo: userId)
          .orderBy('purchaseDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Purchase.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user purchases: $e');
    }
  }

  @override
  Future<UserInventory> getUserInventory(String userId) async {
    try {
      final doc = await _inventoriesCollection.doc(userId).get();
      
      if (!doc.exists) {
        // Create initial inventory
        final initialInventory = UserInventory.initial(userId);
        await _inventoriesCollection.doc(userId).set(initialInventory.toMap());
        return initialInventory;
      }
      
      return UserInventory.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get user inventory: $e');
    }
  }

  @override
  Future<UserInventory> activateItem(String userId, String storeItemId) async {
    try {
      final inventory = await getUserInventory(userId);
      
      if (!inventory.ownsItem(storeItemId)) {
        throw Exception('User does not own this item');
      }

      final updatedInventory = inventory.activateItem(storeItemId);
      await _inventoriesCollection.doc(userId).set(updatedInventory.toMap());
      
      return updatedInventory;
    } catch (e) {
      throw Exception('Failed to activate item: $e');
    }
  }

  @override
  Future<UserInventory> consumeItem(String userId, String storeItemId) async {
    try {
      final inventory = await getUserInventory(userId);
      
      if (!inventory.ownsItem(storeItemId)) {
        throw Exception('User does not own this item');
      }

      final updatedInventory = inventory.consumeItem(storeItemId);
      await _inventoriesCollection.doc(userId).set(updatedInventory.toMap());
      
      return updatedInventory;
    } catch (e) {
      throw Exception('Failed to consume item: $e');
    }
  }

  @override
  Future<bool> canPurchaseItem(String userId, String storeItemId) async {
    try {
      final storeItem = await getStoreItem(storeItemId);
      if (storeItem == null || !storeItem.isAvailable) {
        return false;
      }

      final userStats = await _gamificationService.getUserStats(userId);
      if (userStats == null) {
        return false;
      }

      return userStats.fluxoCoins >= storeItem.price;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int> getItemPrice(String userId, String storeItemId) async {
    try {
      final storeItem = await getStoreItem(storeItemId);
      if (storeItem == null) {
        throw Exception('Store item not found');
      }

      // For now, return base price. In the future, this could include discounts
      return storeItem.price;
    } catch (e) {
      throw Exception('Failed to get item price: $e');
    }
  }

  @override
  Stream<List<StoreItem>> watchStoreItems() {
    return _storeItemsCollection
        .where('isAvailable', isEqualTo: true)
        .orderBy('category')
        .orderBy('price')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StoreItem.fromMap(doc.data()))
            .toList());
  }

  @override
  Stream<UserInventory> watchUserInventory(String userId) {
    return _inventoriesCollection
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists 
            ? UserInventory.fromMap(doc.data()!)
            : UserInventory.initial(userId));
  }

  @override
  Stream<List<Purchase>> watchUserPurchases(String userId) {
    return _purchasesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('purchaseDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Purchase.fromMap(doc.data()))
            .toList());
  }

  /// Helper method to add item to user inventory
  Future<void> _addItemToInventory(String userId, StoreItem storeItem, String purchaseId) async {
    final inventory = await getUserInventory(userId);
    
    final inventoryItem = InventoryItem(
      storeItemId: storeItem.id,
      purchaseId: purchaseId,
      quantity: 1,
      purchaseDate: DateTime.now(),
      isStackable: storeItem.type == StoreItemType.consumable,
    );

    final updatedInventory = inventory.addItem(inventoryItem);
    await _inventoriesCollection.doc(userId).set(updatedInventory.toMap());
  }

  /// Initializes the store with default items (should be called once during setup)
  Future<void> initializeStore() async {
    try {
      final batch = _firestore.batch();
      
      for (final item in StoreCatalog.defaultItems) {
        final docRef = _storeItemsCollection.doc(item.id);
        batch.set(docRef, item.toMap());
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to initialize store: $e');
    }
  }
}