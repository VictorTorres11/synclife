import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service for implementing lazy loading patterns
class LazyLoadingService<T> {
  final Future<List<T>> Function(int offset, int limit) _loadFunction;
  final int _pageSize;

  List<T> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentOffset = 0;

  final StreamController<List<T>> _itemsController =
      StreamController<List<T>>.broadcast();
  final StreamController<bool> _loadingController =
      StreamController<bool>.broadcast();

  LazyLoadingService({
    required Future<List<T>> Function(int offset, int limit) loadFunction,
    int pageSize = 20,
  })  : _loadFunction = loadFunction,
        _pageSize = pageSize;

  /// Stream of items
  Stream<List<T>> get items => _itemsController.stream;

  /// Stream of loading state
  Stream<bool> get isLoading => _loadingController.stream;

  /// Current items list
  List<T> get currentItems => List.unmodifiable(_items);

  /// Whether more items can be loaded
  bool get hasMore => _hasMore;

  /// Whether currently loading
  bool get isCurrentlyLoading => _isLoading;

  /// Load initial data
  Future<void> loadInitial() async {
    if (_isLoading) return;

    _isLoading = true;
    _loadingController.add(true);

    try {
      _items.clear();
      _currentOffset = 0;
      _hasMore = true;

      final newItems = await _loadFunction(_currentOffset, _pageSize);

      _items.addAll(newItems);
      _currentOffset += newItems.length;
      _hasMore = newItems.length == _pageSize;

      _itemsController.add(_items);
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      rethrow;
    } finally {
      _isLoading = false;
      _loadingController.add(false);
    }
  }

  /// Load more data (pagination)
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _loadingController.add(true);

    try {
      final newItems = await _loadFunction(_currentOffset, _pageSize);

      _items.addAll(newItems);
      _currentOffset += newItems.length;
      _hasMore = newItems.length == _pageSize;

      _itemsController.add(_items);
    } catch (e) {
      debugPrint('Error loading more data: $e');
      rethrow;
    } finally {
      _isLoading = false;
      _loadingController.add(false);
    }
  }

  /// Refresh data
  Future<void> refresh() async {
    await loadInitial();
  }

  /// Add item to the beginning of the list
  void prependItem(T item) {
    _items.insert(0, item);
    _itemsController.add(_items);
  }

  /// Add item to the end of the list
  void appendItem(T item) {
    _items.add(item);
    _itemsController.add(_items);
  }

  /// Remove item from the list
  void removeItem(T item) {
    _items.remove(item);
    _itemsController.add(_items);
  }

  /// Update item in the list
  void updateItem(T oldItem, T newItem) {
    final index = _items.indexOf(oldItem);
    if (index != -1) {
      _items[index] = newItem;
      _itemsController.add(_items);
    }
  }

  /// Clear all data
  void clear() {
    _items.clear();
    _currentOffset = 0;
    _hasMore = true;
    _itemsController.add(_items);
  }

  /// Dispose resources
  void dispose() {
    _itemsController.close();
    _loadingController.close();
  }
}

/// Mixin for widgets that need lazy loading functionality
mixin LazyLoadingMixin {
  /// Check if should load more based on scroll position
  bool shouldLoadMore(double scrollPosition, double maxScrollExtent,
      {double threshold = 200}) {
    return scrollPosition >= maxScrollExtent - threshold;
  }
}
