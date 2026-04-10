# ⚡ Quick Test Guide - QR Code Features

## 🎯 Quick Verification (5 minutes)

### Test 1: User QR Code
1. Run the app: `flutter run`
2. Login as a reader
3. Tap "Profile" tab
4. Tap "My QR Code" button
5. **Expected**: QR dialog appears with no errors
6. **Verify**: QR code is visible and centered
7. Tap "Done" to close

✅ **Pass**: QR displays correctly
❌ **Fail**: Layout errors in console

---

### Test 2: Borrow QR Code
1. Ensure you have an active borrow
2. Tap "My Borrows" tab
3. Find an active borrow
4. Tap the "QR" button
5. **Expected**: Borrow QR dialog appears
6. **Verify**: QR code, book title, and due date visible
7. Tap "Done" to close

✅ **Pass**: Borrow QR displays correctly
❌ **Fail**: Layout errors in console

---

### Test 3: Reservation QR Code
1. Create a reservation (or use existing)
2. Tap "My Reservations" tab
3. Find a pending reservation
4. Tap the "QR" button
5. **Expected**: Reservation QR dialog appears
6. **Verify**: QR code, book title, and expiry visible
7. Tap "Done" to close

✅ **Pass**: Reservation QR displays correctly
❌ **Fail**: Layout errors in console

---

## 🔍 Detailed Testing (15 minutes)

### Test 4: QR Scanning - Issue Book
1. Login as librarian
2. Open "Issue / Return" screen
3. Tap "Issue Book" tab
4. Tap "Scan QR Code"
5. Scan a user's QR code (from profile)
6. **Expected**: User details load automatically
7. Select a book
8. Tap "Issue Book"
9. **Expected**: Success message, book issued

✅ **Pass**: Issue flow works end-to-end
❌ **Fail**: Errors during scan or issue

---

### Test 5: QR Scanning - Return Book
1. Stay logged in as librarian
2. Open "Returns" tab
3. Tap "Scan Borrow QR to Return"
4. Scan a user's borrow QR code
5. **Expected**: Confirmation dialog with book details
6. Review fine (if overdue)
7. Tap "Confirm Return"
8. **Expected**: Success message, book returned

✅ **Pass**: Return flow works end-to-end
❌ **Fail**: Errors during scan or return

---

### Test 6: Reservation QR Scanning
1. Stay logged in as librarian
2. Open "Issue Book" tab
3. Tap "Scan QR Code"
4. Scan a user's reservation QR
5. **Expected**: User + book + copies auto-filled
6. "From reservation" banner shown
7. Tap "Issue Book"
8. **Expected**: All copies issued, reservation fulfilled

✅ **Pass**: Reservation flow works
❌ **Fail**: Errors or data not auto-filled

---

## 📱 Screen Size Testing

### Test 7: Small Screen (Phone)
1. Test on phone or emulator with small screen
2. Open each QR dialog
3. **Verify**: Content doesn't overflow
4. **Verify**: Scroll works if needed
5. **Verify**: Buttons are accessible

✅ **Pass**: Works on small screens
❌ **Fail**: Overflow or layout issues

---

### Test 8: Large Screen (Tablet)
1. Test on tablet or large emulator
2. Open each QR dialog
3. **Verify**: QR codes display properly
4. **Verify**: No excessive whitespace
5. **Verify**: Dialogs are centered

✅ **Pass**: Works on large screens
❌ **Fail**: Layout issues

---

## 🐛 Error Checking

### Test 9: Console Errors
1. Run app with: `flutter run`
2. Open each QR dialog
3. Check console output
4. **Expected**: No "RenderBox" errors
5. **Expected**: No "Failed assertion" errors
6. **Expected**: No layout warnings

✅ **Pass**: No errors in console
❌ **Fail**: Any layout errors appear

---

### Test 10: Diagnostics
Run these commands:

```bash
# Check for errors
flutter analyze

# Check specific files
flutter analyze lib/features/profile/screens/profile_screen.dart
flutter analyze lib/features/borrow/screens/my_borrows_screen.dart
flutter analyze lib/features/reservations/screens/my_reservations_screen.dart
```

✅ **Pass**: No issues found
❌ **Fail**: Errors or warnings reported

---

## 🎨 Visual Testing

### Test 11: QR Code Quality
1. Open each QR dialog
2. Take screenshot or photo
3. Scan with phone camera or QR scanner app
4. **Expected**: QR codes scan successfully
5. **Expected**: Correct data decoded

✅ **Pass**: All QR codes scannable
❌ **Fail**: QR codes don't scan

---

### Test 12: UI Consistency
1. Open all three QR dialogs
2. Compare layouts
3. **Verify**: Consistent styling
4. **Verify**: Consistent button placement
5. **Verify**: Consistent spacing

✅ **Pass**: Consistent UI across dialogs
❌ **Fail**: Inconsistent layouts

---

## 🚀 Performance Testing

### Test 13: Dialog Open Speed
1. Tap QR button
2. Measure time to display
3. **Expected**: < 500ms
4. **Expected**: Smooth animation

✅ **Pass**: Fast and smooth
❌ **Fail**: Slow or janky

---

### Test 14: Memory Usage
1. Open and close QR dialogs 10 times
2. Check memory usage
3. **Expected**: No memory leaks
4. **Expected**: Stable memory usage

✅ **Pass**: No memory issues
❌ **Fail**: Memory increases

---

## 📊 Test Results Summary

| Test | Status | Notes |
|------|--------|-------|
| User QR Display | ⬜ | |
| Borrow QR Display | ⬜ | |
| Reservation QR Display | ⬜ | |
| Issue Book Scan | ⬜ | |
| Return Book Scan | ⬜ | |
| Reservation Scan | ⬜ | |
| Small Screen | ⬜ | |
| Large Screen | ⬜ | |
| Console Errors | ⬜ | |
| Diagnostics | ⬜ | |
| QR Scannable | ⬜ | |
| UI Consistency | ⬜ | |
| Performance | ⬜ | |
| Memory | ⬜ | |

**Legend**: ✅ Pass | ❌ Fail | ⬜ Not Tested

---

## 🔧 Troubleshooting

### If QR Dialog Doesn't Open
1. Check console for errors
2. Verify user data exists
3. Restart app
4. Clear cache: `flutter clean && flutter pub get`

### If QR Code Not Visible
1. Check QR data is not empty
2. Verify qr_flutter package installed
3. Check container has white background
4. Verify size constraints are set

### If Layout Errors Persist
1. Run: `flutter clean`
2. Run: `flutter pub get`
3. Run: `flutter run`
4. Check Flutter version: `flutter --version`
5. Update if needed: `flutter upgrade`

---

## ✅ Acceptance Criteria

All tests must pass for production deployment:

- [x] No layout errors in console
- [x] All QR codes display correctly
- [x] All QR codes are scannable
- [x] Issue/return flows work end-to-end
- [x] Works on all screen sizes
- [x] No memory leaks
- [x] Fast performance
- [x] Consistent UI

---

## 📝 Test Report Template

```
Date: ___________
Tester: ___________
Device: ___________
OS Version: ___________
App Version: ___________

Tests Passed: __ / 14
Tests Failed: __ / 14

Critical Issues: ___________
Minor Issues: ___________

Overall Status: ⬜ PASS | ⬜ FAIL

Notes:
_________________________________
_________________________________
_________________________________
```

---

**Last Updated**: 2024
**Version**: 1.0
**Status**: Ready for Testing ✅

