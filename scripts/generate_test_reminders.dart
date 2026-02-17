// ignore_for_file: avoid_print

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Script to generate test reminders for performance testing
/// 
/// Usage:
///   1. Update the userId and boardIds constants below
///   2. Run: dart run scripts/generate_test_reminders.dart
///   3. Wait for completion message
/// 
/// This script generates 100 test reminders distributed across multiple boards
/// with varying priorities, tags, and creation dates.

Future<void> main() async {
  print('🚀 Starting test reminder generation...\n');

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

  // ⚠️ CONFIGURE THESE VALUES ⚠️
  const userId = 'YOUR_TEST_USER_ID'; // Replace with your test user ID
  final boardIds = [
    'BOARD_ID_1', // Replace with actual board IDs
    'BOARD_ID_2',
    'BOARD_ID_3',
    'BOARD_ID_4',
    'BOARD_ID_5',
  ];

  // Validate configuration
  if (userId == 'YOUR_TEST_USER_ID') {
    print('❌ ERROR: Please update userId in the script');
    print('   Find your user ID in Firebase Console → Authentication');
    return;
  }

  if (boardIds.first == 'BOARD_ID_1') {
    print('❌ ERROR: Please update boardIds in the script');
    print('   Find board IDs in Firebase Console → Firestore → boards collection');
    return;
  }

  print('📋 Configuration:');
  print('   User ID: $userId');
  print('   Boards: ${boardIds.length}');
  print('   Reminders to generate: 100\n');

  // Confirm before proceeding
  print('⚠️  This will create 100 test reminders in Firestore');
  print('   Press Ctrl+C to cancel, or wait 3 seconds to continue...\n');
  await Future.delayed(const Duration(seconds: 3));

  try {
    await generateTestReminders(
      firestore: firestore,
      userId: userId,
      boardIds: boardIds,
      count: 100,
    );

    print('\n✅ Test reminder generation complete!');
    print('\n📊 Next steps:');
    print('   1. Open the app and navigate to Reminders page');
    print('   2. Follow the testing guide in LARGE_DATASET_TESTING_GUIDE.md');
    print('   3. Document performance metrics');
    print('   4. Clean up test data when done\n');
  } catch (e, stackTrace) {
    print('\n❌ Error generating test reminders: $e');
    print('Stack trace: $stackTrace');
  }
}

/// Generate test reminders with realistic data
Future<void> generateTestReminders({
  required FirebaseFirestore firestore,
  required String userId,
  required List<String> boardIds,
  required int count,
}) async {
  final random = Random();
  final priorities = ['low', 'medium', 'high'];
  final tags = [
    'work',
    'personal',
    'urgent',
    'later',
    'important',
    'shopping',
    'health',
    'finance',
    'home',
    'travel'
  ];

  print('📝 Generating $count test reminders...\n');

  var batch = firestore.batch();
  var batchCount = 0;
  var totalCount = 0;

  for (int i = 1; i <= count; i++) {
    final docRef = firestore.collection('reminders').doc();

    // Generate realistic content
    final content = _generateReminderContent(i, random);

    // Distribute across boards
    final boardId = boardIds[i % boardIds.length];

    // Vary priorities (60% medium, 25% high, 15% low)
    final priorityRoll = random.nextInt(100);
    final priority = priorityRoll < 15
        ? 'low'
        : priorityRoll < 40
            ? 'high'
            : 'medium';

    // Random 1-3 tags
    final tagCount = 1 + random.nextInt(3);
    final reminderTags = List.generate(
      tagCount,
      (_) => tags[random.nextInt(tags.length)],
    ).toSet().toList(); // Remove duplicates

    // Stagger creation dates (most recent first)
    final createdAt = DateTime.now().subtract(Duration(
      hours: i,
      minutes: random.nextInt(60),
    ));

    final reminder = {
      'id': docRef.id,
      'content': content,
      'userId': userId,
      'boardId': boardId,
      'priority': priority,
      'tags': reminderTags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': createdAt.toIso8601String(),
    };

    batch.set(docRef, reminder);
    batchCount++;
    totalCount++;

    // Firestore batch limit is 500 operations
    if (batchCount >= 500) {
      await batch.commit();
      print('   ✓ Committed batch of $batchCount reminders ($totalCount/$count)');
      batch = firestore.batch();
      batchCount = 0;
    }

    // Progress indicator every 10 reminders
    if (i % 10 == 0) {
      print('   Progress: $i/$count reminders generated');
    }
  }

  // Commit remaining reminders
  if (batchCount > 0) {
    await batch.commit();
    print('   ✓ Committed final batch of $batchCount reminders ($totalCount/$count)');
  }

  print('\n✅ Successfully generated $count test reminders');

  // Update user limitations
  print('\n📊 Updating user limitations...');
  try {
    await firestore.collection('userLimitations').doc(userId).update({
      'currentReminders': count,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    print('✅ User limitations updated');
  } catch (e) {
    print('⚠️  Warning: Could not update user limitations: $e');
    print('   You may need to update this manually in Firebase Console');
  }
}

/// Generate realistic reminder content
String _generateReminderContent(int index, Random random) {
  final templates = [
    // Work-related
    'Review project documentation for Q${1 + random.nextInt(4)}',
    'Send email to team about upcoming deadline',
    'Update task board with latest progress',
    'Prepare presentation slides for meeting',
    'Schedule meeting with client',
    'Review code changes in PR #${random.nextInt(1000)}',
    'Write unit tests for new feature',
    'Update README file with new instructions',
    'Fix bug in authentication module',
    'Deploy changes to staging environment',

    // Personal
    'Buy groceries for dinner tonight',
    'Call dentist for appointment',
    'Pick up dry cleaning',
    'Pay electricity bill',
    'Schedule car maintenance',
    'Book flight tickets for vacation',
    'Renew gym membership',
    'Order birthday gift for friend',
    'Water plants in the garden',
    'Clean out garage',

    // Health
    'Take vitamins after breakfast',
    'Schedule annual checkup',
    'Refill prescription medication',
    'Go for 30-minute walk',
    'Drink 8 glasses of water today',
    'Prepare healthy meal for lunch',
    'Book eye exam appointment',
    'Update health insurance information',

    // Finance
    'Review monthly budget',
    'Pay credit card bill',
    'Transfer money to savings account',
    'Check investment portfolio',
    'File expense report',
    'Update financial spreadsheet',
    'Review subscription services',

    // Home
    'Fix leaky faucet in bathroom',
    'Replace air filter in HVAC',
    'Organize closet',
    'Clean refrigerator',
    'Change light bulbs',
    'Vacuum living room',
    'Take out trash and recycling',

    // Shopping
    'Buy new running shoes',
    'Order office supplies',
    'Purchase birthday card',
    'Get new phone charger',
    'Buy ingredients for recipe',

    // Learning
    'Watch tutorial on Flutter animations',
    'Read chapter 5 of programming book',
    'Complete online course module',
    'Practice Spanish for 20 minutes',
    'Review notes from last meeting',
  ];

  // Select a template and add variation
  final template = templates[random.nextInt(templates.length)];

  // Occasionally add a number or date to make it unique
  if (random.nextInt(3) == 0) {
    return '$template (#$index)';
  }

  return template;
}
