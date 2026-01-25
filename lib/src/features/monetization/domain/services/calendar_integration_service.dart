import '../models/calendar_integration.dart';

/// Service for managing calendar integrations
abstract class CalendarIntegrationService {
  /// Gets all calendar integrations for a user
  Future<List<CalendarIntegration>> getUserIntegrations(String userId);

  /// Creates a new calendar integration
  Future<CalendarIntegration> createIntegration({
    required String userId,
    required CalendarProvider provider,
    required String accountName,
    required String calendarId,
    SyncDirection syncDirection = SyncDirection.bidirectional,
    CalendarSyncSettings? syncSettings,
  });

  /// Updates an existing calendar integration
  Future<CalendarIntegration> updateIntegration(
    String integrationId,
    CalendarIntegration integration,
  );

  /// Deletes a calendar integration
  Future<void> deleteIntegration(String integrationId);

  /// Enables or disables a calendar integration
  Future<void> toggleIntegration(String integrationId, bool enabled);

  /// Syncs tasks with external calendar
  Future<void> syncWithCalendar(String integrationId);

  /// Syncs all enabled integrations for a user
  Future<void> syncAllIntegrations(String userId);

  /// Tests connection to external calendar
  Future<bool> testConnection(CalendarProvider provider, String calendarId);

  /// Gets available calendars for a provider
  Future<List<ExternalCalendar>> getAvailableCalendars(
    CalendarProvider provider,
  );

  /// Watches calendar integrations for a user
  Stream<List<CalendarIntegration>> watchUserIntegrations(String userId);
}

/// Represents an external calendar that can be integrated
class ExternalCalendar {
  const ExternalCalendar({
    required this.id,
    required this.name,
    required this.provider,
    this.description,
    this.color,
    this.isReadOnly = false,
  });

  final String id;
  final String name;
  final CalendarProvider provider;
  final String? description;
  final String? color;
  final bool isReadOnly;
}
