import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:synclife_app/src/core/sync/services/compression_service.dart';

void main() {
  group('CompressionService', () {
    late CompressionService compressionService;

    setUp(() {
      compressionService = CompressionServiceImpl(
        compressionThreshold: 100, // Lower threshold for testing
        compressionLevel: 6,
      );
    });

    group('shouldCompress', () {
      test('should return false for small data', () {
        final smallData = {'key': 'value'};
        expect(compressionService.shouldCompress(smallData), isFalse);
      });

      test('should return true for large data', () {
        final largeData = {
          'key': 'a' * 200, // Large string to exceed threshold
          'array': List.generate(50, (i) => 'item_$i'),
        };
        expect(compressionService.shouldCompress(largeData), isTrue);
      });
    });

    group('compress and decompress', () {
      test('should compress and decompress large data correctly', () async {
        final originalData = {
          'title': 'Test Task with Long Description',
          'description':
              'This is a very long description that should be compressed because it exceeds the compression threshold. ' *
                  10,
          'tags': List.generate(20, (i) => 'tag_$i'),
          'metadata': {
            'created': DateTime.now().toIso8601String(),
            'updated': DateTime.now().toIso8601String(),
            'version': '1.0.0',
          },
        };

        // Compress
        final compressedData = await compressionService.compress(originalData);

        expect(compressedData.isCompressed, isTrue);
        expect(compressedData.compressedSize,
            lessThan(compressedData.originalSize));
        expect(compressedData.checksum, isNotEmpty);

        // Decompress
        final decompressedData =
            await compressionService.decompress(compressedData);

        expect(decompressedData, equals(originalData));
      });

      test('should not compress small data but still provide checksum',
          () async {
        final smallData = {'key': 'value'};

        final compressedData = await compressionService.compress(smallData);

        expect(compressedData.isCompressed, isFalse);
        expect(
            compressedData.compressedSize, equals(compressedData.originalSize));
        expect(compressedData.checksum, isNotEmpty);

        final decompressedData =
            await compressionService.decompress(compressedData);
        expect(decompressedData, equals(smallData));
      });

      test('should throw exception on checksum mismatch', () async {
        final originalData = {'key': 'value'};
        final compressedData = await compressionService.compress(originalData);

        // Corrupt the checksum
        final corruptedData = CompressedData(
          data: compressedData.data,
          checksum: 'invalid_checksum',
          isCompressed: compressedData.isCompressed,
          originalSize: compressedData.originalSize,
          compressedSize: compressedData.compressedSize,
        );

        expect(
          () => compressionService.decompress(corruptedData),
          throwsA(isA<CompressionException>()),
        );
      });
    });

    group('calculateChecksum', () {
      test('should generate consistent checksums', () {
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);

        final checksum1 = compressionService.calculateChecksum(data);
        final checksum2 = compressionService.calculateChecksum(data);

        expect(checksum1, equals(checksum2));
        expect(checksum1, isNotEmpty);
      });

      test('should generate different checksums for different data', () {
        final data1 = Uint8List.fromList([1, 2, 3]);
        final data2 = Uint8List.fromList([4, 5, 6]);

        final checksum1 = compressionService.calculateChecksum(data1);
        final checksum2 = compressionService.calculateChecksum(data2);

        expect(checksum1, isNot(equals(checksum2)));
      });
    });

    group('CompressedData', () {
      test('should calculate compression statistics correctly', () {
        const originalSize = 1000;
        const compressedSize = 600;

        final compressedData = CompressedData(
          data: Uint8List.fromList([]),
          checksum: 'test_checksum',
          isCompressed: true,
          originalSize: originalSize,
          compressedSize: compressedSize,
        );

        expect(compressedData.compressionRatio, equals(0.6));
        expect(compressedData.spaceSaved, equals(400));
        expect(compressedData.spaceSavedPercentage, equals(40.0));
      });

      test('should serialize and deserialize correctly', () {
        final originalData = CompressedData(
          data: Uint8List.fromList([1, 2, 3, 4, 5]),
          checksum: 'test_checksum',
          isCompressed: true,
          originalSize: 100,
          compressedSize: 60,
        );

        final map = originalData.toMap();
        final deserializedData = CompressedData.fromMap(map);

        expect(deserializedData.data, equals(originalData.data));
        expect(deserializedData.checksum, equals(originalData.checksum));
        expect(
            deserializedData.isCompressed, equals(originalData.isCompressed));
        expect(
            deserializedData.originalSize, equals(originalData.originalSize));
        expect(deserializedData.compressedSize,
            equals(originalData.compressedSize));
      });
    });
  });
}
