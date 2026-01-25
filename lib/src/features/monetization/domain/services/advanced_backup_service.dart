import '../models/advanced_backup.dart';

/// Service for managing advanced backup functionality
abstract class AdvancedBackupService {
  /// Gets all backup configurations for a user
  Future<List<AdvancedBackup>> getUserBackups(String userId);

  /// Creates a new backup configuration
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
  });

  /// Updates an existing backup configuration
  Future<AdvancedBackup> updateBackup(
    String backupId,
    AdvancedBackup backup,
  );

  /// Deletes a backup configuration and its archives
  Future<void> deleteBackup(String backupId);

  /// Enables or disables a backup configuration
  Future<void> toggleBackup(String backupId, bool enabled);

  /// Manually triggers a backup
  Future<BackupArchive> performBackup(String backupId);

  /// Restores data from a backup archive
  Future<void> restoreFromBackup(String archiveId);

  /// Gets all backup archives for a user
  Future<List<BackupArchive>> getUserArchives(String userId);

  /// Gets backup archives for a specific backup configuration
  Future<List<BackupArchive>> getBackupArchives(String backupId);

  /// Deletes old backup archives based on retention policy
  Future<void> cleanupOldBackups(String backupId);

  /// Validates backup integrity
  Future<bool> validateBackup(String archiveId);

  /// Exports backup data to external storage
  Future<String> exportBackup(String archiveId, CloudProvider provider);

  /// Imports backup data from external storage
  Future<BackupArchive> importBackup(
    String userId,
    String filePath,
    CloudProvider provider,
  );

  /// Gets backup statistics for a user
  Future<BackupStatistics> getBackupStatistics(String userId);

  /// Watches backup configurations for a user
  Stream<List<AdvancedBackup>> watchUserBackups(String userId);

  /// Watches backup archives for a user
  Stream<List<BackupArchive>> watchUserArchives(String userId);
}

/// Statistics about user's backups
class BackupStatistics {
  const BackupStatistics({
    required this.totalBackups,
    required this.totalArchives,
    required this.totalStorageUsed,
    required this.lastBackupAt,
    required this.nextScheduledBackup,
    required this.successfulBackups,
    required this.failedBackups,
  });

  final int totalBackups;
  final int totalArchives;
  final int totalStorageUsed;
  final DateTime? lastBackupAt;
  final DateTime? nextScheduledBackup;
  final int successfulBackups;
  final int failedBackups;

  /// Gets human-readable storage size
  String get formattedStorageUsed {
    if (totalStorageUsed < 1024) return '${totalStorageUsed}B';
    if (totalStorageUsed < 1024 * 1024) {
      return '${(totalStorageUsed / 1024).toStringAsFixed(1)}KB';
    }
    if (totalStorageUsed < 1024 * 1024 * 1024) {
      return '${(totalStorageUsed / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(totalStorageUsed / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// Gets backup success rate as percentage
  double get successRate {
    final total = successfulBackups + failedBackups;
    if (total == 0) return 0.0;
    return (successfulBackups / total) * 100;
  }
}
