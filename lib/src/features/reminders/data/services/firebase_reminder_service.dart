import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/models.dart';
import '../../domain/services/reminder_service.dart';
import 'limited_reminder_service.dart';

/// Firebase implementation of ReminderService
/// 
/// This service implements all reminder CRUD operations using Firestore
/// as the backend storage. It integrates with LimitedReminderService
/// to enforce user limitations.
class FirebaseReminderService implements ReminderService {
  FirebaseReminderService({
    required FirebaseFirestore firestore,
    required LimitedReminderService limitationService,
  })  : _firestore = firestore,
        _limitationService = limitationService;

  final FirebaseFirestore _firestore;
  final LimitedReminderService _limitationService;

  /// Reference to the reminders collection in Firestore
  CollectionReference get _remindersCollection =>
      _firestore.collection('reminders');

  /// Creates a new reminder in Firestore
  /// 
  /// This method performs the following steps:
  /// 1. Checks if the user has reached their reminder limit
  /// 2. Generates a unique ID and timestamps
  /// 3. Creates the reminder object
  /// 4. Persists to Firestore
  /// 5. Increments the user's reminder count
  /// 
  /// Throws [ReminderLimitExceededException] if the user has reached their limit.
  @override
  Future<Reminder> createReminder({
    required String content,
    required String userId,
    required String boardId,
    List<String> tags = const [],
    ReminderPriority priority = ReminderPriority.medium,
  }) async {
    // 1. Check user limitations
    await _limitationService.checkReminderLimit(userId);

    // 2. Generate ID and timestamps
    final id = _remindersCollection.doc().id;
    final now = DateTime.now();

    // 3. Create reminder
    final reminder = Reminder(
      id: id,
      content: content,
      userId: userId,
      boardId: boardId,
      tags: tags,
      priority: priority,
      createdAt: now,
      updatedAt: now,
    );

    // 4. Persist to Firestore
    await _remindersCollection.doc(id).set(reminder.toMap());

    // 5. Update limitation counter
    await _limitationService.incrementReminderCount(userId);

    return reminder;
  }

  /// Retrieves all reminders for a specific user
  /// 
  /// Returns reminders ordered by creation date (most recent first).
  @override
  Future<List<Reminder>> getReminders(String userId) async {
    final snapshot = await _remindersCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Reminder.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Retrieves reminders for a specific user and board
  /// 
  /// Returns reminders filtered by board, ordered by creation date (most recent first).
  @override
  Future<List<Reminder>> getRemindersByBoard(
    String userId,
    String boardId,
  ) async {
    final snapshot = await _remindersCollection
        .where('userId', isEqualTo: userId)
        .where('boardId', isEqualTo: boardId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Reminder.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Searches reminders by content using case-insensitive partial matching
  /// 
  /// Note: This performs client-side filtering since Firestore doesn't support
  /// case-insensitive text search natively. For large datasets, consider
  /// implementing a dedicated search solution.
  @override
  Future<List<Reminder>> searchReminders(String userId, String query) async {
    // Get all user reminders first
    final allReminders = await getReminders(userId);

    // Filter by content (case-insensitive)
    final queryLower = query.toLowerCase();
    return allReminders
        .where((reminder) =>
            reminder.content.toLowerCase().contains(queryLower))
        .toList();
  }

  /// Updates an existing reminder with new values
  /// 
  /// Only the provided fields will be updated. The updatedAt timestamp
  /// is automatically set to the current time.
  /// 
  /// Throws an [Exception] if the reminder is not found.
  @override
  Future<Reminder> updateReminder(
    String reminderId, {
    String? content,
    String? boardId,
    List<String>? tags,
    ReminderPriority? priority,
  }) async {
    // Get the existing reminder
    final doc = await _remindersCollection.doc(reminderId).get();
    if (!doc.exists) {
      throw Exception('Reminder not found: $reminderId');
    }

    final existingReminder =
        Reminder.fromMap(doc.data() as Map<String, dynamic>);

    // Create updated reminder with new values
    final updatedReminder = existingReminder.copyWith(
      content: content,
      boardId: boardId,
      tags: tags,
      priority: priority,
      updatedAt: DateTime.now(),
    );

    // Update in Firestore
    await _remindersCollection.doc(reminderId).update(updatedReminder.toMap());

    return updatedReminder;
  }

  /// Deletes a reminder and decrements the user's reminder count
  /// 
  /// This operation is permanent and cannot be undone.
  @override
  Future<void> deleteReminder(String reminderId, String userId) async {
    // Delete from Firestore
    await _remindersCollection.doc(reminderId).delete();

    // Decrement counter
    await _limitationService.decrementReminderCount(userId);
  }

  /// Returns a real-time stream of reminders for a user
  /// 
  /// The stream emits a new list whenever reminders are added, updated, or deleted.
  /// Reminders are ordered by creation date (most recent first).
  @override
  Stream<List<Reminder>> watchReminders(String userId) {
    return _remindersCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Reminder.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Returns a real-time stream of reminders for a specific board
  /// 
  /// The stream emits a new list whenever reminders in the board are added,
  /// updated, or deleted. Reminders are ordered by creation date (most recent first).
  @override
  Stream<List<Reminder>> watchRemindersByBoard(String userId, String boardId) {
    return _remindersCollection
        .where('userId', isEqualTo: userId)
        .where('boardId', isEqualTo: boardId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Reminder.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Returns the total count of reminders for a user
  /// 
  /// This is used for limitation checks and usage indicators.
  @override
  Future<int> getReminderCount(String userId) async {
    final snapshot = await _remindersCollection
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.length;
  }
}
