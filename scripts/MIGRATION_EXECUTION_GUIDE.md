# Migration Execution Guide - Production Database

This guide provides step-by-step instructions for executing the UserLimitations migration on your production Firebase database.

## ⚠️ CRITICAL: Pre-Migration Checklist

Before running the migration, ensure ALL of the following are complete:

- [ ] **Code Deployment**: The reminders feature code has been deployed to production
- [ ] **Firestore Indexes**: Composite indexes have been deployed and built (Task 8.2.3)
- [ ] **Security Rules**: Updated Firestore rules have been deployed (Task 8.1.7)
- [ ] **Backup Created**: Full Firestore backup has been exported (see below)
- [ ] **Service Account Key**: Downloaded from Firebase Console
- [ ] **Dependencies Installed**: `npm install firebase-admin` completed
- [ ] **Dry Run Completed**: Migration script tested in dry-run mode
- [ ] **Team Notified**: Relevant team members aware of migration timing

## Step 1: Create Firestore Backup

**CRITICAL**: Always create a backup before running any migration.

### Option A: Using Firebase Console (Recommended)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Firestore Database**
4. Click on the **"Import/Export"** tab
5. Click **"Export"**
6. Select the `userLimitations` collection
7. Choose a Cloud Storage bucket location
8. Click **"Export"**
9. **Save the export location** - you'll need this for rollback if necessary
10. Wait for export to complete (check Cloud Storage)

### Option B: Using gcloud CLI

```bash
# Export entire database
gcloud firestore export gs://[YOUR_BUCKET]/backups/$(date +%Y%m%d_%H%M%S)

# Or export specific collection
gcloud firestore export gs://[YOUR_BUCKET]/backups/$(date +%Y%m%d_%H%M%S) \
  --collection-ids=userLimitations
```

**Verify Backup**: Check Cloud Storage to confirm the backup files exist before proceeding.

## Step 2: Download Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click the gear icon → **Project Settings**
4. Navigate to **Service Accounts** tab
5. Click **"Generate New Private Key"**
6. Click **"Generate Key"** in the confirmation dialog
7. Save the JSON file as `scripts/serviceAccountKey.json`
8. **IMPORTANT**: Do NOT commit this file to version control

### Verify Service Account Permissions

The service account should have:
- **Cloud Datastore User** role, OR
- **Firebase Admin SDK Administrator Service Agent** role

