import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import '../../domain/models/advanced_backup.dart';
import '../../domain/services/advanced_backup_service.dart';

/// Firebase implementation of AdvancedBackupService
class FirebaseAdvancedBackupService implements AdvancedBackupService {
  FirebaseAdvancedBackupService({
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = const Uuid();

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  @override
  Future<List<AdvancedBackup>> getUserBackups(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('advanced_backups')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AdvancedBackup.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user backups: $e');
    }
  }

  @override
  Future<AdvancedBackup> createBackup({
    required String userId,
    required String name,
    required BackupType backupType,
    required BackupFrequency frequency,
    int retentionDays = 30,
    bool includeAttachments = true,
    bool encryptionEnabled = true,
    CloudProvider? cloudProvider,
    Map<String, dynamic> cloudConfig = const {},
  }) async {
    try {
      final now = DateTime.now();
      final backup = AdvancedBackup(
        id: _uuid.v4(),
        userId: userId,
        name: name,
        backupType: backupType,
        frequency: frequency,
        isEnabled: true,
        createdAt: now,
        updatedAt: now,
        nextBackupAt: _calculateNextBackup(frequency, now),
        retentionDays: retentionDays,
        includeAttachments: includeAttachments,
        encryptionEnabled: encryptionEnabled,
        cloudProvider: cloudProvider,
        cloudConfig: cloudConfig,
      );

      await _firestore
          .collection('advanced_backups')
          .doc(backup.id)
          .set(backup.toMap());

      return backup;
    } catch (e) {
      throw Exception('Failed to create backup: $e');
    }
  }

  @override
  Future<AdvancedBackup> updateBackup(
    String backupId,
    AdvancedBackup backup,
  ) async {
    try {
      final updatedBackup = backup.copyWith(
        updatedAt: DateTime.now(),
        nextBackupAt: _calculateNextBackup(backup.frequency, DateTime.now()),
      );

      await _firestore
          .collection('advanced_backups')
          .doc(backupId)
          .update(updatedBackup.toMap());

      return updatedBackup;
    } catch (e) {
      throw Exception('Failed to update backup: $e');
    }
  }

  @override
  Future<void> deleteBackup(String backupId) async {
    try {
      // Delete all associated archives first
      final archives = await getBackupArchives(backupId);
      for (final archive in archives) {
        await _deleteArchiveFile(archive);
        await _firestore.collection('backup_archives').doc(archive.id).delete();
      }

      // Delete the backup configuration
      await _firestore.collection('advanced_backups').doc(backupId).delete();
    } catch (e) {
      throw Exception('Failed to delete backup: $e');
    }
  }

  @override
  Future<void> toggleBackup(String backupId, bool enabled) async {
    try {
      final updateData = {
        'isEnabled': enabled,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (enabled) {
        // Recalculate next backup time when enabling
        final doc =
            await _firestore.collection('advanced_backups').doc(backupId).get();

        if (doc.exists) {
          final backup = AdvancedBackup.fromMap(doc.data()!);
          final nextBackup =
              _calculateNextBackup(backup.frequency, DateTime.now());
          if (nextBackup != null) {
            updateData['nextBackupAt'] = nextBackup.toIso8601String();
          }
        }
      }

      await _firestore
          .collection('advanced_backups')
          .doc(backupId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to toggle backup: $e');
    }
  }

  @override
  Future<BackupArchive> performBackup(String backupId) async {
    try {
      final doc =
          await _firestore.collection('advanced_backups').doc(backupId).get();

      if (!doc.exists) {
        throw Exception('Backup configuration not found: $backupId');
      }

      final backup = AdvancedBackup.fromMap(doc.data()!);

      if (!backup.isEnabled) {
        throw Exception('Backup is disabled: $backupId');
      }

      // Generate backup data
      final backupData = await _generateBackupData(backup);

      // Encrypt if enabled
      final finalData = backup.encryptionEnabled
          ? await _encryptData(backupData)
          : backupData;

      // Calculate checksum
      final checksum = sha256.convert(finalData).toString();

      // Generate archive ID first
      final archiveId = _uuid.v4();

      // Create archive record
      final archive = BackupArchive(
        id: archiveId,
        backupId: backupId,
        userId: backup.userId,
        fileName: _generateFileName(backup),
        filePath: 'backups/${backup.userId}/$archiveId',
        fileSize: finalData.length,
        backupType: backup.backupType,
        createdAt: DateTime.now(),
        isEncrypted: backup.encryptionEnabled,
        checksum: checksum,
        metadata: {
          'backupName': backup.name,
          'includeAttachments': backup.includeAttachments,
        },
      );

      // Upload to Firebase Storage
      await _uploadArchiveFile(archive, finalData);

      // Save archive record
      await _firestore
          .collection('backup_archives')
          .doc(archive.id)
          .set(archive.toMap());

      // Update backup configuration
      await _firestore.collection('advanced_backups').doc(backupId).update({
        'lastBackupAt': DateTime.now().toIso8601String(),
        'nextBackupAt': _calculateNextBackup(backup.frequency, DateTime.now())
            ?.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Clean up old backups if needed
      await cleanupOldBackups(backupId);

      return archive;
    } catch (e) {
      throw Exception('Failed to perform backup: $e');
    }
  }

  @override
  Future<void> restoreFromBackup(String archiveId) async {
    try {
      final doc =
          await _firestore.collection('backup_archives').doc(archiveId).get();

      if (!doc.exists) {
        throw Exception('Backup archive not found: $archiveId');
      }

      final archive = BackupArchive.fromMap(doc.data()!);

      // Download archive file
      final data = await _downloadArchiveFile(archive);

      // Decrypt if needed
      final finalData = archive.isEncrypted ? await _decryptData(data) : data;

      // Validate checksum
      final calculatedChecksum = sha256.convert(finalData).toString();
      if (archive.checksum != null && calculatedChecksum != archive.checksum) {
        throw Exception('Backup integrity check failed');
      }

      // Restore data
      await _restoreBackupData(archive.userId, finalData);
    } catch (e) {
      throw Exception('Failed to restore from backup: $e');
    }
  }

  @override
  Future<List<BackupArchive>> getUserArchives(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('backup_archives')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => BackupArchive.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user archives: $e');
    }
  }

  @override
  Future<List<BackupArchive>> getBackupArchives(String backupId) async {
    try {
      final querySnapshot = await _firestore
          .collection('backup_archives')
          .where('backupId', isEqualTo: backupId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => BackupArchive.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get backup archives: $e');
    }
  }

  @override
  Future<void> cleanupOldBackups(String backupId) async {
    try {
      final doc =
          await _firestore.collection('advanced_backups').doc(backupId).get();

      if (!doc.exists) return;

      final backup = AdvancedBackup.fromMap(doc.data()!);
      final cutoffDate =
          DateTime.now().subtract(Duration(days: backup.retentionDays));

      final oldArchives = await _firestore
          .collection('backup_archives')
          .where('backupId', isEqualTo: backupId)
          .where('createdAt', isLessThan: cutoffDate.toIso8601String())
          .get();

      for (final doc in oldArchives.docs) {
        final archive = BackupArchive.fromMap(doc.data());
        await _deleteArchiveFile(archive);
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to cleanup old backups: $e');
    }
  }

  @override
  Future<bool> validateBackup(String archiveId) async {
    try {
      final doc =
          await _firestore.collection('backup_archives').doc(archiveId).get();

      if (!doc.exists) return false;

      final archive = BackupArchive.fromMap(doc.data()!);

      // Download and verify checksum
      final data = await _downloadArchiveFile(archive);
      final calculatedChecksum = sha256.convert(data).toString();

      return archive.checksum == calculatedChecksum;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String> exportBackup(String archiveId, CloudProvider provider) async {
    try {
      // This would implement export to external cloud providers
      // For now, return a placeholder path
      return 'exported/${archiveId}_${provider.name}';
    } catch (e) {
      throw Exception('Failed to export backup: $e');
    }
  }

  @override
  Future<BackupArchive> importBackup(
    String userId,
    String filePath,
    CloudProvider provider,
  ) async {
    try {
      // This would implement import from external cloud providers
      // For now, create a placeholder archive
      final archive = BackupArchive(
        id: _uuid.v4(),
        backupId: 'imported',
        userId: userId,
        fileName: 'imported_backup.zip',
        filePath: filePath,
        fileSize: 0,
        backupType: BackupType.full,
        createdAt: DateTime.now(),
        isEncrypted: false,
      );

      await _firestore
          .collection('backup_archives')
          .doc(archive.id)
          .set(archive.toMap());

      return archive;
    } catch (e) {
      throw Exception('Failed to import backup: $e');
    }
  }

  @override
  Future<BackupStatistics> getBackupStatistics(String userId) async {
    try {
      final backups = await getUserBackups(userId);
      final archives = await getUserArchives(userId);

      final totalStorageUsed = archives.fold<int>(
        0,
        (sum, archive) => sum + archive.fileSize,
      );

      final lastBackupAt =
          archives.isNotEmpty ? archives.first.createdAt : null;

      final nextScheduledBackup = backups
          .where((b) => b.isEnabled && b.nextBackupAt != null)
          .map((b) => b.nextBackupAt!)
          .fold<DateTime?>(
            null,
            (earliest, date) =>
                earliest == null || date.isBefore(earliest) ? date : earliest,
          );

      return BackupStatistics(
        totalBackups: backups.length,
        totalArchives: archives.length,
        totalStorageUsed: totalStorageUsed,
        lastBackupAt: lastBackupAt,
        nextScheduledBackup: nextScheduledBackup,
        successfulBackups: archives.length, // Simplified
        failedBackups: 0, // Would track failures in real implementation
      );
    } catch (e) {
      throw Exception('Failed to get backup statistics: $e');
    }
  }

  @override
  Stream<List<AdvancedBackup>> watchUserBackups(String userId) {
    return _firestore
        .collection('advanced_backups')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdvancedBackup.fromMap(doc.data()))
            .toList());
  }

  @override
  Stream<List<BackupArchive>> watchUserArchives(String userId) {
    return _firestore
        .collection('backup_archives')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BackupArchive.fromMap(doc.data()))
            .toList());
  }

  // Private helper methods

  DateTime? _calculateNextBackup(BackupFrequency frequency, DateTime from) {
    switch (frequency) {
      case BackupFrequency.manual:
        return null;
      case BackupFrequency.daily:
        return from.add(const Duration(days: 1));
      case BackupFrequency.weekly:
        return from.add(const Duration(days: 7));
      case BackupFrequency.monthly:
        return DateTime(from.year, from.month + 1, from.day);
    }
  }

  String _generateFileName(AdvancedBackup backup) {
    final timestamp = DateTime.now().toIso8601String().split('T')[0];
    final type = backup.backupType.name;
    return 'synclife_${backup.name}_${type}_$timestamp.zip';
  }

  Future<Uint8List> _generateBackupData(AdvancedBackup backup) async {
    // This would generate the actual backup data
    // For now, return placeholder data
    final data = {
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'userId': backup.userId,
      'backupType': backup.backupType.name,
      'includeAttachments': backup.includeAttachments,
      // Would include actual user data here
    };

    return Uint8List.fromList(utf8.encode(json.encode(data)));
  }

  Future<Uint8List> _encryptData(Uint8List data) async {
    // This would implement actual encryption
    // For now, return the data as-is
    return data;
  }

  Future<Uint8List> _decryptData(Uint8List data) async {
    // This would implement actual decryption
    // For now, return the data as-is
    return data;
  }

  Future<void> _uploadArchiveFile(BackupArchive archive, Uint8List data) async {
    // In a real implementation, this would upload to Firebase Storage
    // For now, we'll simulate the upload
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<Uint8List> _downloadArchiveFile(BackupArchive archive) async {
    // In a real implementation, this would download from Firebase Storage
    // For now, return empty data
    await Future.delayed(const Duration(milliseconds: 100));
    return Uint8List(0);
  }

  Future<void> _deleteArchiveFile(BackupArchive archive) async {
    // In a real implementation, this would delete from Firebase Storage
    // For now, just simulate the operation
    await Future.delayed(const Duration(milliseconds: 50));
  }

  Future<void> _restoreBackupData(String userId, Uint8List data) async {
    // This would implement the actual data restoration
    // For now, just simulate the process
    final jsonData = json.decode(utf8.decode(data));
    print('Restoring backup for user $userId: $jsonData');
  }
}
