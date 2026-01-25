import 'package:equatable/equatable.dart';

/// User notification preferences model
class NotificationPreferences extends Equatable {
  const NotificationPreferences({
    this.enablePushNotifications = true,
    this.enableDailySummary = true,
    this.enableTeamUpdates = true,
    this.enableNightSummary = true,
    this.enableTaskReminders = true,
    this.morningTime = const TimeOfDay(hour: 8, minute: 0),
    this.nightTime = const TimeOfDay(hour: 22, minute: 0),
    this.quietHoursStart = const TimeOfDay(hour: 22, minute: 0),
    this.quietHoursEnd = const TimeOfDay(hour: 8, minute: 0),
    this.enableQuietHours = true,
  });

  final bool enablePushNotifications;
  final bool enableDailySummary;
  final bool enableTeamUpdates;
  final bool enableNightSummary;
  final bool enableTaskReminders;
  final TimeOfDay morningTime;
  final TimeOfDay nightTime;
  final TimeOfDay quietHoursStart;
  final TimeOfDay quietHoursEnd;
  final bool enableQuietHours;

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      enablePushNotifications: map['enablePushNotifications'] as bool? ?? true,
      enableDailySummary: map['enableDailySummary'] as bool? ?? true,
      enableTeamUpdates: map['enableTeamUpdates'] as bool? ?? true,
      enableNightSummary: map['enableNightSummary'] as bool? ?? true,
      enableTaskReminders: map['enableTaskReminders'] as bool? ?? true,
      morningTime: _timeFromMap(map['morningTime']) ??
          const TimeOfDay(hour: 8, minute: 0),
      nightTime: _timeFromMap(map['nightTime']) ??
          const TimeOfDay(hour: 22, minute: 0),
      quietHoursStart: _timeFromMap(map['quietHoursStart']) ??
          const TimeOfDay(hour: 22, minute: 0),
      quietHoursEnd: _timeFromMap(map['quietHoursEnd']) ??
          const TimeOfDay(hour: 8, minute: 0),
      enableQuietHours: map['enableQuietHours'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enablePushNotifications': enablePushNotifications,
      'enableDailySummary': enableDailySummary,
      'enableTeamUpdates': enableTeamUpdates,
      'enableNightSummary': enableNightSummary,
      'enableTaskReminders': enableTaskReminders,
      'morningTime': _timeToMap(morningTime),
      'nightTime': _timeToMap(nightTime),
      'quietHoursStart': _timeToMap(quietHoursStart),
      'quietHoursEnd': _timeToMap(quietHoursEnd),
      'enableQuietHours': enableQuietHours,
    };
  }

  static TimeOfDay? _timeFromMap(dynamic timeMap) {
    if (timeMap is Map<String, dynamic>) {
      return TimeOfDay(
        hour: timeMap['hour'] as int? ?? 0,
        minute: timeMap['minute'] as int? ?? 0,
      );
    }
    return null;
  }

  static Map<String, int> _timeToMap(TimeOfDay time) {
    return {
      'hour': time.hour,
      'minute': time.minute,
    };
  }

  NotificationPreferences copyWith({
    bool? enablePushNotifications,
    bool? enableDailySummary,
    bool? enableTeamUpdates,
    bool? enableNightSummary,
    bool? enableTaskReminders,
    TimeOfDay? morningTime,
    TimeOfDay? nightTime,
    TimeOfDay? quietHoursStart,
    TimeOfDay? quietHoursEnd,
    bool? enableQuietHours,
  }) {
    return NotificationPreferences(
      enablePushNotifications:
          enablePushNotifications ?? this.enablePushNotifications,
      enableDailySummary: enableDailySummary ?? this.enableDailySummary,
      enableTeamUpdates: enableTeamUpdates ?? this.enableTeamUpdates,
      enableNightSummary: enableNightSummary ?? this.enableNightSummary,
      enableTaskReminders: enableTaskReminders ?? this.enableTaskReminders,
      morningTime: morningTime ?? this.morningTime,
      nightTime: nightTime ?? this.nightTime,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      enableQuietHours: enableQuietHours ?? this.enableQuietHours,
    );
  }

  /// Check if current time is within quiet hours
  bool isInQuietHours(TimeOfDay currentTime) {
    if (!enableQuietHours) return false;

    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final startMinutes = quietHoursStart.hour * 60 + quietHoursStart.minute;
    final endMinutes = quietHoursEnd.hour * 60 + quietHoursEnd.minute;

    // Handle overnight quiet hours (e.g., 22:00 to 08:00)
    if (startMinutes > endMinutes) {
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }

    // Handle same-day quiet hours (e.g., 12:00 to 14:00)
    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  @override
  List<Object?> get props => [
        enablePushNotifications,
        enableDailySummary,
        enableTeamUpdates,
        enableNightSummary,
        enableTaskReminders,
        morningTime,
        nightTime,
        quietHoursStart,
        quietHoursEnd,
        enableQuietHours,
      ];
}

/// Time of day helper class for notifications
class TimeOfDay extends Equatable {
  const TimeOfDay({required this.hour, required this.minute});

  final int hour;
  final int minute;

  @override
  List<Object?> get props => [hour, minute];

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
