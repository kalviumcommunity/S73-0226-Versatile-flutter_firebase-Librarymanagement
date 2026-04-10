# Library Validation - Testing Checklist

## Prerequisites
- Have at least 2 libraries in the system (Library A and Library B)
- Have at least 1 librarian account for each library
- Have at least 1 reader account
- Have books available in both libraries

## Test Scenarios 

### ✅ Scenario 1: Issue Books at Library A
**Steps:**
1. Login as Librarian of Library A
2. Navigate to "Issue Books" screen
3. Scan reader QR or search by email
4. Select 2-3 books from Library A
5. Set borrow period (14 days)
6. Click "Issue Books"

**Expected Results:**
- ✅ Transaction created successfully
- ✅ Success message shown
- ✅ Book stock decremented
- ✅ Transaction appears in reader's "My Borrows"
- ✅ Transaction card shows "Library: Library A"

---

### ✅ Scenario 2: Try to Return at Wrong Library (Library B)
**Steps:**
1. Login as Librarian of Library B
2. Navigate to "Return Books" screen
3. Scan the transaction QR from Library A (from reader's app)

**Expected Results:**
- ✅ Error message shown: "This transaction is from Library A. You can only process returns for your library."
- ✅ NO confirmation dialog appears
- ✅ Transaction is NOT returned
- ✅ Book stock remains unchanged

---

### ✅ Scenario 3: Return at Correct Library (Library A)
**Steps:**
1. Login as Librarian of Library A
2. Navigate to "Return Books" screen
3. Scan the transaction QR from Library A

**Expected Results:**
- ✅ Confirmation dialog appears
- ✅ Shows correct transaction details
- ✅ Shows library name: Library A
- ✅ Shows all borrowed books
- ✅ Shows due date
- ✅ If overdue, shows fine amount
- ✅ Click "Confirm Return"
- ✅ Success message shown
- ✅ Transaction status changes to "Returned"
- ✅ Book stock incremented
- ✅ Transaction moves to "Returned" tab in reader's app

---

### ✅ Scenario 4: Transaction Card Display
**Steps:**
1. Login as Reader
2. Navigate to "My Borrows"
3. View "Active" tab
4. View "Returned" tab

**Expected Results:**
- ✅ Each transaction card shows library icon
- ✅ Each card displays "Library: [Library Name]"
- ✅ Library name is clearly visible
- ✅ Library name matches the issuing library

---

### ✅ Scenario 5: Transaction QR Code
**Steps:**
1. Login as Reader
2. Navigate to "My Borrows" → "Active" tab
3. Tap on a transaction card
4. View QR code dialog

**Expected Results:**
- ✅ QR code is displayed
- ✅ Shows transaction details
- ✅ Shows library name (implicitly in the data)
- ✅ QR format: `TRANSACTION:<id>:<userId>:<libraryId>`
- ✅ Can be scanned by librarian

---

### ✅ Scenario 6: Manual Search Return
**Steps:**
1. Login as Librarian of Library A
2. Navigate to "Return Books" screen
3. Click "Manual Search"
4. Search by reader email or name
5. Select a transaction from Library A

**Expected Results:**
- ✅ Only shows transactions from Library A
- ✅ Can select and return transaction
- ✅ Confirmation dialog appears
- ✅ Return processes successfully

---

### ✅ Scenario 7: Cross-Library Reader
**Steps:**
1. Have a reader who is member of both Library A and Library B
2. Issue books from Library A
3. Issue books from Library B
4. View reader's "My Borrows"

**Expected Results:**
- ✅ Shows transactions from both libraries
- ✅ Each transaction clearly shows its library name
- ✅ Library A transactions can only be returned at Library A
- ✅ Library B transactions can only be returned at Library B

---

### ✅ Scenario 8: Overdue Transaction
**Steps:**
1. Have an overdue transaction from Library A
2. Login as Librarian of Library B
3. Try to scan the overdue transaction QR

**Expected Results:**
- ✅ Error message shown (library mismatch)
- ✅ Fine amount is NOT processed at wrong library
- ✅ Transaction remains overdue

**Then:**
4. Login as Librarian of Library A
5. Scan the overdue transaction QR

**Expected Results:**
- ✅ Confirmation dialog shows fine amount
- ✅ Shows "Overdue! Fine: ₹X"
- ✅ Can process return with fine
- ✅ Transaction marked as returned

---

## Edge Cases

### Edge Case 1: Old QR Format
**Steps:**
1. Use old QR format: `LIB_TRANSACTION:<id>`
2. Scan in return screen

**Expected Results:**
- ✅ System fetches transaction from database
- ✅ Validates library from transaction data
- ✅ Works correctly (backward compatible)

---

### Edge Case 2: Invalid QR Code
**Steps:**
1. Scan a random QR code (not a transaction QR)

**Expected Results:**
- ✅ Error message: "Invalid QR code. Please scan a transaction QR code."
- ✅ No crash or unexpected behavior

---

### Edge Case 3: Already Returned Transaction
**Steps:**
1. Return a transaction successfully
2. Try to scan the same QR again

**Expected Results:**
- ✅ Error message: "This transaction has already been returned."
- ✅ No duplicate return processing

---

## Performance Tests

### Test 1: Multiple Transactions
- Create 10+ transactions across different libraries
- Verify all show correct library names
- Verify filtering works correctly

### Test 2: Stock Updates
- Issue multiple books
- Return multiple books
- Verify stock counts are accurate
- Verify no race conditions

---

## Sign-Off

| Test Scenario | Status | Tester | Date | Notes |
|--------------|--------|--------|------|-------|
| Scenario 1: Issue at Library A | ⬜ | | | |
| Scenario 2: Return at Wrong Library | ⬜ | | | |
| Scenario 3: Return at Correct Library | ⬜ | | | |
| Scenario 4: Card Display | ⬜ | | | |
| Scenario 5: QR Code | ⬜ | | | |
| Scenario 6: Manual Search | ⬜ | | | |
| Scenario 7: Cross-Library Reader | ⬜ | | | |
| Scenario 8: Overdue Transaction | ⬜ | | | |
| Edge Case 1: Old QR Format | ⬜ | | | |
| Edge Case 2: Invalid QR | ⬜ | | | |
| Edge Case 3: Already Returned | ⬜ | | | |

---

## Critical Success Criteria

✅ **Must Pass:**
1. Books issued at Library A can ONLY be returned at Library A
2. Clear error messages when library mismatch occurs
3. Library name is visible in all transaction cards
4. No crashes or unexpected behavior
5. Stock updates correctly after issue/return
6. Backward compatibility with old QR codes

✅ **Nice to Have:**
1. Fast QR scanning
2. Smooth UI transitions
3. Helpful error messages
4. Good user experience

---

## Notes
- Test with real devices for QR scanning
- Test with different screen sizes
- Test with slow network connections
- Test with multiple concurrent users
