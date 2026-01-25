import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/firebase_calendar_integration_service.dart';
import '../../domain/models/calendar_integration.dart';
import '../../domain/services/calendar_integration_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Provider for CalendarIntegrationService
final calendarIntegrationServiceProvider =
    Provider<CalendarIntegrationService>((ref) {
  return FirebaseCalendarIntegrationService();
});

/// Provider for user's calendar integrations
final userCalendarIntegrationsProvider =
    StreamProvider<List<CalendarIntegration>>((ref) {
  final service = ref.watch(calendarIntegrationServiceProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return Stream.value([]);
  }

  return service.watchUserIntegrations(user.uid);
});

/// Provider for available external calendars
final availableCalendarsProvider =
    FutureProvider.family<List<ExternalCalendar>, CalendarProvider>(
        (ref, provider) {
  final service = ref.watch(calendarIntegrationServiceProvider);
  return service.getAvailableCalendars(provider);
});

/// Provider for testing calendar connection
final testCalendarConnectionProvider = FutureProvider.family<bool,
    ({CalendarProvider provider, String calendarId})>((ref, params) {
  final service = ref.watch(calendarIntegrationServiceProvider);
  return service.testConnection(params.provider, params.calendarId);
});

/// Provider for syncing all integrations
final syncAllIntegrationsProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(calendarIntegrationServiceProvider);
  final user = ref.watch(currentUserProvider);

  if (user != null) {
    await service.syncAllIntegrations(user.uid);
  }
});

/// Provider for creating calendar integration
final createCalendarIntegrationProvider =
    FutureProvider.family<CalendarIntegration, CreateCalendarIntegrationParams>(
        (ref, params) {
  final service = ref.watch(calendarIntegrationServiceProvider);
  return service.createIntegration(
    userId: params.userId,
    provider: params.provider,
    accountName: params.accountName,
    calendarId: params.calendarId,
    syncDirection: params.syncDirection,
    syncSettings: params.syncSettings,
  );
});

/// Parameters for creating calendar integration
class CreateCalendarIntegrationParams {
  const CreateCalendarIntegrationParams({
    required this.userId,
    required this.provider,
    required this.accountName,
    required this.calendarId,
    this.syncDirection = SyncDirection.bidirectional,
    this.syncSettings,
  });

  final String userId;
  final CalendarProvider provider;
  final String accountName;
  final String calendarId;
  final SyncDirection syncDirection;
  final CalendarSyncSettings? syncSettings;
}
