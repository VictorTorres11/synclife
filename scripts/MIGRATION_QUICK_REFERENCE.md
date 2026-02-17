# UserLimitations Migration - Quick Reference

Quick reference for migrating existing UserLimitations documents to include reminder limitation fields.

## 📋 Pre-Migration Checklist

- [ ] Reminders feature code deployed to production
- [ ] Firestore indexes deployed and built (Task 8.2.3)
- [ ] Firestore security rules deployed (Task 8.1.7)
- [ ] Firebase service account key downloaded
- [ ] Node.js and npm installed
- [ ] Firebase Admin SDK installed: `npm install firebase-admin`
- [ ] **Firestore backup created** (CRITICAL!)

## 🚀 Quick Start

### 1. Create Backup (REQUIRED)

```bash
# Using Firebase Console: Firestore → Import/Export → Export
# Or using gcloud CLI:
gcloud firestore export gs://[YOUR_BUCKET]/backups/$(date +%Y%m%d_%H%M%S) \
  --collection-ids=userLimitations
```

### 2. Dry Run (Test Mode)

```bash
# Ensure DRY_RUN = true in the script (default)
node scripts/migrate_user_limitations.js
```

Review the output to verify everything looks correct.

### 3. Production Run

```bash
# 1. Change DRY_RUN = false in scripts/migrate_user_limitations.js
# 2. Run the script:
node scripts/migrate_user_limitations.js

# 3. Press Enter when prompted to confirm
```

## 📊 What Gets Added

For each `userLimitations` document:

- **Free Users** (where `maxActiveTasks != -1`):
  - `maxReminders: 30`
  - `currentReminders: 0`

- **Premium Users** (where `maxActiveTasks == -1`):
  - `maxReminders: -1` (unlimited)
  - `currentReminders: 0`

## ✅ Quick Verification

### Level 1: Essential Checks (5 minutes)

1. **Check Migration Output**:
   ```
   ✓ Migration completed successfully!
   Errors: 0
   ```

2. **Spot Check Firestore**:
   - Open 3-5 random documents in `userLimitations` collection
   - Verify `maxReminders` and `currentReminders` fields exist
   - Verify values are correct for user type

3. **Test in App**:
   - Navigate to Reminders page
   - Create a reminder
   - Verify usage indicator shows "1/30 reminders used"
   - Delete the reminder
   - Verify usage indicator shows "0/30 reminders used"

### Level 2: Thorough Testing (15 minutes)

4. **Test Free User Limits**:
   - Create 30 reminders
   - Verify 31st reminder is blocked
   - Verify upgrade prompt shown

5. **Test Premium User**:
   - Create 35+ reminders
   - Verify no limits enforced

6. **Test Integration**:
   - Convert reminder to task
   - Verify counter decrements
   - Verify task created correctly

## 🛡️ Safety Features

- ✅ **Idempotent**: Safe to run multiple times (skips already migrated documents)
- ✅ **Dry-run mode**: Preview changes before applying
- ✅ **Batch operations**: Efficient and atomic
- ✅ **Error handling**: Continues even if individual documents fail
- ✅ **Detailed logging**: Audit trail of all operations

## 🔧 Troubleshooting

### Service account key not found
```bash
# Download from Firebase Console → Project Settings → Service Accounts
# Save as: scripts/serviceAccountKey.json
```

### Cannot find module 'firebase-admin'
```bash
npm install firebase-admin
```

### Permission denied
- Verify service account has "Cloud Datastore User" role
- Check Firebase project ID matches

### Counter mismatch after migration
```javascript
// Fix counter for a specific user
const userId = 'USER_ID';
const reminders = await db.collection('reminders')
  .where('userId', '==', userId)
  .get();
await db.collection('userLimitations').doc(userId).update({
  currentReminders: reminders.size,
  updatedAt: new Date().toIso8601String()
});
```

## 🔄 Rollback

If needed, restore from Firestore backup:

```bash
# Using gcloud CLI
gcloud firestore import gs://[YOUR_BUCKET]/backups/[BACKUP_TIMESTAMP]
```

**WARNING**: This restores the ENTIRE database to backup state.

## 📚 Full Documentation

For detailed instructions, see:
- **Execution**: `scripts/MIGRATION_EXECUTION_GUIDE.md` (comprehensive step-by-step)
- **Verification**: `scripts/MIGRATION_VERIFICATION_GUIDE.md` (detailed testing)
- **Overview**: `scripts/MIGRATION_GUIDE.md` (general information)

## 📝 Post-Migration Checklist

- [ ] Migration completed successfully (Errors: 0)
- [ ] Spot checks in Firestore passed
- [ ] Application test passed (create/delete reminder)
- [ ] Free user limitation test passed
- [ ] Premium user test passed
- [ ] Service account key deleted or secured
- [ ] DRY_RUN flag reset to true
- [ ] Team notified of completion
- [ ] Monitoring in place for 24-48 hours

## 🎯 Next Steps

After successful migration and verification:

1. ✅ Mark Task 8.3.4 as complete (Run migration script)
2. ✅ Mark Task 8.3.5 as complete (Verify migration success)
3. ✅ Continue with remaining deployment tasks
4. ✅ Monitor application for 24-48 hours

## 📞 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review detailed guides in `scripts/MIGRATION_EXECUTION_GUIDE.md`
3. Check Firebase Console for document state
4. Review application logs for errors
5. Consult `.kiro/specs/reminders-system/task-8.3-completion-summary.md`

---

**Quick Tip**: Always run dry-run first, create a backup, and verify thoroughly before marking tasks complete!
