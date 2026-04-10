# Firestore Permissions Fix

## Issue
Books could not be issued due to Firestore permission error:
```
Status{code=PERMISSION_DENIED, description=Missing or insufficient permissions.}
```

## Root Cause
The `borrow_transactions` collection was not included in Firestore security rules.

## Solution Applied

### Updated `firestore.rules`
Added the following rule:
```javascript
// ── Borrow Transactions ──
match /borrow_transactions/{transactionId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null;
}
```

### Deployed to Firebase
```bash
firebase use lib-management-d6460
firebase deploy --only firestore:rules
```

## Status
✅ **FIXED** - Firestore rules deployed successfully

## Testing
Now you can:
1. Login as librarian
2. Go to "Borrow" tab
3. Scan reader QR or search by email
4. Add books and issue transaction
5. Transaction should be created successfully

## Additional Notes

### Firebase Messaging Warning
The error about `_firebaseMessagingBackgroundHandler` is a warning, not critical:
```
NoSuchMethodError: No top-level getter '_firebaseMessagingBackgroundHandler' declared.
```

This occurs because Firebase Messaging is configured but the background handler is not set up. This doesn't affect the book issuing functionality.

**To fix (optional):**
If you want to add push notifications later, you'll need to:
1. Add a background message handler in `main.dart`
2. Configure Firebase Cloud Messaging properly

For now, this can be ignored as it doesn't impact core functionality.

## Current Firestore Rules

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // ── Users ──
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // ── Libraries ──
    match /libraries/{libraryId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
    }

    // ── Library Members ──
    match /library_members/{docId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow delete: if request.auth != null;
    }

    // ── Books ──
    match /books/{bookId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }

    // ── Borrows ──
    match /borrows/{borrowId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }

    // ── Borrow Transactions ── [NEWLY ADDED]
    match /borrow_transactions/{transactionId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }

    // ── Reservations ──
    match /reservations/{reservationId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }

    // ── Access Tokens ──
    match /access_tokens/{tokenId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## Verification Steps

1. **Check Firebase Console**
   - Go to https://console.firebase.google.com/project/lib-management-d6460
   - Navigate to Firestore Database → Rules
   - Verify the rules include `borrow_transactions`

2. **Test in App**
   - Restart the app
   - Login as librarian
   - Try to issue books
   - Should work without permission errors

## Troubleshooting

If you still get permission errors:

1. **Clear app data and cache**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Restart the app completely**
   - Force stop the app
   - Clear app data from device settings
   - Reinstall if necessary

3. **Check Firebase Console**
   - Verify rules are published
   - Check Firestore usage tab for any errors

4. **Verify authentication**
   - Ensure user is logged in
   - Check `request.auth != null` in rules

## Next Steps

✅ Firestore permissions fixed
✅ Rules deployed
⏭️ Test book issuing functionality
⏭️ Verify transaction creation works
⏭️ Test return workflow

The system should now work correctly!
