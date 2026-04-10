# Testing Guide - Multi-Book Transaction System

## Quick Start Testing

### Prerequisites
1. Firebase project configured
2. At least 3 test users:
   - 1 Reader account
   - 1 Librarian account
   - 1 Admin account (optional)
3. Library with books in stock

## Test Scenarios

### Scenario 1: Librarian Issues Books via QR Scan

**Steps:**
1. Login as Reader
2. Go to Profile tab
3. Verify "My QR Code" button is visible
4. Tap "My QR Code" - QR should display with format `LIB_USER:<uid>:<email>`
5. Take screenshot or keep app open

6. Login as Librarian (different device or logout/login)
7. Go to "Borrow" tab (3rd tab in bottom nav)
8. Tap "Scan Reader QR Code"
9. Scan the reader's QR code
10. Verify reader name and email auto-fill
11. Tap "Add Book"
12. Select a book from the list
13. Adjust quantity (test increment/decrement)
14. Tap "Add"
15. Repeat steps 11-14 to add 2-3 more books
16. Select borrow period (e.g., 14 days)
17. Tap "Issue Books"

**Expected Results:**
- ✅ Reader identified correctly
- ✅ Multiple books added to transaction
- ✅ Stock validation works (error if insufficient)
- ✅ Transaction created successfully
- ✅ Success message shown
- ✅ Form clears after success

### Scenario 2: Librarian Issues Books via Manual Search

**Steps:**
1. Login as Librarian
2. Go to "Borrow" tab
3. Enter reader email in text field
4. Tap "Find"
5. Verify reader details displayed
6. Add books and issue (same as Scenario 1, steps 11-17)

**Expected Results:**
- ✅ Reader found by email
- ✅ Transaction created successfully

### Scenario 3: Reader Views Transaction and QR

**Steps:**
1. Login as Reader (who borrowed books)
2. Go to "Borrows" tab (3rd tab in bottom nav)
3. Verify active transaction is displayed
4. Check transaction details:
   - Number of books
   - Issue date
   - Due date
   - Book list with quantities
5. Tap "Show QR for Return"
6. Verify QR code displays with format `LIB_TRANSACTION:<id>`
7. Verify transaction details shown below QR

**Expected Results:**
- ✅ Active transactions listed
- ✅ Transaction QR code displays correctly
- ✅ All book details visible
- ✅ Due date shown

### Scenario 4: Librarian Returns Books via QR Scan

**Steps:**
1. Login as Librarian
2. Create a new navigation option or use existing return flow
3. Scan the transaction QR code from reader's app
4. Verify transaction details displayed:
   - Reader name and email
   - Books borrowed with quantities
   - Issue and due dates
   - Fine amount (if overdue)
5. Tap "Confirm Return"

**Expected Results:**
- ✅ Transaction identified correctly
- ✅ All details displayed
- ✅ Fine calculated if overdue
- ✅ Return processed successfully
- ✅ Stock restored
- ✅ Transaction marked as returned

### Scenario 5: Librarian Returns Books via Manual Search

**Steps:**
1. Login as Librarian
2. Go to return screen
3. Tap "Manual Search"
4. Select "Email" or "Name"
5. Enter reader email/name
6. Tap "Search"
7. Select transaction from results
8. Verify details and confirm return

**Expected Results:**
- ✅ Search finds active transactions
- ✅ Return processed successfully

### Scenario 6: QR Code Enforcement

**Steps:**
1. Login as Reader
2. Go to Profile tab
3. Verify "My QR Code" button is visible

4. Logout and login as Librarian
5. Go to Profile tab
6. Verify "My QR Code" button is NOT visible

7. Logout and login as Admin
8. Go to Profile tab
9. Verify "My QR Code" button is NOT visible

**Expected Results:**
- ✅ Only readers have QR code button
- ✅ Admin and librarian do NOT have QR codes

### Scenario 7: Stock Validation

