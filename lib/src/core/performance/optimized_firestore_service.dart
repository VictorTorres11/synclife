import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service for optimized Firestore queries
class OptimizedFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cache for frequently accessed documents
  final Map<String, DocumentSnapshot> _documentCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  /// Cache duration in minutes
  static const int _cacheDurationMinutes = 5;

  /// Get document with caching
  Future<DocumentSnapshot?> getCachedDocument(
      String collection, String documentId) async {
    final cacheKey = '$collection/$documentId';
    final cachedDoc = _documentCache[cacheKey];
    final cacheTime = _cacheTimestamps[cacheKey];

    // Check if cache is still valid
    if (cachedDoc != null && cacheTime != null) {
      final isExpired = DateTime.now().difference(cacheTime).inMinutes >
          _cacheDurationMinutes;
      if (!isExpired) {
        return cachedDoc;
      }
    }

    try {
      final doc = await _firestore.collection(collection).doc(documentId).get();

      // Cache the document
      _documentCache[cacheKey] = doc;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return doc;
    } catch (e) {
      debugPrint('Error getting cached document: $e');
      return null;
    }
  }

  /// Optimized query with pagination and indexing hints
  Query<Map<String, dynamic>> getOptimizedQuery({
    required String collection,
    List<QueryFilter>? filters,
    List<QueryOrder>? orderBy,
    int? limit,
    DocumentSnapshot? startAfter,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(collection);

    // Apply filters
    if (filters != null) {
      for (final filter in filters) {
        query = query.where(filter.field,
            isEqualTo: filter.isEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isLessThan: filter.isLessThan,
            arrayContains: filter.arrayContains,
            whereIn: filter.whereIn);
      }
    }

    // Apply ordering
    if (orderBy != null) {
      for (final order in orderBy) {
        query = query.orderBy(order.field, descending: order.descending);
      }
    }

    // Apply pagination
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query;
  }

  /// Batch write operations for better performance
  Future<void> batchWrite(List<BatchOperation> operations) async {
    final batch = _firestore.batch();

    for (final operation in operations) {
      final docRef =
          _firestore.collection(operation.collection).doc(operation.documentId);

      switch (operation.type) {
        case BatchOperationType.set:
          batch.set(docRef, operation.data!);
          break;
        case BatchOperationType.update:
          batch.update(docRef, operation.data!);
          break;
        case BatchOperationType.delete:
          batch.delete(docRef);
          break;
      }
    }

    await batch.commit();

    // Clear cache for affected documents
    for (final operation in operations) {
      final cacheKey = '${operation.collection}/${operation.documentId}';
      _documentCache.remove(cacheKey);
      _cacheTimestamps.remove(cacheKey);
    }
  }

  /// Get multiple documents efficiently
  Future<List<DocumentSnapshot>> getMultipleDocuments(
      String collection, List<String> documentIds) async {
    if (documentIds.isEmpty) return [];

    // Split into chunks of 10 (Firestore limit for 'in' queries)
    const chunkSize = 10;
    final chunks = <List<String>>[];

    for (int i = 0; i < documentIds.length; i += chunkSize) {
      final end = (i + chunkSize < documentIds.length)
          ? i + chunkSize
          : documentIds.length;
      chunks.add(documentIds.sublist(i, end));
    }

    final List<DocumentSnapshot> results = [];

    for (final chunk in chunks) {
      final query = _firestore
          .collection(collection)
          .where(FieldPath.documentId, whereIn: chunk);
      final snapshot = await query.get();
      results.addAll(snapshot.docs);
    }

    return results;
  }

  /// Clear document cache
  void clearCache() {
    _documentCache.clear();
    _cacheTimestamps.clear();
  }

  /// Clear expired cache entries
  void clearExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value).inMinutes > _cacheDurationMinutes) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _documentCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }
}

/// Query filter configuration
class QueryFilter {
  final String field;
  final dynamic isEqualTo;
  final dynamic isGreaterThan;
  final dynamic isLessThan;
  final dynamic arrayContains;
  final List<dynamic>? whereIn;

  QueryFilter({
    required this.field,
    this.isEqualTo,
    this.isGreaterThan,
    this.isLessThan,
    this.arrayContains,
    this.whereIn,
  });
}

/// Query ordering configuration
class QueryOrder {
  final String field;
  final bool descending;

  QueryOrder({
    required this.field,
    this.descending = false,
  });
}

/// Batch operation configuration
class BatchOperation {
  final String collection;
  final String documentId;
  final BatchOperationType type;
  final Map<String, dynamic>? data;

  BatchOperation({
    required this.collection,
    required this.documentId,
    required this.type,
    this.data,
  });
}

enum BatchOperationType {
  set,
  update,
  delete,
}
