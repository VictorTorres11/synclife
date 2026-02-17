import '../models/reminder.dart';
import '../../../monetization/domain/models/user_limitations.dart';

/// Thrown when a user exceeds their reminder limit
/// 
/// This exception is thrown when a free user attempts to create a reminder
/// but has already reached their maximum allowed reminders (typically 30).
class LimitExceededException implements Exception {
  const LimitExceededException({
    required this.limitationType,
    required this.currentCount,
    required this.maxCount,
  });

  /// The type of limitation that was exceeded
  final LimitationType limitationType;
  
  /// The current count of items
  final int currentCount;
  
  /// The maximum allowed count
  final int maxCount;

  @override
  String toString() => 
    'Limit exceeded: $currentCount/$maxCount $limitationType';
}

/// Thrown when reminder conversion to task fails
/// 
/// This exception is thrown when the process of converting a reminder
/// to a task encounters an error. The original reminder is preserved
/// in the exception for potential recovery.
class ConversionException implements Exception {
  const ConversionException(this.message, {this.originalReminder});

  /// Error message describing what went wrong
  final String message;
  
  /// The original reminder that failed to convert (if available)
  final Reminder? originalReminder;

  @override
  String toString() => 'ConversionException: $message';
}

/// Thrown when a reminder operation fails
/// 
/// This is a general exception for reminder-related operations
/// that don't fit into more specific exception categories.
class ReminderException implements Exception {
  const ReminderException(this.message);

  /// Error message describing what went wrong
  final String message;

  @override
  String toString() => 'ReminderException: $message';
}
