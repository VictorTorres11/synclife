import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Service for compressing and decompressing sync data
abstract class CompressionService {
  /// Compress data and return compressed bytes with checksum
  Future<CompressedData> compress(Map<String, dynamic> data);

  /// Decompress data and verify checksum
  Future<Map<String, dynamic>> decompress(CompressedData compressedData);

  /// Calculate checksum for data integrity verification
  String calculateChecksum(Uint8List data);

  /// Check if data should be compressed based on size threshold
  bool shouldCompress(Map<String, dynamic> data);
}

/// Implementation of CompressionService using gzip compression
class CompressionServiceImpl implements CompressionService {
  CompressionServiceImpl({
    this.compressionThreshold = 1024, // 1KB threshold
    this.compressionLevel = 6, // Balanced compression level
  });

  final int compressionThreshold;
  final int compressionLevel;

  @override
  Future<CompressedData> compress(Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    final originalBytes = utf8.encode(jsonString);

    if (!shouldCompress(data)) {
      // Don't compress small data
      final checksum = calculateChecksum(originalBytes);
      return CompressedData(
        data: originalBytes,
        checksum: checksum,
        isCompressed: false,
        originalSize: originalBytes.length,
        compressedSize: originalBytes.length,
      );
    }

    // Compress using gzip
    final compressedBytes = Uint8List.fromList(gzip.encode(originalBytes));
    final checksum = calculateChecksum(compressedBytes);

    return CompressedData(
      data: compressedBytes,
      checksum: checksum,
      isCompressed: true,
      originalSize: originalBytes.length,
      compressedSize: compressedBytes.length,
    );
  }

  @override
  Future<Map<String, dynamic>> decompress(CompressedData compressedData) async {
    // Verify checksum
    final calculatedChecksum = calculateChecksum(compressedData.data);
    if (calculatedChecksum != compressedData.checksum) {
      throw CompressionException(
        'Checksum mismatch: expected ${compressedData.checksum}, '
        'got $calculatedChecksum',
      );
    }

    Uint8List decodedBytes;
    if (compressedData.isCompressed) {
      // Decompress using gzip
      decodedBytes = Uint8List.fromList(gzip.decode(compressedData.data));
    } else {
      decodedBytes = compressedData.data;
    }

    final jsonString = utf8.decode(decodedBytes);
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  @override
  String calculateChecksum(Uint8List data) {
    final digest = sha256.convert(data);
    return digest.toString();
  }

  @override
  bool shouldCompress(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    final sizeInBytes = utf8.encode(jsonString).length;
    return sizeInBytes >= compressionThreshold;
  }
}

/// Represents compressed data with metadata
class CompressedData {
  const CompressedData({
    required this.data,
    required this.checksum,
    required this.isCompressed,
    required this.originalSize,
    required this.compressedSize,
  });

  final Uint8List data;
  final String checksum;
  final bool isCompressed;
  final int originalSize;
  final int compressedSize;

  /// Compression ratio (0.0 to 1.0, lower is better compression)
  double get compressionRatio => compressedSize / originalSize;

  /// Space saved in bytes
  int get spaceSaved => originalSize - compressedSize;

  /// Space saved as percentage
  double get spaceSavedPercentage => (spaceSaved / originalSize) * 100;

  Map<String, dynamic> toMap() => {
        'data': base64Encode(data),
        'checksum': checksum,
        'isCompressed': isCompressed,
        'originalSize': originalSize,
        'compressedSize': compressedSize,
      };

  factory CompressedData.fromMap(Map<String, dynamic> map) => CompressedData(
        data: base64Decode(map['data'] as String),
        checksum: map['checksum'] as String,
        isCompressed: map['isCompressed'] as bool,
        originalSize: map['originalSize'] as int,
        compressedSize: map['compressedSize'] as int,
      );
}

/// Exception thrown when compression/decompression fails
class CompressionException implements Exception {
  const CompressionException(this.message);

  final String message;

  @override
  String toString() => 'CompressionException: $message';
}
