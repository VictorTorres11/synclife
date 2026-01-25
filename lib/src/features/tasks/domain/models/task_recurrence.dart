/// Enumeration of task recurrence patterns
enum TaskRecurrence {
  /// Task occurs only once
  none,
  
  /// Task repeats daily
  daily,
  
  /// Task repeats weekly
  weekly,
  
  /// Task repeats monthly
  monthly,
  
  /// Task has custom recurrence pattern
  custom;

  /// Convert enum to string for storage
  String toJson() => name;

  /// Create enum from string
  static TaskRecurrence fromJson(String json) {
    return TaskRecurrence.values.firstWhere(
      (e) => e.name == json,
      orElse: () => TaskRecurrence.none,
    );
  }
}