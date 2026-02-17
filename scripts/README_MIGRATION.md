# UserLimitations Migration - Documentation Index

This directory contains all documentation and scripts needed to migrate existing UserLimitations documents to support the reminders system.

## 📚 Documentation Overview

### For Quick Reference
- **[MIGRATION_QUICK_REFERENCE.md](MIGRATION_QUICK_REFERENCE.md)** - Quick start guide for experienced users (5 min read)

### For Detailed Instructions
- **[MIGRATION_EXECUTION_GUIDE.md](MIGRATION_EXECUTION_GUIDE.md)** - Comprehensive step-by-step execution guide (15 min read)
- **[MIGRATION_VERIFICATION_GUIDE.md](MIGRATION_VERIFICATION_GUIDE.md)** - Detailed verification procedures (20 min read)
- **[MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)** - General overview and setup information (10 min read)

### For Project Documentation
- **[../.kiro/specs/reminders-system/task-8.3.4-8.3.5-completion-summary.md](../.kiro/specs/reminders-system/task-8.3.4-8.3.5-completion-summary.md)** - Task completion summary

## 🚀 Quick Start

### I'm New to This
1. Read [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) for overview
2. Follow [MIGRATION_EXECUTION_GUIDE.md](MIGRATION_EXECUTION_GUIDE.md) step-by-step
3. Use [MIGRATION_VERIFICATION_GUIDE.md](MIGRATION_VERIFICATION_GUIDE.md) to verify

### I'm Experienced
1. Check [MIGRATION_QUICK_REFERENCE.md](MIGRATION_QUICK_REFERENCE.md)
2. Run the commands
3. Verify using Level 1 checks

## 📋 Migration Checklist

### Before Migration
- [ ] Read appropriate documentation
- [ ] Reminders feature code deployed
- [ ] Firestore indexes deployed and built
- [ ] Firestore security rules deployed
- [ ] **Create Firestore backup** (CRITICAL!)
- [ ] Download service account key
- [ ] Install dependencies: `npm install firebase-admin`

### During Migration
- [ ] Run dry-run mode first
- [ ] Review dry-run output
- [ ] Execute production migration
- [ ] Monitor migration output
- [ ] Verify no errors

### After Migration
- [ ] Perform Level 1 verification (required)
- [ ] Perform Level 2 verification (recommended)
- [ ] Secure/delete service account key
- [ ] Reset DRY_RUN flag to true
- [ ] Monitor for 24-48 hours
- [ ] Mark tasks 8.3.4 and 8.3.5 complete

## 📁 Files in This Directory

### Migration Scripts
- **migrate_user_limitations.js** - Node.js migration script (primary)
- **migrate_user_limitations.dart** - Dart informational script

### Documentation
- **MIGRATION_QUICK_REFERENCE.md** - Quick reference guide
- **MIGRATION_EXECUTION_GUIDE.md** - Detailed execution instructions
- **MIGRATION_VERIFICATION_GUIDE.md** - Comprehensive verification procedures
- **MIGRATION_GUIDE.md** - General overview and setup
- **README_MIGRATION.md** - This file (documentation index)

## 🎯 What This Migration Does

Adds reminder limitation fields to existing `userLimitations` documents:

| User Type | maxReminders | currentReminders |
|-----------|--------------|------------------|
| Free      | 30           | 0                |
| Premium   | -1 (unlimited) | 0              |

**User Type Detection**: Based on `maxActiveTasks` field
- Premium: `maxActiveTasks == -1`
- Free: `maxActiveTasks != -1`

## ⚠️ Critical Safety Information

### Always Create a Backup First!

```bash
# Using gcloud CLI
gcloud firestore export gs://[YOUR_BUCKET]/backups/$(date +%Y%m%d_%H%M%S) \
  --collection-ids=userLimitations

# Or use Firebase Console: Firestore → Import/Export → Export
```

### Migration is Idempotent

- ✅ Safe to run multiple times
- ✅ Skips already migrated documents
- ✅ Can be re-run if errors occur

### Rollback Available

If needed, restore from backup:

