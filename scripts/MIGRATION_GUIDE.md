# UserLimitations Migration Guide

This guide explains how to migrate existing UserLimitations documents to include the new reminder limitation fields (`maxReminders` and `currentReminders`).

## Overview

The reminders system requires two new fields in the `userLimitations` collection:
- `maxReminders`: Maximum number of reminders allowed (30 for free users, -1 for premium)
- `currentReminders`: Current number of reminders created (starts at 0)

## Prerequisites

Before running the migration, ensure you have:

1. **Firebase Service Account Key**
   - Download the service account key JSON file from [Firebase Console](https://console.firebase.google.com/)
   - Go to Project Settings → Service Accounts → Generate New Private Key
   - Save the JSON file as `scripts/serviceAccountKey.json`
   - **DO NOT commit this file to version control** (it's already in .gitignore)

2. **Node.js and npm installed**
   - Check with: `node --version` and `npm --version`
   - If not installed, download from [nodejs.org](https://nodejs.org/)

3. **Firebase Admin SDK**
   - Install with: `npm install firebase-admin`

## Migration Steps

### Step 1: Dry Run (Recommended)

First, run the script in dry-run mode to preview the changes without applying them:

1. Ensure `DRY_RUN = true` in `scripts/migrate_user_limitations.js` (this is the default)
2. Run the script:
   ```bash
   node scripts/migrate_user_limitations.js
   ```

3. Review the output to verify:
   - Number of documents to be migrated
   - Free vs premium user counts
   - No unexpected errors

### Step 2: Backup (Highly Recommended)

Before running the actual migration, create a backup of your Firestore database:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Navigate to Firestore Database
3. Click on "Import/Export" tab
4. Export the `userLimitations` collection
5. Save the export location for potential rollback

### Step 3: Run Migration

Once you've verified the dry run and created a backup:

1. Open `scripts/migrate_user_limitations.js`
2. Change `DRY_RUN = false`
3. Run the script:
   ```bash
   node scripts/migrate_user_limitations.js
   ```

4. When prompted, press Enter to confirm the migration
5. Wait for the script to complete
6. Review the summary output

### Step 4: Verify Migration

After the migration completes, verify the results:

1. Check the Firestore Console to ensure documents have the new fields
2. Verify a few sample documents:
   - Free users should have `maxReminders: 30, currentReminders: 0`
   - Premium users should have `maxReminders: -1, currentReminders: 0`
3. Test the reminders feature in the app to ensure it works correctly

## Alternative: Manual Migration via Firebase Console

For small datasets (< 10 users), you can migrate manually:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Navigate to Firestore Database → userLimitations collection
3. For each document:
   - Click on the document
   - Add field `maxReminders`:
     - Value: `30` for free users (where `maxActiveTasks != -1`)
     - Value: `-1` for premium users (where `maxActiveTasks == -1`)
   - Add field `currentReminders`: Value: `0`
   - Update `updatedAt` field with current timestamp
4. Save the document

## Migration Script Details

### What the Script Does

1. Connects to Firestore using Firebase Admin SDK
2. Fetches all documents from the `userLimitations` collection
3. For each document:
   - Checks if it already has the reminder fields (skips if yes)
   - Determines user type based on `maxActiveTasks` field:
     - Premium: `maxActiveTasks == -1`
     - Free: `maxActiveTasks != -1`
   - Adds appropriate values:
     - Free users: `maxReminders: 30, currentReminders: 0`
     - Premium users: `maxReminders: -1, currentReminders: 0`
   - Updates the `updatedAt` timestamp
4. Uses batch writes for efficiency
5. Provides detailed logging and error handling

### Safety Features

- **Dry-run mode**: Preview changes without applying them
- **Idempotent**: Safe to run multiple times (skips already migrated documents)
- **Batch writes**: Efficient and atomic operations
- **Error handling**: Continues processing even if individual documents fail
- **Detailed logging**: Audit trail of all operations

## Troubleshooting

### Error: "Service account key not found"

**Solution**: Download the service account key from Firebase Console and save it as `scripts/serviceAccountKey.json`

### Error: "Cannot find module 'firebase-admin'"

**Solution**: Install the Firebase Admin SDK:
```bash
npm install firebase-admin
```

### Error: "Permission denied"

**Solution**: Verify that the service account has the necessary permissions:
- Cloud Datastore User role
- Or Firebase Admin SDK Administrator Service Agent role

### Some documents failed to migrate

**Solution**: 
1. Check the error messages in the script output
2. Verify the document structure in Firestore
3. Manually update failed documents if necessary
4. Re-run the script (it will skip already migrated documents)

## Rollback

If you need to rollback the migration:

### Option 1: Restore from Backup

1. Go to Firebase Console → Firestore Database → Import/Export
2. Import the backup you created before migration
3. This will restore the collection to its pre-migration state

### Option 2: Manual Removal

If you only need to remove the new fields:

1. Use Firebase Console to manually remove `maxReminders` and `currentReminders` fields
2. Or create a reverse migration script

## Post-Migration

After successful migration:

1. ✅ Deploy the updated Firestore security rules (if not already done)
2. ✅ Deploy the updated Firestore indexes (if not already done)
3. ✅ Test the reminders feature thoroughly
4. ✅ Monitor error logs for any issues
5. ✅ Update the `DRY_RUN` flag back to `true` to prevent accidental re-runs
6. ✅ **Delete or secure the service account key file**

## Security Notes

- **DO NOT** commit the service account key file to version control
- **DO** delete the key file after migration or store it securely
- **DO** create a backup before running the migration
- **DO** run in dry-run mode first to preview changes
- The script is idempotent and safe to run multiple times
- Existing documents with the fields will be skipped automatically

## Support

If you encounter any issues during migration:

1. Check the script output for detailed error messages
2. Review the Firestore Console for document structure
3. Verify Firebase Admin SDK credentials and permissions
4. Check the application logs for any related errors

For detailed technical information, see `.kiro/specs/reminders-system/task-8.3-completion-summary.md`
