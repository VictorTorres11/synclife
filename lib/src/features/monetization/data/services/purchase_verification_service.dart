import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for verifying in-app purchases with backend
class PurchaseVerificationService {
  PurchaseVerificationService({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;

  /// Verifies an Android purchase with Google Play
  Future<PurchaseVerificationResult> verifyAndroidPurchase({
    required String userId,
    required String productId,
    required String purchaseToken,
    required String packageName,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/verify-android-purchase'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'productId': productId,
          'purchaseToken': purchaseToken,
          'packageName': packageName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PurchaseVerificationResult.fromMap(data);
      } else {
        throw Exception(
            'Verification failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to verify Android purchase: $e');
    }
  }

  /// Verifies an iOS purchase with App Store
  Future<PurchaseVerificationResult> verifyIOSPurchase({
    required String userId,
    required String productId,
    required String transactionId,
    required String receiptData,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/verify-ios-purchase'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'productId': productId,
          'transactionId': transactionId,
          'receiptData': receiptData,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PurchaseVerificationResult.fromMap(data);
      } else {
        throw Exception(
            'Verification failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to verify iOS purchase: $e');
    }
  }

  /// Gets subscription status from backend
  Future<SubscriptionStatusResult> getSubscriptionStatus(String userId) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/subscription-status/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return SubscriptionStatusResult.fromMap(data);
      } else {
        throw Exception(
            'Failed to get status with code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get subscription status: $e');
    }
  }

  void dispose() {
    _httpClient.close();
  }
}

/// Result of purchase verification
class PurchaseVerificationResult {
  const PurchaseVerificationResult({
    required this.isValid,
    required this.productId,
    this.expiryDate,
    this.originalTransactionId,
    this.autoRenewing,
    this.error,
  });

  final bool isValid;
  final String productId;
  final DateTime? expiryDate;
  final String? originalTransactionId;
  final bool? autoRenewing;
  final String? error;

  factory PurchaseVerificationResult.fromMap(Map<String, dynamic> map) {
    return PurchaseVerificationResult(
      isValid: map['isValid'] as bool,
      productId: map['productId'] as String,
      expiryDate: map['expiryDate'] != null
          ? DateTime.parse(map['expiryDate'] as String)
          : null,
      originalTransactionId: map['originalTransactionId'] as String?,
      autoRenewing: map['autoRenewing'] as bool?,
      error: map['error'] as String?,
    );
  }
}

/// Result of subscription status check
class SubscriptionStatusResult {
  const SubscriptionStatusResult({
    required this.isActive,
    required this.plan,
    this.expiryDate,
    this.autoRenewing,
    this.gracePeriodEndDate,
  });

  final bool isActive;
  final String plan;
  final DateTime? expiryDate;
  final bool? autoRenewing;
  final DateTime? gracePeriodEndDate;

  factory SubscriptionStatusResult.fromMap(Map<String, dynamic> map) {
    return SubscriptionStatusResult(
      isActive: map['isActive'] as bool,
      plan: map['plan'] as String,
      expiryDate: map['expiryDate'] != null
          ? DateTime.parse(map['expiryDate'] as String)
          : null,
      autoRenewing: map['autoRenewing'] as bool?,
      gracePeriodEndDate: map['gracePeriodEndDate'] != null
          ? DateTime.parse(map['gracePeriodEndDate'] as String)
          : null,
    );
  }
}
