# Reservation Library Validation - Debug Guide

## Issue
Librarian from Library A can still collect reservations for Library B.

## Validation Points Added

### 1. QR Scanner Path ✅
**File:** `lib/features/reservations/screens/librarian_reservation_scanner.dart` (line ~250)

When scanning QR code, validates:
```dart
if (reservation.libraryId != librarianLibraryId) {
  throw Exception('This reservation is for ${reservation.libraryName}. 
                   You can only collect reservations for your library.');
}
```

### 2. Pending Reservations Tab Path ✅
**File:** `lib/features/reservations/screens/librarian_reservation_scanner.dart` (line ~305)

When tapping on a reservation from the list, validates:
```dart
if (reservation.libraryId != librarianLibraryId) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('This reservation is for ${reservation.libraryName}. 
                     You can only collect reservations for your library.'),
      backgroundColor: AppColors.error,
    ),
  );
  return;
}
```

### 3. Data Source Filtering ✅
**File:** `lib/features/reservations/repository/reservation_repository.dart` (line ~351)

Pending reservations stream filters at database level:
```dart
return _reservationsRef
    .where('libraryId', isEqualTo: libraryId)
    .where('status', isEqualTo: ReservationStatus.pending.name)
```

## Debug Steps

### Step 1: Check Console Logs

When scanning a QR code or tapping a reservation, you should see:
```
🔍 Library Validation:
  Librarian: [Name] ([UID])
  Librarian Library ID: [ID]
  Reservation Library ID: [ID]
  Reservation Library Name: [Name]
✅ Library validation passed
```

OR if validation fails:
```
🔍 Library Validation:
  Librarian: [Name] ([UID])
  Librarian Library ID: [ID]
  Reservation Library ID: [Different ID]
  Reservation Library Name: [Different Name]
Error: This reservation is for [Library Name]. You can only collect reservations for your library.
```

### Step 2: Verify Librarian's Library ID

1. Open Firestore Console
2. Go to `users` collection
3. Find the librarian's document
4. Check the `libraryId` field
5. **Expected:** Should be set to the admin's UID who created the librarian

**If libraryId is null or wrong:**
- The librarian was not properly set up
- Need to update the librarian's document with correct libraryId

### Step 3: Verify Reservation's Library ID

1. Open Firestore Console
2. Go to `reservations` collection
3. Find the reservation document
4. Check the `libraryId` field
5. **Expected:** Should match the library where books were reserved

**If libraryId is null or wrong:**
- The reservation was not created properly
- Need to fix the reservation creation logic

### Step 4: Test Scenarios

#### Scenario A: Same Library (Should Work)
1. Login as Librarian of Library A (libraryId = AdminA_UID)
2. Reader creates reservation for Library A (libraryId = AdminA_UID)
3. Librarian scans QR or taps reservation
4. **Expected:** Collection dialog appears
5. **Expected:** Can issue books successfully

#### Scenario B: Different Library (Should Fail)
1. Login as Librarian of Library A (libraryId = AdminA_UID)
2. Reader creates reservation for Library B (libraryId = AdminB_UID)
3. Librarian scans QR or taps reservation
4. **Expected:** Error message appears
5. **Expected:** "This reservation is for Library B. You can only collect reservations for your library."
6. **Expected:** Dialog does NOT appear

#### Scenario C: Pending List Filtering
1. Login as Librarian of Library A
2. Go to "Pending Reservations" tab
3. **Expected:** Only see reservations where libraryId = AdminA_UID
4. **Expected:** No reservations from Library B visible

## Common Issues

### Issue 1: Librarian's libraryId is null
**Symptom:** Error message "Librarian library not found"

**Cause:** Librarian document doesn't have libraryId field

**Fix:**
1. Open Firestore Console
2. Find librarian's document in `users` collection
3. Add field: `libraryId: [AdminUID]`
4. Restart app

### Issue 2: Reservation's libraryId is wrong
**Symptom:** Validation passes when it shouldn't

**Cause:** Reservation has wrong libraryId

**Fix:**
1. Check reservation creation code
2. Ensure libraryId is passed correctly
3. Update existing reservations in Firestore

### Issue 3: Multiple Libraries with Same ID
**Symptom:** Validation doesn't work as expected

**Cause:** Multiple libraries using same admin UID

**Fix:**
1. Ensure each library has unique admin
2. Check library setup process

### Issue 4: Validation Code Not Running
**Symptom:** No debug logs appear

**Cause:** Code not deployed or hot reload failed

**Fix:**
1. Stop app completely
2. Run `flutter clean`
3. Run `flutter run`
4. Try again

## Firestore Data Structure

### Librarian Document (users collection)
```json
{
  "uid": "librarian_uid",
  "name": "John Doe",
  "email": "john@example.com",
  "role": "librarian",
  "libraryId": "admin_uid",  // ← CRITICAL: Must be set
  "libraryName": "Central Library"
}
```

### Reservation Document (reservations collection)
```json
{
  "id": "reservation_id",
  "userId": "reader_uid",
  "userName": "Jane Reader",
  "userEmail": "jane@example.com",
  "libraryId": "admin_uid",  // ← CRITICAL: Must match librarian's libraryId
  "libraryName": "Central Library",
  "status": "pending",
  "items": [...]
}
```

## Testing Checklist

- [ ] Console shows debug logs when scanning QR
- [ ] Console shows debug logs when tapping reservation
- [ ] Librarian's libraryId is set in Firestore
- [ ] Reservation's libraryId is set in Firestore
- [ ] Error message appears for wrong library
- [ ] Collection dialog appears for correct library
- [ ] Pending list only shows correct library's reservations

## If Issue Still Persists

1. **Check Console Logs** - What do the debug logs show?
2. **Check Firestore Data** - Are libraryId fields set correctly?
3. **Check User Role** - Is the user actually a librarian?
4. **Restart App** - Hot reload might not apply changes
5. **Clear Cache** - Run `flutter clean` and rebuild

## Contact Information

If validation is still not working after following this guide:
1. Share console logs showing the debug output
2. Share screenshots of Firestore documents (librarian and reservation)
3. Share exact steps to reproduce the issue
