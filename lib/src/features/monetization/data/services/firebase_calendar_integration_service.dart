import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/calendar_integration.dart';
import '../../domain/services/calendar_integration_service.dart';
import '../../../tasks/domain/models/task.dart';
import '../../../tasks/domain/services/task_service.dart';

/// Firebase implementation of CalendarIntegrationService
class FirebaseCalendarIntegrationService implements CalendarIntegrationService {
  FirebaseCalendarIntegrationService({
    FirebaseFirestore? firestore,
    TaskService? taskService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _taskService = taskService,
        _uuid = const Uuid();

  final FirebaseFirestore _firestore;
  final TaskService? _taskService;
  final Uuid _uuid;

  @override
  Future<List<CalendarIntegration>> getUserIntegrations(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('calendar_integrations')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CalendarIntegration.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user integrations: $e');
    }
  }

  @override
  Future<CalendarIntegration> createIntegration({
    required String userId,
    required CalendarProvider provider,
    required String accountName,
    required String calendarId,
    SyncDirection syncDirection = SyncDirection.bidirectional,
    CalendarSyncSettings? syncSettings,
  }) async {
    try {
      final integration = CalendarIntegration(
        id: _uuid.v4(),
        userId: userId,
        provider: provider,
        accountName: accountName,
        calendarId: calendarId,
        isEnabled: true,
        syncDirection: syncDirection,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncSettings: syncSettings ?? const CalendarSyncSettings(),
      );

      await _firestore
          .collection('calendar_integrations')
          .doc(integration.id)
          .set(integration.toMap());

      return integration;
    } catch (e) {
      throw Exception('Failed to create integration: $e');
    }
  }

  @override
  Future<CalendarIntegration> updateIntegration(
    String integrationId,
    CalendarIntegration integration,
  ) async {
    try {
      final updatedIntegration = integration.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('calendar_integrations')
          .doc(integrationId)
          .update(updatedIntegration.toMap());

      return updatedIntegration;
    } catch (e) {
      throw Exception('Failed to update integration: $e');
    }
  }

  @override
  Future<void> deleteIntegration(String integrationId) async {
    try {
      await _firestore
          .collection('calendar_integrations')
          .doc(integrationId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete integration: $e');
    }
  }

  @override
  Future<void> toggleIntegration(String integrationId, bool enabled) async {
    try {
      await _firestore
          .collection('calendar_integrations')
          .doc(integrationId)
          .update({
        'isEnabled': enabled,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to toggle integration: $e');
    }
  }

  @override
  Future<void> syncWithCalendar(String integrationId) async {
    try {
      final doc = await _firestore
          .collection('calendar_integrations')
          .doc(integrationId)
          .get();

      if (!doc.exists) {
        throw Exception('Integration not found: $integrationId');
      }

      final integration = CalendarIntegration.fromMap(doc.data()!);

      if (!integration.isEnabled) {
        throw Exception('Integration is disabled: $integrationId');
      }

      // Get user's tasks for synchronization
      if (_taskService != null) {
        await _syncTasksWithCalendar(integration);
      }

      // Update last sync time
      await _firestore
          .collection('calendar_integrations')
          .doc(integrationId)
          .update({
        'lastSyncAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to sync with calendar: $e');
    }
  }

  @override
  Future<void> syncAllIntegrations(String userId) async {
    try {
      final integrations = await getUserIntegrations(userId);
      final enabledIntegrations =
          integrations.where((i) => i.isEnabled).toList();

      for (final integration in enabledIntegrations) {
        try {
          await syncWithCalendar(integration.id);
        } catch (e) {
          // Log error but continue with other integrations
          print('Failed to sync integration ${integration.id}: $e');
        }
      }
    } catch (e) {
      throw Exception('Failed to sync all integrations: $e');
    }
  }

  @override
  Future<bool> testConnection(
    CalendarProvider provider,
    String calendarId,
  ) async {
    try {
      // In a real implementation, this would test the actual connection
      // to the external calendar service
      switch (provider) {
        case CalendarProvider.google:
          return await _testGoogleCalendarConnection(calendarId);
        case CalendarProvider.apple:
          return await _testAppleCalendarConnection(calendarId);
        case CalendarProvider.outlook:
          return await _testOutlookCalendarConnection(calendarId);
        case CalendarProvider.caldav:
          return await _testCalDAVConnection(calendarId);
      }
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<ExternalCalendar>> getAvailableCalendars(
    CalendarProvider provider,
  ) async {
    try {
      // In a real implementation, this would fetch calendars from the provider
      switch (provider) {
        case CalendarProvider.google:
          return await _getGoogleCalendars();
        case CalendarProvider.apple:
          return await _getAppleCalendars();
        case CalendarProvider.outlook:
          return await _getOutlookCalendars();
        case CalendarProvider.caldav:
          return await _getCalDAVCalendars();
      }
    } catch (e) {
      throw Exception('Failed to get available calendars: $e');
    }
  }

  @override
  Stream<List<CalendarIntegration>> watchUserIntegrations(String userId) {
    return _firestore
        .collection('calendar_integrations')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CalendarIntegration.fromMap(doc.data()))
            .toList());
  }

  // Private helper methods for calendar synchronization
  Future<void> _syncTasksWithCalendar(CalendarIntegration integration) async {
    // This would implement the actual task synchronization logic
    // For now, we'll just simulate the process

    // In a real implementation:
    // 1. Get tasks from TaskService
    // 2. Convert tasks to calendar events based on sync settings
    // 3. Create/update/delete events in external calendar
    // 4. Handle bidirectional sync if enabled

    await Future.delayed(
        const Duration(milliseconds: 500)); // Simulate API call
  }

  // Provider-specific connection test methods
  Future<bool> _testGoogleCalendarConnection(String calendarId) async {
    // Simulate Google Calendar API connection test
    await Future.delayed(const Duration(milliseconds: 300));
    return calendarId.isNotEmpty;
  }

  Future<bool> _testAppleCalendarConnection(String calendarId) async {
    // Simulate Apple Calendar connection test
    await Future.delayed(const Duration(milliseconds: 300));
    return calendarId.isNotEmpty;
  }

  Future<bool> _testOutlookCalendarConnection(String calendarId) async {
    // Simulate Outlook Calendar connection test
    await Future.delayed(const Duration(milliseconds: 300));
    return calendarId.isNotEmpty;
  }

  Future<bool> _testCalDAVConnection(String calendarId) async {
    // Simulate CalDAV connection test
    await Future.delayed(const Duration(milliseconds: 300));
    return calendarId.isNotEmpty;
  }

  // Provider-specific calendar listing methods
  Future<List<ExternalCalendar>> _getGoogleCalendars() async {
    // Simulate Google Calendar API call
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      const ExternalCalendar(
        id: 'primary',
        name: 'Primary Calendar',
        provider: CalendarProvider.google,
        color: '#1976D2',
      ),
      const ExternalCalendar(
        id: 'work',
        name: 'Work Calendar',
        provider: CalendarProvider.google,
        color: '#F57C00',
      ),
    ];
  }

  Future<List<ExternalCalendar>> _getAppleCalendars() async {
    // Simulate Apple Calendar access
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      const ExternalCalendar(
        id: 'home',
        name: 'Home',
        provider: CalendarProvider.apple,
        color: '#4CAF50',
      ),
      const ExternalCalendar(
        id: 'personal',
        name: 'Personal',
        provider: CalendarProvider.apple,
        color: '#9C27B0',
      ),
    ];
  }

  Future<List<ExternalCalendar>> _getOutlookCalendars() async {
    // Simulate Outlook Calendar API call
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      const ExternalCalendar(
        id: 'calendar',
        name: 'Calendar',
        provider: CalendarProvider.outlook,
        color: '#0078D4',
      ),
    ];
  }

  Future<List<ExternalCalendar>> _getCalDAVCalendars() async {
    // Simulate CalDAV server query
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      const ExternalCalendar(
        id: 'caldav-main',
        name: 'Main Calendar',
        provider: CalendarProvider.caldav,
        color: '#607D8B',
      ),
    ];
  }
}
