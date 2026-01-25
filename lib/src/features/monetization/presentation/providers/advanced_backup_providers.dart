import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/firebase_advanced_backup_service.dart';
import '../../domain/models/advanced_backup.dart';
import '../../domain/services/advanced_backup_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Provider for AdvancedBackupService
final advancedBackupServiceProvider = Provider<AdvancedBackupService>((ref) {
  return FirebaseAdvancedBackupService();
});

/// Provider for user's backup configurations
final userBackupsProvider = StreamProvider<List<AdvancedBackup>>((ref) {
  final service = ref.watch(advancedBackupServiceProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return Stream.value([]);
  }

  return service.watchUserBackups(user.uid);
});

/// Provider for user's backup archives
final userArchivesProvider = StreamProvider<List<BackupArchive>>((ref) {
  final service = ref.watch(advancedBackupServiceProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return Stream.value([]);
  }

  return service.watchUserArchives(user.uid);
});

/// Provider for backup statistics
final backupStatisticsProvider = FutureProvider<BackupStatistics>((ref) {
  final service = ref.watch(advancedBackupServiceProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return const BackupStatistics(
      totalBackups: 0,
      totalArchives: 0,
      totalStorageUsed: 0,
      lastBackupAt: null,
      nextScheduledBackup: null,
      successfulBackups: 0,
      failedBackups: 0,
    );
  }

  return service.getBackupStatistics(user.uid);
});

/// Provider for backup archives of a specific backup
final backupArchivesProvider =
    FutureProvider.family<List<BackupArchive>, String>((ref, backupId) {
  final service = ref.watch(advancedBackupServiceProvider);
  return service.getBackupArchives(backupId);
});

/// Provider for creating backup configuration
final createBackupProvider =
    FutureProvider.family<AdvancedBackup, CreateBackupParams>((ref, params) {
  final service = ref.watch(advancedBackupServiceProvider);
  return service.createBackup(
    userId: params.userId,
    name: params.name,
    backupType: params.backupType,
    frequency: params.frequency,
    retentionDays: params.retentionDays,
    includeAttachments: params.includeAttachments,
    encryptionEnabled: params.encryptionEnabled,
    cloudProvider: params.cloudProvider,
    cloudConfig: params.cloudConfig,
  );
});

/// Provider for performing backup
final performBackupProvider =
    FutureProvider.family<BackupArchive, String>((ref, backupId) {
  final service = ref.watch(advancedBackupServiceProvider);
  return service.performBackup(backupId);
});

/// Provider for validating backup
final validateBackupProvider =
    FutureProvider.family<bool, String>((ref, archiveId) {
  final service = ref.watch(advancedBackupServiceProvider);
  return service.validateBackup(archiveId);
});

/// Provider for restoring from backup
final restoreBackupProvider =
    FutureProvider.family<void, String>((ref, archiveId) {
  final service = ref.watch(advancedBackupServiceProvider);
  return service.restoreFromBackup(archiveId);
});

/// Provider for exporting backup
final exportBackupProvider =
    FutureProvider.family<String, ({String archiveId, CloudProvider provider})>(
        (ref, params) {
  final service = ref.watch(advancedBackupServiceProvider);
  return service.exportBackup(params.archiveId, params.provider);
});

/// Provider for importing backup
final importBackupProvider = FutureProvider.family<BackupArchive,
    ({String userId, String filePath, CloudProvider provider})>((ref, params) {
  final service = ref.watch(advancedBackupServiceProvider);
  return service.importBackup(params.userId, params.filePath, params.provider);
});

/// Parameters for creating backup configuration
class CreateBackupParams {
  const CreateBackupParams({
    required this.userId,
    required this.name,
    required this.backupType,
    required this.frequency,
    this.retentionDays = 30,
    this.includeAttachments = true,
    this.encryptionEnabled = true,
    this.cloudProvider,
    this.cloudConfig = const {},
  });

  final String userId;
  final String name;
  final BackupType backupType;
  final BackupFrequency frequency;
  final int retentionDays;
  final bool includeAttachments;
  final bool encryptionEnabled;
  final CloudProvider? cloudProvider;
  final Map<String, dynamic> cloudConfig;
}
