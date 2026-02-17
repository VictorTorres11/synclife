/// Enumeration of reminder priority levels
enum ReminderPriority {
  /// Low priority reminder
  low,
  
  /// Medium priority reminder (default)
  medium,
  
  /// High priority reminder
  high;

  /// Convert enum to string for storage
  String toJson() => name;

  /// Create enum from string
  static ReminderPriority fromJson(String json) {
    return ReminderPriority.values.firstWhere(
      (e) => e.name == json,
      orElse: () => ReminderPriority.medium,
    );
  }
}
