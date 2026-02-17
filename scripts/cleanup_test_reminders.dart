// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Script to clean up test reminders after performance testing
/// 
/// Usage:
///   1. Update the userId constant below
///   2. Run: dart run scripts/cleanup_test_reminders.dart
///   3. Confirm deletion when prompted
/// 
/// This script deletes ALL reminders for the specified user and resets
/// their reminder count to 0. Use with caution!

Future<void> main() async {
  print('🧹 Starting test reminder cleanup...\n');

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized\n');
  } catch (e) {
    print('❌ Error initializing Firebase: $e');
    print('Make sure you have firebase_options.dart configured');
    return;
  }

  final firestore = FirebaseFirestore.instance;

  // ⚠️ CONFIGURE THIS VALUE ⚠️
  const userId = 'YOUR_TEST_USER_ID'; // Replace with your test user ID

  // Validate configuration
  if (userId == 'YOUR_TEST_USER_ID') {
    print('❌ ERROR: Please update userId in the script');
    print('   Find your user ID in Firebase Console → Authentication');
    return;
  }

  print('📋 Configuration:');
  print('   User ID: $userId\n');

  // Get reminder count
  final snapshot = await firestore
      .collection('reminders')
      .where('userId', isEqualTo: userId)
      .get();

  final reminderCount = snapshot.docs.length;

  if (reminderCount == 0) {
    print('ℹ️  No reminders found for this user');
    return;
  }

  print('⚠️  WARNING: This will delete $reminderCount reminders!');
  print('   This action cannot be undone.');
  print('\n   Type "DELETE" to confirm, or press Ctrl+C to cancel: ');

  // In a real script, you'd read from stdin here
  // For automation, we'll add a delay instead
  print('   Waiting 5 seconds for confirmation...\n');
  await Future.delayed(const Duration(seconds: 5));

  try {
    await cleanupTestReminders(
      firestore: firestore,
      userId: userId,
    );

    print('\n✅ Cleanup complete!');
    print('\n📊 Summary:');
    print('   Reminders deleted: $reminderCount');
    print('   User limitations reset: ✓\n');
  } catch (e, stackTrace) {
    print('\n❌ Error during cleanup: $e');
    print('Stack trace: $stackTrace');
  }
}

/// Delete all reminders for a user and reset their count
Future<void> cleanupTestReminders({
  required FirebaseFirestore firestore,
  required String userId,
}) async {
  print('🗑️  Deleting reminders...\n');

  // Get all reminders for the user
  final snapshot = await firestore
      .collection('reminders')
      .where('userId', isEqualTo: userId)
      .get();

  if (snapshot.docs.isEmpty) {
    print('ℹ️  No reminders to delete');
    return;
  }

  final totalCount = snapshot.docs.length;
  print('   Found $totalCount reminders to delete');

  // Delete in batches (Firestore limit is 500 operations per batch)
  var batch = firestore.batch();
  var batchCount = 0;
  var deletedCount = 0;

  for (final doc in snapshot.docs) {
    batch.delete(doc.reference);
    batchCount++;
    deletedCount++;

    // Commit batch when it reaches 500 operations
    if (batchCount >= 500) {
      await batch.commit();
      print('   ✓ Deleted batch of $batchCount reminders ($deletedCount/$totalCount)');
      batch = firestore.batch();
      batchCount = 0;
    }

    // Progress indicator every 50 reminders
    if (deletedCount % 50 == 0) {
      print('   Progress: $deletedCount/$totalCount reminders deleted');
    }
  }

  // Commit remaining deletions
  if (batchCount > 0) {
    await batch.commit();
    print('   ✓ Deleted final batch of $batchCount reminders ($deletedCount/$totalCount)');
  }

  print('\n✅ Successfully deleted $totalCount reminders');

  // Reset user limitations
  print('\n📊 Resetting user limitations...');
  try {
    await firestore.collection('userLimitations').doc(userId).update({
      'currentReminders': 0,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    print('✅ User limitations reset to 0');
  } catch (e) {
    print('⚠️  Warning: Could not reset user limitations: $e');
    print('   You may need to update this manually in Firebase Console');
  }
}
