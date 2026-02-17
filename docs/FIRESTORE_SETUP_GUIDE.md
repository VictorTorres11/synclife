# Firestore Setup Guide for SyncLife

This guide provides comprehensive instructions for setting up Firebase Firestore for the SyncLife application, including the reminders system.

## Table of Contents

1. [Overview](#overview)
2. [Collections Structure](#collections-structure)
3. [Reminders Collection Setup](#reminders-collection-setup)
4. [Security Rules](#security-rules)
5. [Indexes Configuration](#indexes-configuration)
6. [Migration Guide](#migration-guide)
7. [Testing and Verification](#testing-and-verification)

## Overview

SyncLife uses Firebase Firestore as its primary database for real-time synchronization across devices. The database follows a multi-tenant architecture where users can only access their own data and data from boards they are members of.

### Key Features

- **Real-time synchronization**: Changes propagate instantly across all devices
- **Offline support**: Firestore SDK provides automatic offline caching
- **Security**: Row-level security rules ensure data isolation
- **Scalability**: Composite indexes optimize query performance

## Collections Structure

### Core Collections

| Collection | Purpose | Access Control |
|------------|---------|----------------|
| `users` | User account information | User owns document |
| `userProfiles` | Extended user profile data | User owns document |
| `userStats` | Gamification statistics | User owns document |
| `user_limitations` | Free/Premium tier limitations | User owns document |
| `boards` | Collaboration boards | Board members only |
| `tasks` | Task management | Board members only |
| `reminders` | Quick capture reminders | User owns document |
| `notifications` | User notifications | User owns document |
| `subscriptions` | Premium subscriptions | User owns document |

## Reminders Collection Setup

### Collection: `reminders`

The reminders collection stores lightweight notes that users can quickly capture and later convert to full tasks.

### Document Structure

```json
{
  "id": "reminder_abc123",
  "content": "Buy groceries for dinner",
  "userId": "user_xyz789",
  "boardId": "board_def456",
  "tags": ["shopping", "urgent"],
  "priority": "high",
  "createdAt": "2026-02-09T10:30:00.000Z",
  "updatedAt": "2026-02-09T10:30:00.000Z"
}
```

### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique reminder identifier (matches document ID) |
| `content` | string | Yes | Reminder text content (1-500 characters) |
| `userId` | string | Yes | Owner's user ID (must match authenticated user) |
| `boardId` | string | Yes | Associated board ID for organization |
| `tags` | array | No | List of tag strings for categorization |
| `priority` | string | No | Priority level: "low", "medium", or "high" |
| `createdAt` | string | Yes | ISO 8601 timestamp of creation |
| `updatedAt` | string | Yes | ISO 8601 timestamp of last update |

### Field Validation Rules

- **content**: Must be a non-empty string between 1 and 500 characters
- **userId**: Must match the authenticated user's UID
- **boardId**: Must reference an existing board the user has access to
- **priority**: If provided, must be one of: "low", "medium", "high"
- **tags**: If provided, must be an array of strings

### Creating the Collection

The collection is created automatically when the first reminder is added. No manual setup is required.

### Initial Data

No seed data is required. The collection starts empty for each user.

## Security Rules

### Reminders Security Rules

The following security rules are configured for the `reminders` collection:

```javascript
match /reminders/{reminderId} {
  // Allow read if user owns the reminder
  allow read: if request.auth != null 
    && resource.data.userId == request.auth.uid;
  
  // Allow create if:
  // - User is authenticated
  // - userId matches auth uid
  // - All required fields present
  // - Content length is between 1 and 500 characters
  allow create: if request.auth != null
    && request.resource.data.userId == request.auth.uid
    && request.resource.data.keys().hasAll([
      'id', 'content', 'userId', 'boardId', 
      'createdAt', 'updatedAt'
    ])
    && request.resource.data.content is string
    && request.resource.data.content.size() > 0
    && request.resource.data.content.size() <= 500;
  
  // Allow update if user owns the reminder and userId remains immutable
  allow update: if request.auth != null
    && resource.data.userId == request.auth.uid
    && request.resource.data.userId == request.auth.uid;
  
  // Allow delete if user owns the reminder
  allow delete: if request.auth != null
    && resource.data.userId == request.auth.uid;
}
```

### Security Features

1. **Authentication Required**: All operations require a valid Firebase Auth token
2. **User Isolation**: Users can only access their own reminders
3. **Field Validation**: Content length is enforced at the database level
4. **Immutable userId**: The userId field cannot be changed after creation
5. **Required Fields**: All mandatory fields must be present on creation

### Deploying Security Rules

To deploy the security rules to Firebase:

```bash
# Deploy rules only
firebase deploy --only firestore:rules

# Or deploy everything
firebase deploy
```

### Testing Security Rules

Use the Firebase Emulator Suite to test rules locally:

```bash
# Start the emulator
firebase emulators:start

# Run tests
npm test
```

## Indexes Configuration

### Required Indexes for Reminders

Two composite indexes are required for efficient reminder queries:

#### Index 1: User Reminders Ordered by Creation Date

```json
{
  "collectionGroup": "reminders",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "userId", "mode": "ASCENDING" },
    { "fieldPath": "createdAt", "mode": "DESCENDING" }
  ]
}
```

**Purpose**: Supports fetching all user reminders ordered by creation date (most recent first)

**Query Example**:
```dart
firestore.collection('reminders')
  .where('userId', isEqualTo: userId)
  .orderBy('createdAt', descending: true)
```

#### Index 2: Board-Filtered Reminders Ordered by Creation Date

```json
{
  "collectionGroup": "reminders",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "userId", "mode": "ASCENDING" },
    { "fieldPath": "boardId", "mode": "ASCENDING" },
    { "fieldPath": "createdAt", "mode": "DESCENDING" }
  ]
}
```

**Purpose**: Supports fetching reminders filtered by board with ordering

**Query Example**:
```dart
firestore.collection('reminders')
  .where('userId', isEqualTo: userId)
  .where('boardId', isEqualTo: boardId)
  .orderBy('createdAt', descending: true)
```

### Deploying Indexes

The indexes are defined in `firestore.indexes.json` and can be deployed using:

```bash
# Deploy indexes only
firebase deploy --only firestore:indexes

# Or deploy everything
firebase deploy
```

### Index Build Time

- **Small datasets** (< 1000 documents): Indexes build in seconds
- **Medium datasets** (1000-10000 documents): Indexes build in minutes
- **Large datasets** (> 10000 documents): Indexes may take hours

You can monitor index build progress in the Firebase Console under **Firestore > Indexes**.

### Verifying Indexes

After deployment, verify indexes are active:

1. Go to Firebase Console
2. Navigate to **Firestore Database > Indexes**
3. Check that both reminder indexes show status: **Enabled**

## Migration Guide

### Adding Reminder Limitations to Existing Users

If you have existing users, you need to add reminder limitation fields to their `user_limitations` documents.

#### Migration Script

A migration script is provided at `scripts/migrate_user_limitations.dart`:

```dart
// Run with: dart scripts/migrate_user_limitations.dart
```

#### What the Migration Does

1. Fetches all existing `user_limitations` documents
2. Adds `maxReminders` field:
   - `30` for free users (where `maxActiveTasks != -1`)
   - `-1` for premium users (where `maxActiveTasks == -1`)
3. Adds `currentReminders` field: `0` (will be updated as users create reminders)
4. Updates `updatedAt` timestamp

#### Migration Steps

1. **Backup your database** (recommended):
   ```bash
   # Export Firestore data
   gcloud firestore export gs://your-bucket/backup-$(date +%Y%m%d)
   ```

2. **Test in development environment first**:
   ```bash
   # Switch to development project
   firebase use development
   
   # Run migration
   dart scripts/migrate_user_limitations.dart
   ```

3. **Verify migration results**:
   - Check a few user documents manually
   - Verify counts are correct
   - Test reminder creation

4. **Run in production**:
   ```bash
   # Switch to production project
   firebase use production
   
   # Run migration
   dart scripts/migrate_user_limitations.dart
   ```

#### Manual Migration (Alternative)

If you prefer to migrate manually or have a small number of users:

1. Go to Firebase Console > Firestore Database
2. Navigate to `user_limitations` collection
3. For each document, add fields:
   - `maxReminders`: 30 (or -1 for premium)
   - `currentReminders`: 0
   - `updatedAt`: current timestamp

### Handling New Users

New users automatically get the correct limitation fields when their account is created. No additional setup is needed.

## Testing and Verification

### Verification Checklist

After setting up Firestore for reminders, verify the following:

#### ✅ Security Rules

- [ ] Authenticated users can create reminders
- [ ] Users cannot read other users' reminders
- [ ] Content length validation works (reject > 500 chars)
- [ ] Required fields validation works
- [ ] userId immutability is enforced

#### ✅ Indexes

- [ ] Both reminder indexes show as "Enabled" in Firebase Console
- [ ] Queries execute without "missing index" errors
- [ ] Query performance is acceptable (< 1 second)

#### ✅ Limitations

- [ ] Free users are limited to 30 reminders
- [ ] Premium users have unlimited reminders
- [ ] Counter increments on reminder creation
- [ ] Counter decrements on reminder deletion

#### ✅ CRUD Operations

- [ ] Create reminder works
- [ ] Read reminders works
- [ ] Update reminder works
- [ ] Delete reminder works
- [ ] Real-time updates work across devices

### Testing Commands

```bash
# Run all tests
flutter test

# Run reminder-specific tests
flutter test test/features/reminders/

# Run integration tests
flutter test test/features/reminders/integration/

# Run property-based tests
flutter test test/property_tests/reminder_property_tests.dart
```

### Manual Testing Scenarios

1. **Create Reminder**:
   - Open app, go to Reminders page
   - Tap FAB (+)
   - Fill in content and select board
   - Verify reminder appears in list

2. **Board Filtering**:
   - Create reminders in different boards
   - Use board filter
   - Verify only selected board's reminders show

3. **Search**:
   - Create reminders with different content
   - Use search bar
   - Verify case-insensitive partial matching works

4. **Limitation Enforcement**:
   - As free user, create 30 reminders
   - Attempt to create 31st reminder
   - Verify upgrade prompt appears

5. **Conversion to Task**:
   - Create a reminder
   - Click "Convert to Task"
   - Verify task is created and reminder is deleted

### Monitoring in Production

After deployment, monitor these metrics:

- **Error Rate**: Should be < 1%
- **Query Latency**: Should be < 500ms (p95)
- **Limitation Hit Rate**: Track how many users hit the 30 reminder limit
- **Conversion Rate**: Track reminder → task conversions

Use Firebase Console > Firestore > Usage tab to monitor:
- Read/Write operations
- Storage usage
- Index usage

## Troubleshooting

### Common Issues

#### Issue: "Missing or insufficient permissions"

**Cause**: Security rules are not deployed or user is not authenticated

**Solution**:
```bash
firebase deploy --only firestore:rules
```

#### Issue: "The query requires an index"

**Cause**: Composite indexes are not deployed or still building

**Solution**:
```bash
firebase deploy --only firestore:indexes
```

Wait for indexes to finish building (check Firebase Console).

#### Issue: Reminder creation fails silently

**Cause**: Content length exceeds 500 characters

**Solution**: Validate content length in the app before submission:
```dart
if (content.length > 500) {
  throw ReminderException('Content must be 500 characters or less');
}
```

#### Issue: Counter out of sync

**Cause**: Reminder deletion failed but counter was decremented

**Solution**: Run a sync script to recalculate counters:
```dart
// Count actual reminders
final count = await firestore
  .collection('reminders')
  .where('userId', isEqualTo: userId)
  .get()
  .then((snapshot) => snapshot.docs.length);

// Update counter
await firestore
  .collection('user_limitations')
  .doc(userId)
  .update({'currentReminders': count});
```

### Getting Help

- **Firebase Documentation**: https://firebase.google.com/docs/firestore
- **SyncLife Issues**: Open an issue in the project repository
- **Firebase Support**: https://firebase.google.com/support

## Best Practices

### Performance

1. **Use Streams for Real-time Updates**: Leverage Firestore's real-time listeners
2. **Implement Pagination**: For users with many reminders (> 100)
3. **Cache Locally**: Firestore SDK handles this automatically
4. **Batch Operations**: Use batch writes when creating/deleting multiple reminders

### Security

1. **Never Trust Client Input**: Validate all data in security rules
2. **Use Server Timestamps**: For accurate timing across timezones
3. **Audit Regularly**: Review security rules and access patterns
4. **Monitor Anomalies**: Set up alerts for unusual activity

### Cost Optimization

1. **Minimize Reads**: Use real-time listeners instead of polling
2. **Optimize Queries**: Use indexes to avoid full collection scans
3. **Clean Up Old Data**: Archive or delete old reminders
4. **Monitor Usage**: Track read/write operations in Firebase Console

## Conclusion

This guide covers the complete setup of Firestore for the SyncLife reminders system. Follow the steps in order, test thoroughly in development before deploying to production, and monitor your deployment for any issues.

For questions or issues, refer to the troubleshooting section or open an issue in the project repository.