**Steps:**
1. Login as Librarian
2. Find a book with low stock (e.g., 2 copies available)
3. Try to issue 3 copies to a reader
4. Verify error message shown
5. Reduce quantity to 2 or less
6. Issue successfully

**Expected Results:**
- ✅ Error shown when quantity exceeds stock
- ✅ Transaction succeeds with valid quantity
- ✅ Stock decremented correctly

### Scenario 8: Overdue Fine Calculation

**Steps:**
1. Create a transaction with past due date (manually in Firestore for testing)
   - Set `dueDate` to 3 days ago
   - Keep `status` as "active"
2. Login as Reader
3. Go to "Borrows" tab
4. Verify transaction shows "OVERDUE" badge
5. Verify fine amount displayed (₹6 for 3 days)
6. Tap "Show QR for Return"
7. Verify fine shown in QR dialog

8. Login as Librarian
9. Scan transaction QR or search manually
10. Verify fine displayed in return confirmation
11. Confirm return
12. Verify fine recorded in transaction

**Expected Results:**
- ✅ Overdue status detected
- ✅ Fine calculated correctly (₹2/day)
- ✅ Fine displayed to reader and librarian
- ✅ Fine recorded on return

### Scenario 9: Transaction History

**Steps:**
1. Login as Reader with returned transactions
2. Go to "Borrows" tab
3. Scroll down to "History" section
4. Verify returned transactions listed
5. Verify "RETURNED" badge shown
6. Verify return date displayed
7. Verify no "Show QR" button for returned transactions

**Expected Results:**
- ✅ History section displays returned transactions
- ✅ Correct status and dates shown
- ✅ No QR button for returned transactions

### Scenario 10: Role Validation

**Steps:**
1. Login as Librarian
2. Go to "Borrow" tab
3. Try to scan another librarian's QR code
4. Verify error message shown
5. Try to search for admin email
6. Verify error message shown

**Expected Results:**
- ✅ Error: "This user is not a reader"
- ✅ Cannot issue books to non-readers

## Edge Cases to Test

### 1. Empty States
- [ ] No active transactions (reader view)
- [ ] No books available (librarian borrow)
- [ ] No search results (manual search)

### 2. Network Issues
- [ ] Offline transaction creation (should fail gracefully)
- [ ] Slow network (loading states shown)
- [ ] Connection loss during transaction

### 3. Concurrent Operations
- [ ] Two librarians issuing same book simultaneously
- [ ] Stock updates during transaction creation

### 4. Data Validation
- [ ] Invalid QR code format
- [ ] Deleted user/book references
- [ ] Negative quantities (should be prevented)

## Performance Testing

### Load Testing
1. Create 50+ transactions
2. Verify list scrolling is smooth
3. Check real-time updates performance

### QR Scanning
1. Test in different lighting conditions
2. Test with different camera qualities
3. Verify scan speed and accuracy

## Regression Testing

After any code changes, verify:
- [ ] Old borrow system still works (if not deprecated)
- [ ] Authentication flow unchanged
- [ ] Book management unchanged
- [ ] Profile updates work
- [ ] Navigation works correctly

## Bug Reporting Template

```
**Bug Title:** [Brief description]

**Steps to Reproduce:**
1. 
2. 
3. 

**Expected Result:**
[What should happen]

**Actual Result:**
[What actually happened]

**Screenshots:**
[If applicable]

**Device Info:**
- Device: [e.g., Pixel 6]
- OS: [e.g., Android 13]
- App Version: [if applicable]

**Additional Context:**
[Any other relevant information]
```

## Success Criteria

All scenarios should pass with:
- ✅ No crashes or errors
- ✅ Correct data displayed
- ✅ Smooth user experience
- ✅ Proper error messages
- ✅ Data consistency maintained
- ✅ Real-time updates working

## Notes

- Test on both Android and iOS if possible
- Test with different screen sizes
- Test with accessibility features enabled
- Clear app data between major test runs
- Monitor Firestore console for data integrity
