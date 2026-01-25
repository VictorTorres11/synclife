import 'package:equatable/equatable.dart';

/// Represents an advanced backup configuration
class AdvancedBackup extends Equatable {
  const AdvancedBackup({
    required this.id,
    required this.userId,
    required this.name,
    required this.backupType,
    required this.frequency,
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
    this.lastBackupAt,
    this.nextBackupAt,
    this.retentionDays = 30,
    this.includeAttachments = true,
    this.encryptionEnabled = true,
    this.cloudProvider,
    this.cloudConfig = const {},
  });

  final String id;
  final String userId;
  final String name;
  final BackupType backupType;
  final BackupFrequency frequency;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastBackupAt;
  final DateTime? nextBackupAt;
  final int retentionDays;
  final bool includeAttachments;
  final bool encryptionEnabled;
  final CloudProvider? cloudProvider;
  final Map<String, dynamic> cloudConfig;

  /// Creates AdvancedBackup from Firestore document data
  factory AdvancedBackup.fromMap(Map<String, dynamic> map) => AdvancedBackup(
        id: map['id'] as String,
        userId: map['userId'] as String,
        name: map['name'] as String,
        backupType: BackupType.values.firstWhere(
          (e) => e.name == map['backupType'],
          orElse: () => BackupType.full,
        ),
        frequency: BackupFrequency.values.firstWhere(
          (e) => e.name == map['frequency'],
          orElse: () => BackupFrequency.daily,
        ),
        isEnabled: map['isEnabled'] as bool,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
        lastBackupAt: map['lastBackupAt'] != null
            ? DateTime.parse(map['lastBackupAt'] as String)
            : null,
        nextBackupAt: map['nextBackupAt'] != null
            ? DateTime.parse(map['nextBackupAt'] as String)
            : null,
        retentionDays: map['retentionDays'] as int? ?? 30,
        includeAttachments: map['includeAttachments'] as bool? ?? true,
        encryptionEnabled: map['encryptionEnabled'] as bool? ?? true,
        cloudProvider: map['cloudProvider'] != null
            ? CloudProvider.values.firstWhere(
                (e) => e.name == map['cloudProvider'],
                orElse: () => CloudProvider.googleDrive,
              )
            : null,
        cloudConfig: Map<String, dynamic>.from(
          map['cloudConfig'] as Map? ?? {},
        ),
      );

  /// Converts AdvancedBackup to Firestore document data
  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'name': name,
        'backupType': backupType.name,
        'frequency': frequency.name,
        'isEnabled': isEnabled,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'lastBackupAt': lastBackupAt?.toIso8601String(),
        'nextBackupAt': nextBackupAt?.toIso8601String(),
        'retentionDays': retentionDays,
        'includeAttachments': includeAttachments,
        'encryptionEnabled': encryptionEnabled,
        'cloudProvider': cloudProvider?.name,
        'cloudConfig': cloudConfig,
      };

  AdvancedBackup copyWith({
    String? id,
    String? userId,
    String? name,
    BackupType? backupType,
    BackupFrequency? frequency,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastBackupAt,
    DateTime? nextBackupAt,
    int? retentionDays,
    bool? includeAttachments,
    bool? encryptionEnabled,
    CloudProvider? cloudProvider,
    Map<String, dynamic>? cloudConfig,
  }) =>
      AdvancedBackup(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        backupType: backupType ?? this.backupType,
        frequency: frequency ?? this.frequency,
        isEnabled: isEnabled ?? this.isEnabled,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastBackupAt: lastBackupAt ?? this.lastBackupAt,
        nextBackupAt: nextBackupAt ?? this.nextBackupAt,
        retentionDays: retentionDays ?? this.retentionDays,
        includeAttachments: includeAttachments ?? this.includeAttachments,
        encryptionEnabled: encryptionEnabled ?? this.encryptionEnabled,
        cloudProvider: cloudProvider ?? this.cloudProvider,
        cloudConfig: cloudConfig ?? this.cloudConfig,
      );

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        backupType,
        frequency,
        isEnabled,
        createdAt,
        updatedAt,
        lastBackupAt,
        nextBackupAt,
        retentionDays,
        includeAttachments,
        encryptionEnabled,
        cloudProvider,
        cloudConfig,
      ];
}

/// Types of backup
enum BackupType {
  full, // Complete data backup
  incremental, // Only changes since last backup
  differential, // Changes since last full backup
}

/// Backup frequency options
enum BackupFrequency {
  manual, // User-triggered only
  daily,
  weekly,
  monthly,
}

/// Supported cloud storage providers
enum CloudProvider {
  googleDrive,
  iCloudDrive,
  oneDrive,
  dropbox,
  s3,
}

/// Represents a backup file/archive
class BackupArchive extends Equatable {
  const BackupArchive({
    required this.id,
    required this.backupId,
    required this.userId,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.backupType,
    required this.createdAt,
    required this.isEncrypted,
    this.checksum,
    this.metadata = const {},
  });

  final String id;
  final String backupId;
  final String userId;
  final String fileName;
  final String filePath;
  final int fileSize;
  final BackupType backupType;
  final DateTime createdAt;
  final bool isEncrypted;
  final String? checksum;
  final Map<String, dynamic> metadata;

  /// Creates BackupArchive from Firestore document data
  factory BackupArchive.fromMap(Map<String, dynamic> map) => BackupArchive(
        id: map['id'] as String,
        backupId: map['backupId'] as String,
        userId: map['userId'] as String,
        fileName: map['fileName'] as String,
        filePath: map['filePath'] as String,
        fileSize: map['fileSize'] as int,
        backupType: BackupType.values.firstWhere(
          (e) => e.name == map['backupType'],
          orElse: () => BackupType.full,
        ),
        createdAt: DateTime.parse(map['createdAt'] as String),
        isEncrypted: map['isEncrypted'] as bool,
        checksum: map['checksum'] as String?,
        metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? {}),
      );

  /// Converts BackupArchive to Firestore document data
  Map<String, dynamic> toMap() => {
        'id': id,
        'backupId': backupId,
        'userId': userId,
        'fileName': fileName,
        'filePath': filePath,
        'fileSize': fileSize,
        'backupType': backupType.name,
        'createdAt': createdAt.toIso8601String(),
        'isEncrypted': isEncrypted,
        'checksum': checksum,
        'metadata': metadata,
      };

  /// Gets human-readable file size
  String get formattedSize {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024)
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  @override
  List<Object?> get props => [
        id,
        backupId,
        userId,
        fileName,
        filePath,
        fileSize,
        backupType,
        createdAt,
        isEncrypted,
        checksum,
        metadata,
      ];
}