```bash
gcloud firestore import gs://[YOUR_BUCKET]/backups/[BACKUP_TIMESTAMP]
```

## 🔍 Verification Levels

### Level 1: Quick Checks (5 minutes) - **REQUIRED**
- Check migration output
- Spot check Firestore documents
- Quick application test

### Level 2: Thorough Testing (15 minutes) - **RECOMMENDED**
- Data integrity verification
- Application functionality testing
- Limitation enforcement testing
- Integration testing

### Level 3: Comprehensive Audit (30+ minutes) - **OPTIONAL**
- Full database audit
- Performance testing
- Security rules verification

## 🆘 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Service account key not found | Download from Firebase Console → Project Settings → Service Accounts |
| Cannot find module 'firebase-admin' | Run `npm install firebase-admin` |
| Permission denied | Verify service account has "Cloud Datastore User" role |
| Counter mismatch | Run counter fix script (see verification guide) |
| Some documents failed | Re-run script (it will skip successful ones) |

### Getting Help

1. Check the troubleshooting section in the relevant guide
2. Review Firebase Console for document state
3. Check application logs for errors
4. Consult task completion summary for context

## 📊 Migration Flow

```
1. Pre-Migration
   ├── Read documentation
   ├── Verify prerequisites
   ├── Create backup (CRITICAL!)
   └── Download service account key

2. Dry Run
   ├── Ensure DRY_RUN = true
   ├── Run script
   ├── Review output
   └── Verify no errors

3. Production Migration
   ├── Change DRY_RUN = false
   ├── Run script
   ├── Confirm execution
   └── Monitor output

4. Verification
   ├── Level 1: Quick checks (required)
   ├── Level 2: Thorough testing (recommended)
   └── Level 3: Comprehensive audit (optional)

5. Post-Migration
   ├── Secure service account key
   ├── Reset DRY_RUN flag
   ├── Monitor for 24-48 hours
   └── Mark tasks complete
```

## 🔗 Related Resources

### Spec Files
- `.kiro/specs/reminders-system/requirements.md` - Requirements document
- `.kiro/specs/reminders-system/design.md` - Design document
- `.kiro/specs/reminders-system/tasks.md` - Task list
- `.kiro/specs/reminders-system/task-8.3-completion-summary.md` - Task 8.3 overview
- `.kiro/specs/reminders-system/task-8.3.4-8.3.5-completion-summary.md` - Tasks 8.3.4 & 8.3.5 summary

### Firebase Resources
- [Firebase Console](https://console.firebase.google.com/)
- [Firestore Documentation](https://firebase.google.com/docs/firestore)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)

## 📝 Task Information

- **Task 8.3.4**: Run migration script on production database
- **Task 8.3.5**: Verify migration success
- **Phase**: 8 - Firebase Configuration
- **Status**: Documentation Complete - Ready for User Execution

## ✅ Success Criteria

Migration is successful when:

1. ✅ Migration script completes with "Errors: 0"
2. ✅ All documents have `maxReminders` and `currentReminders` fields
3. ✅ Values are correct for user types
4. ✅ Level 1 verification passes
5. ✅ Application functions correctly
6. ✅ Limitation enforcement works
7. ✅ No errors in application logs
8. ✅ Monitoring shows no issues

## 🎓 Best Practices

1. **Always read documentation first** - Don't skip the guides
2. **Always create a backup** - This is non-negotiable
3. **Always run dry-run first** - Preview changes before applying
4. **Always verify thoroughly** - At least Level 1, preferably Level 2
5. **Always monitor after migration** - Watch for 24-48 hours
6. **Always secure credentials** - Delete or secure service account key

## 📞 Support

If you encounter issues:

1. Check the troubleshooting section in the relevant guide
2. Review the comprehensive guides for detailed solutions
3. Check Firebase Console for document state
4. Review application logs for errors
5. Consult the task completion summary for context

---

**Last Updated**: 2026-02-09  
**Version**: 1.0  
**Related Tasks**: 8.3.4, 8.3.5  
**Spec Location**: `.kiro/specs/reminders-system/`
