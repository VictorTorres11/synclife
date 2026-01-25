import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/services/firebase_store_service.dart';
import '../../domain/models/models.dart';
import '../../domain/services/services.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../gamification/presentation/providers/gamification_providers.dart';

/// Provider for StoreService
final storeServiceProvider = Provider<StoreService>((ref) {
  final gamificationService = ref.watch(gamificationServiceProvider);
  return FirebaseStoreService(
    firestore: FirebaseFirestore.instance,
    gamificationService: gamificationService,
  );
});

/// Provider for all store items
final storeItemsProvider = StreamProvider<List<StoreItem>>((ref) {
  final storeService = ref.watch(storeServiceProvider);
  return storeService.watchStoreItems();
});

/// Provider for store items by category
final storeItemsByCategoryProvider =
    StreamProvider.family<List<StoreItem>, StoreItemCategory>((ref, category) {
  final storeService = ref.watch(storeServiceProvider);
  return storeService.getStoreItemsByCategory(category).asStream();
});

/// Provider for current user's inventory
final userInventoryProvider = StreamProvider<UserInventory?>((ref) {
  final authState = ref.watch(authStateProvider);
  final storeService = ref.watch(storeServiceProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return storeService.watchUserInventory(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// Provider for current user's purchase history
final userPurchasesProvider = StreamProvider<List<Purchase>>((ref) {
  final authState = ref.watch(authStateProvider);
  final storeService = ref.watch(storeServiceProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return storeService.watchUserPurchases(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Provider for purchase functionality
final purchaseNotifierProvider =
    StateNotifierProvider<PurchaseNotifier, PurchaseState>((ref) {
  final storeService = ref.watch(storeServiceProvider);
  return PurchaseNotifier(storeService);
});

/// State for purchase operations
class PurchaseState {
  const PurchaseState({
    this.isLoading = false,
    this.error,
    this.lastPurchase,
  });

  final bool isLoading;
  final String? error;
  final Purchase? lastPurchase;

  PurchaseState copyWith({
    bool? isLoading,
    String? error,
    Purchase? lastPurchase,
  }) {
    return PurchaseState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastPurchase: lastPurchase ?? this.lastPurchase,
    );
  }
}

/// Notifier for handling purchase operations
class PurchaseNotifier extends StateNotifier<PurchaseState> {
  PurchaseNotifier(this._storeService) : super(const PurchaseState());

  final StoreService _storeService;

  /// Purchases an item from the store
  Future<void> purchaseItem(String userId, String storeItemId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final purchase = await _storeService.purchaseItem(userId, storeItemId);
      state = state.copyWith(
        isLoading: false,
        lastPurchase: purchase,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Activates an item in user's inventory
  Future<void> activateItem(String userId, String storeItemId) async {
    try {
      await _storeService.activateItem(userId, storeItemId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Consumes an item from user's inventory
  Future<void> consumeItem(String userId, String storeItemId) async {
    try {
      await _storeService.consumeItem(userId, storeItemId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clears any error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}
