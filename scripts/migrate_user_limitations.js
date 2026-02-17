#!/usr/bin/env node

/**
 * Migration script to add reminder limitation fields to existing UserLimitations documents
 * 
 * This script updates all existing userLimitations documents in Firestore to include
 * the new maxReminders and currentReminders fields required for the reminders system.
 * 
 * IMPORTANT: This script should be run ONCE after deploying the reminders feature.
 * 
 * How to Run:
 * 
 * 1. Install dependencies:
 *    npm install firebase-admin
 * 
 * 2. Download service account key from Firebase Console:
 *    - Go to Project Settings → Service Accounts
 *    - Click "Generate New Private Key"
 *    - Save as serviceAccountKey.json in the scripts folder
 * 
 * 3. Run the script:
 *    node scripts/migrate_user_limitations.js
 * 
 * 4. Review the output to verify the migration was successful
 */

const admin = require('firebase-admin');
const readline = require('readline');

// Configuration
const DRY_RUN = true; // Set to false to apply changes
const SERVICE_ACCOUNT_PATH = './scripts/serviceAccountKey.json';

// Initialize Firebase Admin
let serviceAccount;
try {
  serviceAccount = require(SERVICE_ACCOUNT_PATH);
} catch (error) {
  console.error('✗ Error: Service account key not found');
  console.error(`  Please download it from Firebase Console and save as: ${SERVICE_ACCOUNT_PATH}`);
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function askConfirmation(question) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      rl.close();
      resolve(answer.toLowerCase() === 'y' || answer.toLowerCase() === 'yes' || answer === '');
    });
  });
}

async function migrate() {
  console.log('=== UserLimitations Migration Script ===');
  console.log('Adding maxReminders and currentReminders fields\n');

  if (DRY_RUN) {
    console.log('⚠️  DRY RUN MODE - No changes will be applied\n');
  }

  try {
    // Fetch all userLimitations documents
    console.log('Fetching userLimitations documents...');
    const snapshot = await db.collection('userLimitations').get();
    console.log(`✓ Found ${snapshot.size} documents\n`);

    if (snapshot.empty) {
      console.log('No documents to migrate. Exiting.');
      process.exit(0);
    }

    // Analyze documents
    let needsMigration = 0;
    let alreadyMigrated = 0;
    let freeUsers = 0;
    let premiumUsers = 0;

    snapshot.forEach(doc => {
      const data = doc.data();
      
      // Check if already migrated
      if (data.maxReminders !== undefined && data.currentReminders !== undefined) {
        alreadyMigrated++;
      } else {
        needsMigration++;
        
        // Determine user type
        const maxActiveTasks = data.maxActiveTasks;
        if (maxActiveTasks === -1) {
          premiumUsers++;
        } else {
          freeUsers++;
        }
      }
    });

    console.log('Migration Analysis:');
    console.log(`  - Already migrated: ${alreadyMigrated}`);
    console.log(`  - Needs migration: ${needsMigration}`);
    console.log(`    - Free users: ${freeUsers}`);
    console.log(`    - Premium users: ${premiumUsers}`);
    console.log('');

    if (needsMigration === 0) {
      console.log('All documents already migrated. Nothing to do.');
      process.exit(0);
    }

    // Confirm migration
    if (!DRY_RUN) {
      console.log(`⚠️  This will update ${needsMigration} documents in Firestore.`);
      const confirmed = await askConfirmation('Press Enter to continue or Ctrl+C to cancel...');
      if (!confirmed) {
        console.log('Migration cancelled.');
        process.exit(0);
      }
      console.log('');
    }

    // Perform migration
    console.log('Starting migration...\n');
    
    const batch = db.batch();
    let processed = 0;
    let updated = 0;
    let skipped = 0;
    let errors = 0;

    snapshot.forEach(doc => {
      try {
        const data = doc.data();
        
        // Skip if already migrated
        if (data.maxReminders !== undefined && data.currentReminders !== undefined) {
          skipped++;
          processed++;
          return;
        }

        // Determine user type and set appropriate values
        const maxActiveTasks = data.maxActiveTasks ?? 50;
        const isPremium = maxActiveTasks === -1;
        
        const maxReminders = isPremium ? -1 : 30;
        const currentReminders = 0;

        console.log(`Migrating user ${doc.id}:`);
        console.log(`  Type: ${isPremium ? "Premium" : "Free"}`);
        console.log(`  maxReminders: ${maxReminders}`);
        console.log(`  currentReminders: ${currentReminders}`);

        if (!DRY_RUN) {
          batch.update(doc.ref, {
            maxReminders: maxReminders,
            currentReminders: currentReminders,
            updatedAt: new Date().toISOString()
          });
          updated++;
        }

        processed++;
        
      } catch (e) {
        console.log(`  ✗ Error migrating ${doc.id}: ${e.message}`);
        errors++;
        processed++;
      }
    });

    // Commit batch
    if (!DRY_RUN && updated > 0) {
      await batch.commit();
      console.log(`\n✓ Batch committed (${updated} operations)\n`);
    }

    // Print summary
    console.log('\n=== Migration Summary ===');
    console.log(`Total documents: ${snapshot.size}`);
    console.log(`Processed: ${processed}`);
    console.log(`Updated: ${updated}`);
    console.log(`Skipped (already migrated): ${skipped}`);
    console.log(`Errors: ${errors}`);
    
    if (DRY_RUN) {
      console.log('\n⚠️  DRY RUN - No changes were applied');
      console.log('Set DRY_RUN = false in the script to apply changes');
    } else {
      console.log('\n✓ Migration completed successfully!');
    }

  } catch (e) {
    console.error('\n✗ Migration failed with error:');
    console.error(e);
    process.exit(1);
  }
}

// Run migration
migrate()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('Fatal error:', error);
    process.exit(1);
  });
