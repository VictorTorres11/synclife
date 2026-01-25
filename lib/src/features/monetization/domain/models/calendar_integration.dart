import 'package:equatable/equatable.dart';

/// Represents a calendar integration configuration
class CalendarIntegration extends Equatable {
  const CalendarIntegration({
    required this.id,
    required this.userId,
    required this.provider,
    required this.accountName,
    required this.calendarId,
    required this.isEnabled,
    required this.syncDirection,
    required this.createdAt,
    required this.updatedAt,
    this.lastSyncAt,
    this.syncSettings = const CalendarSyncSettings(),
  });

  final String id;
  final String userId;
  final CalendarProvider provider;
  final String accountName;
  final String calendarId;
  final bool isEnabled;
  final SyncDirection syncDirection;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSyncAt;
  final CalendarSyncSettings syncSettings;

  /// Creates CalendarIntegration from Firestore document data
  factory CalendarIntegration.fromMap(Map<String, dynamic> map) =>
      CalendarIntegration(
        id: map['id'] as String,
        userId: map['userId'] as String,
        provider: CalendarProvider.values.firstWhere(
          (e) => e.name == map['provider'],
          orElse: () => CalendarProvider.google,
        ),
        accountName: map['accountName'] as String,
        calendarId: map['calendarId'] as String,
        isEnabled: map['isEnabled'] as bool,
        syncDirection: SyncDirection.values.firstWhere(
          (e) => e.name == map['syncDirection'],
          orElse: () => SyncDirection.bidirectional,
        ),
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
        lastSyncAt: map['lastSyncAt'] != null
            ? DateTime.parse(map['lastSyncAt'] as String)
            : null,
        syncSettings: CalendarSyncSettings.fromMap(
          Map<String, dynamic>.from(map['syncSettings'] as Map? ?? {}),
        ),
      );

  /// Converts CalendarIntegration to Firestore document data
  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'provider': provider.name,
        'accountName': accountName,
        'calendarId': calendarId,
        'isEnabled': isEnabled,
        'syncDirection': syncDirection.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'lastSyncAt': lastSyncAt?.toIso8601String(),
        'syncSettings': syncSettings.toMap(),
      };

  CalendarIntegration copyWith({
    String? id,
    String? userId,
    CalendarProvider? provider,
    String? accountName,
    String? calendarId,
    bool? isEnabled,
    SyncDirection? syncDirection,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSyncAt,
    CalendarSyncSettings? syncSettings,
  }) =>
      CalendarIntegration(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        provider: provider ?? this.provider,
        accountName: accountName ?? this.accountName,
        calendarId: calendarId ?? this.calendarId,
        isEnabled: isEnabled ?? this.isEnabled,
        syncDirection: syncDirection ?? this.syncDirection,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
        syncSettings: syncSettings ?? this.syncSettings,
      );

  @override
  List<Object?> get props => [
        id,
        userId,
        provider,
        accountName,
        calendarId,
        isEnabled,
        syncDirection,
        createdAt,
        updatedAt,
        lastSyncAt,
        syncSettings,
      ];
}

/// Supported calendar providers
enum CalendarProvider {
  google,
  apple,
  outlook,
  caldav,
}

/// Direction of calendar synchronization
enum SyncDirection {
  toCalendar, // SyncLife -> Calendar only
  fromCalendar, // Calendar -> SyncLife only
  bidirectional, // Both directions
}

/// Settings for calendar synchronization
class CalendarSyncSettings extends Equatable {
  const CalendarSyncSettings({
    this.syncCompletedTasks = true,
    this.syncRecurringTasks = true,
    this.syncTaskDescriptions = true,
    this.syncTaskTags = false,
    this.createAllDayEvents = false,
    this.defaultEventDuration = const Duration(hours: 1),
    this.reminderMinutes = 15,
  });

  final bool syncCompletedTasks;
  final bool syncRecurringTasks;
  final bool syncTaskDescriptions;
  final bool syncTaskTags;
  final bool createAllDayEvents;
  final Duration defaultEventDuration;
  final int reminderMinutes;

  /// Creates CalendarSyncSettings from map
  factory CalendarSyncSettings.fromMap(Map<String, dynamic> map) =>
      CalendarSyncSettings(
        syncCompletedTasks: map['syncCompletedTasks'] as bool? ?? true,
        syncRecurringTasks: map['syncRecurringTasks'] as bool? ?? true,
        syncTaskDescriptions: map['syncTaskDescriptions'] as bool? ?? true,
        syncTaskTags: map['syncTaskTags'] as bool? ?? false,
        createAllDayEvents: map['createAllDayEvents'] as bool? ?? false,
        defaultEventDuration: Duration(
          minutes: map['defaultEventDurationMinutes'] as int? ?? 60,
        ),
        reminderMinutes: map['reminderMinutes'] as int? ?? 15,
      );

  /// Converts CalendarSyncSettings to map
  Map<String, dynamic> toMap() => {
        'syncCompletedTasks': syncCompletedTasks,
        'syncRecurringTasks': syncRecurringTasks,
        'syncTaskDescriptions': syncTaskDescriptions,
        'syncTaskTags': syncTaskTags,
        'createAllDayEvents': createAllDayEvents,
        'defaultEventDurationMinutes': defaultEventDuration.inMinutes,
        'reminderMinutes': reminderMinutes,
      };

  CalendarSyncSettings copyWith({
    bool? syncCompletedTasks,
    bool? syncRecurringTasks,
    bool? syncTaskDescriptions,
    bool? syncTaskTags,
    bool? createAllDayEvents,
    Duration? defaultEventDuration,
    int? reminderMinutes,
  }) =>
      CalendarSyncSettings(
        syncCompletedTasks: syncCompletedTasks ?? this.syncCompletedTasks,
        syncRecurringTasks: syncRecurringTasks ?? this.syncRecurringTasks,
        syncTaskDescriptions: syncTaskDescriptions ?? this.syncTaskDescriptions,
        syncTaskTags: syncTaskTags ?? this.syncTaskTags,
        createAllDayEvents: createAllDayEvents ?? this.createAllDayEvents,
        defaultEventDuration: defaultEventDuration ?? this.defaultEventDuration,
        reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      );

  @override
  List<Object?> get props => [
        syncCompletedTasks,
        syncRecurringTasks,
        syncTaskDescriptions,
        syncTaskTags,
        createAllDayEvents,
        defaultEventDuration,
        reminderMinutes,
      ];
}