To check/add permissions:
1. Go to [IAM & Admin Console](https://console.cloud.google.com/iam-admin/iam)
2. Find the service account email (format: `firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com`)
3. Verify it has the necessary roles
4. If not, click **"Edit"** and add the required role

## Step 3: Install Dependencies

```bash
# Navigate to your project root
cd /path/to/your/project

# Install Firebase Admin SDK
npm install firebase-admin

# Verify installation
npm list firebase-admin
```

Expected output: `firebase-admin@X.X.X`

## Step 4: Run Dry Run (Test Mode)

**IMPORTANT**: Always run in dry-run mode first to preview changes.

1. Open `scripts/migrate_user_limitations.js`
2. Verify `DRY_RUN = true` (this is the default)
3. Run the script:

```bash
node scripts/migrate_user_limitations.js
```

### Expected Dry Run Output

```
=== UserLimitations Migration Script ===
Adding maxReminders and currentReminders fields

⚠️  DRY RUN MODE - No changes will be applied

Fetching userLimitations documents...
✓ Found 150 documents

Migration Analysis:
  - Already migrated: 0
  - Needs migration: 150
    - Free users: 120
    - Premium users: 30

Starting migration...

Migrating user abc123:
  Type: Free
  maxReminders: 30
  currentReminders: 0

Migrating user def456:
  Type: Premium
  maxReminders: -1
  currentReminders: 0

[... more users ...]

=== Migration Summary ===
Total documents: 150
Processed: 150
Updated: 150
Skipped (already migrated): 0
Errors: 0

⚠️  DRY RUN - No changes were applied
Set DRY_RUN = false in the script to apply changes
```

### Review Dry Run Results

Check for:
- ✅ Correct number of documents found
- ✅ Reasonable free vs premium user split
- ✅ No errors in the output
- ✅ User IDs look correct
- ❌ Any unexpected warnings or errors

**If you see errors**: Do NOT proceed. Investigate and fix issues first.

## Step 5: Schedule Migration Window

**Recommended Approach**: Schedule during low-traffic period

1. **Identify Low-Traffic Window**: Check your analytics for the quietest time
2. **Estimate Duration**: ~1-2 seconds per 100 documents
3. **Notify Users** (optional): If you have a status page, post a maintenance notice
4. **Prepare Rollback Plan**: Have the backup location ready

### Migration Impact

- **Downtime**: None (migration is non-blocking)
- **User Impact**: Minimal (existing features continue working)
- **Duration**: Typically < 1 minute for most databases
- **Reversibility**: Yes (via backup restore)

## Step 6: Execute Production Migration

**⚠️ POINT OF NO RETURN**: This step modifies your production database.

1. **Final Verification**:
   ```bash
   # Verify you're in the correct project
   cat scripts/serviceAccountKey.json | grep project_id
   ```
   
2. **Enable Production Mode**:
   - Open `scripts/migrate_user_limitations.js`
   - Change `DRY_RUN = true` to `DRY_RUN = false`
   - Save the file

3. **Run Migration**:
   ```bash
   node scripts/migrate_user_limitations.js
   ```

4. **Confirm Execution**:
   - The script will display the migration analysis
   - Press **Enter** to confirm and proceed
   - Or press **Ctrl+C** to cancel

### Expected Production Output

```
=== UserLimitations Migration Script ===
Adding maxReminders and currentReminders fields

Fetching userLimitations documents...
✓ Found 150 documents

Migration Analysis:
  - Already migrated: 0
  - Needs migration: 150
    - Free users: 120
    - Premium users: 30

⚠️  This will update 150 documents in Firestore.
Press Enter to continue or Ctrl+C to cancel...

Starting migration...

Migrating user abc123:
  Type: Free
  maxReminders: 30
  currentReminders: 0

[... more users ...]

✓ Batch committed (150 operations)

=== Migration Summary ===
Total documents: 150
Processed: 150
Updated: 150
Skipped (already migrated): 0
Errors: 0

✓ Migration completed successfully!
```

### If Errors Occur During Migration

The script is designed to continue processing even if individual documents fail:

1. **Review Error Messages**: Check which documents failed and why
2. **Check Firestore Console**: Verify the state of failed documents
3. **Re-run Script**: The script is idempotent - it will skip already migrated documents
4. **Manual Fix**: If needed, manually update failed documents via Firebase Console

## Step 7: Immediate Verification

Perform these checks immediately after migration:

### 7.1 Check Migration Summary

Verify the output shows:
- ✅ `Errors: 0`
- ✅ `Updated: [expected number]`
- ✅ `✓ Migration completed successfully!`

### 7.2 Spot Check in Firestore Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Navigate to **Firestore Database** → `userLimitations` collection
3. Open 3-5 random documents
4. Verify each has:
   - ✅ `maxReminders` field (30 for free, -1 for premium)
   - ✅ `currentReminders` field (0)
   - ✅ `updatedAt` field (recent timestamp)

### 7.3 Check Application Logs

Monitor your application logs for any errors related to:
- UserLimitations deserialization
- Reminder creation
- Limitation checks

```bash
# If using Firebase Functions
firebase functions:log --only reminders

# If using Cloud Logging
gcloud logging read "resource.type=cloud_function" --limit 50
```

## Step 8: Post-Migration Cleanup

After successful migration:

1. **Reset Dry Run Flag**:
   - Open `scripts/migrate_user_limitations.js`
   - Change `DRY_RUN = false` back to `DRY_RUN = true`
   - Save and commit this change

2. **Secure Service Account Key**:
   ```bash
   # Delete the key file
   rm scripts/serviceAccountKey.json
   
   # Or move to secure location
   mv scripts/serviceAccountKey.json ~/secure-keys/
   ```

3. **Document Migration**:
   - Record migration date and time
   - Note any issues encountered
   - Update team documentation

4. **Monitor Application**:
   - Watch error rates for 24-48 hours
   - Check user reports for any issues
   - Verify reminder creation works correctly

## Rollback Procedure

If you need to rollback the migration:

### Option A: Restore from Backup (Complete Rollback)

```bash
# Using gcloud CLI
gcloud firestore import gs://[YOUR_BUCKET]/backups/[BACKUP_TIMESTAMP]
```

**WARNING**: This will restore the ENTIRE database to the backup state, losing any changes made after the backup.

### Option B: Remove Fields (Partial Rollback)

If you only need to remove the new fields:

1. Create a reverse migration script:

```javascript
// rollback.js
const admin = require('firebase-admin');
const serviceAccount = require('./scripts/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function rollback() {
  const snapshot = await db.collection('userLimitations').get();
  const batch = db.batch();
  
  snapshot.forEach(doc => {
    batch.update(doc.ref, {
      maxReminders: admin.firestore.FieldValue.delete(),
      currentReminders: admin.firestore.FieldValue.delete(),
      updatedAt: new Date().toIso8601String()
    });
  });
  
  await batch.commit();
  console.log('Rollback completed');
}

rollback().catch(console.error);
```

2. Run the rollback script:
```bash
node rollback.js
```

## Troubleshooting

### Error: "Service account key not found"

**Solution**: 
- Verify the file exists at `scripts/serviceAccountKey.json`
- Check the file path in the script matches your location
- Ensure the file is valid JSON

### Error: "Cannot find module 'firebase-admin'"

**Solution**:
```bash
npm install firebase-admin
```

### Error: "Permission denied"

**Solution**:
- Verify service account has correct IAM roles
- Check Firebase project ID matches
- Ensure service account is enabled

### Error: "DEADLINE_EXCEEDED" or Timeout

**Solution**:
- Large databases may timeout
- Split migration into batches
- Increase timeout in script
- Run during low-traffic period

### Some Documents Failed to Migrate

**Solution**:
1. Review error messages for specific documents
2. Check document structure in Firestore Console
3. Manually fix problematic documents
4. Re-run script (it will skip already migrated documents)

## Migration Checklist

Use this checklist to track your progress:

- [ ] Pre-migration checklist completed
- [ ] Firestore backup created and verified
- [ ] Service account key downloaded
- [ ] Dependencies installed
- [ ] Dry run completed successfully
- [ ] Migration window scheduled
- [ ] Production migration executed
- [ ] Migration summary shows success
- [ ] Spot checks in Firestore passed
- [ ] Application logs show no errors
- [ ] Post-migration cleanup completed
- [ ] Team notified of completion
- [ ] Monitoring in place for 24-48 hours

## Next Steps

After successful migration:

1. ✅ Mark Task 8.3.4 as complete
2. ✅ Proceed to Task 8.3.5: Verify migration success (see MIGRATION_VERIFICATION_GUIDE.md)
3. ✅ Continue with remaining deployment tasks

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review Firebase Console for document state
3. Check application logs for errors
4. Consult the main MIGRATION_GUIDE.md for additional context
5. Review the task completion summary: `.kiro/specs/reminders-system/task-8.3-completion-summary.md`

---

**Document Version**: 1.0  
**Last Updated**: 2026-02-09  
**Related Tasks**: 8.3.4, 8.3.5  
**Related Files**: 
- `scripts/migrate_user_limitations.js`
- `scripts/MIGRATION_GUIDE.md`
- `scripts/MIGRATION_VERIFICATION_GUIDE.md`
