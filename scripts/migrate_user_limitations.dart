#!/usr/bin/env dart

/// Migration script to add reminder limitation fields to existing UserLimitations documents
/// 
/// This script provides instructions for migrating userLimitations documents in Firestore
/// to include the new maxReminders and currentReminders fields.
/// 
/// **IMPORTANT**: This script should be run ONCE after deploying the reminders feature.

import 'dart:io';

void main() async {
  print('=== UserLimitations Migration Guide ===');
  print('Adding maxReminders and currentReminders fields\n');

  print('⚠️  IMPORTANT: This script provides migration instructions.');
  print('The actual migration should be done using Firebase Console or Firebase Admin SDK.\n');

  print('📝 Migration Instructions:\n');
  print('Option 1: Use Firebase Console (Recommended for small datasets)');
  print('  1. Go to https://console.firebase.google.com/');
  print('  2. Select your project');
  print('  3. Navigate to Firestore Database');
  print('  4. Find the "userLimitations" collection');
  print('  5. For each document:');
  print('     - Click on the document');
  print('     - Add field "maxReminders" with value:');
  print('       * 30 for free users (where maxActiveTasks != -1)');
  print('       * -1 for premium users (where maxActiveTasks == -1)');
  print('     - Add field "currentReminders" with value: 0');
  print('     - Update "updatedAt" field with current timestamp');
  print('');
  print('Option 2: Use Firebase Admin SDK (Recommended for large datasets)');
  print('  See the example Node.js script below\n');

  print('Example Node.js migration script:\n');
  print('''
// migrate.js
const admin = require('firebase-admin');
const serviceAccount = require('./path/to/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migrate() {
  const snapshot = await db.collection('userLimitations').get();
  
  console.log(`Found \${snapshot.size} documents`);
  
  const batch = db.batch();
  let count = 0;
  
  snapshot.forEach(doc => {
    const data = doc.data();
    
    // Skip if already migrated
    if (data.maxReminders !== undefined) {
      console.log(`Skipping \${doc.id} - already migrated`);
      return;
    }
    
    const isPremium = data.maxActiveTasks === -1;
    const maxReminders = isPremium ? -1 : 30;
    
    batch.update(doc.ref, {
      maxReminders: maxReminders,
      currentReminders: 0,
      updatedAt: new Date().toISOString()
    });
    
    count++;
    console.log(`Queued \${doc.id} - \${isPremium ? 'Premium' : 'Free'} user`);
  });
  
  if (count > 0) {
    await batch.commit();
    console.log(`\\n✓ Successfully migrated \${count} documents`);
  } else {
    console.log('\\nNo documents to migrate');
  }
}

migrate().catch(console.error);
''');

  print('\nTo run the Node.js script:');
  print('  1. Save the script as migrate.js');
  print('  2. Install dependencies: npm install firebase-admin');
  print('  3. Download service account key from Firebase Console');
  print('  4. Run: node migrate.js\n');

  print('For detailed instructions, see: scripts/MIGRATION_GUIDE.md\n');
  print('✓ Migration instructions displayed');
}
