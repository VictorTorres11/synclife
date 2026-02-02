# Firestore Setup Guide - Fixing Activity Loading Issues

## Problem
The recent activities section shows a loading spinner indefinitely and logs show:
```
Error fetching activities for user: [cloud_firestore/permission-denied] Missing or insufficient permissions.
```

## Root Cause
The Firestore security rules need to be deployed to allow the activities collection to be accessed.

## Solution

### Option 1: Deploy Firestore Rules (Recommended)
1. Make sure you have Firebase CLI installed:
   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Deploy the Firestore rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

4. Verify the rules are deployed by checking the Firebase Console > Firestore Database > Rules

### Option 2: Temporarily Use Simple Activities Widget
The dashboard has been temporarily switched to use `RecentActivityWidgetSimple` which shows sample activities without connecting to Firestore.

To switch back to the full activity system after fixing Firestore:
1. Open `lib/src/features/dashboard/presentation/screens/home_dashboard_screen.dart`
2. Change the import from:
   ```dart
   import '../widgets/recent_activity_widget_simple.dart';
   ```
   to:
   ```dart
   import '../widgets/recent_activity_widget.dart';
   ```
3. Change the widget from:
   ```dart
   const RecentActivityWidgetSimple(),
   ```
   to:
   ```dart
   const RecentActivityWidget(),
   ```

### Option 3: Test Firestore Rules in Firebase Console
1. Go to Firebase Console > Firestore Database > Rules
2. Click "Simulator" tab
3. Test a read operation:
   - **Simulation type**: Read
   - **Location**: `/activities/{activityId}`
   - **Authenticated**: Yes (check the box)
   - **Firebase UID**: Use your actual user ID from the error log
   - **Provider**: Custom
4. Click "Run" to test if the rules allow the operation

## Current Firestore Rules
The `firestore.rules` file already includes the correct rules for activities:

```javascript
// Activities - users can only access their own activities
match /activities/{activityId} {
  allow read, write: if request.auth != null && 
    request.auth.uid == resource.data.userId;
  allow create: if request.auth != null && 
    request.auth.uid == request.resource.data.userId;
}
```

## Testing the Activity System
Once Firestore rules are deployed:

1. **Login to the app** - This will create a login activity
2. **Check the dashboard** - You should see the login activity in "Atividade Recente"
3. **Create tasks or perform other actions** - These will generate more activities

## Troubleshooting

### If rules deployment fails:
- Check that you're in the correct Firebase project: `firebase use --list`
- Switch to correct project: `firebase use [project-id]`
- Verify your Firebase configuration in `firebase.json`

### If activities still don't load:
- Check browser console for any other errors
- Verify user authentication is working
- Check that the user ID in the error matches your authenticated user

### If you see "Missing or insufficient permissions" after deployment:
- Wait a few minutes for rules to propagate
- Clear browser cache and reload
- Check that the rules were actually deployed in Firebase Console

## Alternative: Disable Activity System Temporarily
If you want to disable the activity system entirely for now:

1. The dashboard is already using the simple widget
2. Remove activity logging from login by commenting out these lines in `lib/src/features/auth/presentation/pages/login_page.dart`:
   ```dart
   // Log login activity
   // final activityLogger = ref.read(activityLoggerProvider);
   // await activityLogger.logLogin(user.id);
   ```

This will prevent any Firestore calls related to activities while keeping all other functionality working.