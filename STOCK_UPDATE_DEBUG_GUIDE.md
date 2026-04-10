# Stock Update Debugging Guide

## Issue
Stock numbers are not reflecting correctly after issuing or returning books.

## Enhanced Debugging Added

I've added comprehensive logging to track every step of the stock update process.

### File Modified
`lib/features/borrow/repository/borrow_transaction_repository.dart`

### What the Logs Show

#### When Issuing Books (Creating Transaction)
```
📦 ========== CREATING TRANSACTION ==========
📦 User: user@example.com
📦 Books to borrow:
  - Book Title: 2 copies (BookID: lib123_abc456)
📦 Transaction ID: trans_xyz
  📖 Book Title:
     - Current total: 10
     - Current available: 8
     - Borrowing: 2
     - Will become: 6
     ✅ Batch update queued: decrement availableCopies by 2
📦 Committing batch...
✅ ========== TRANSACTION CREATED SUCCESSFULLY ==========
```

#### When Returning Books
```
📦 ========== RETURNING TRANSACTION ==========
📦 Transaction ID: trans_xyz
📦 User: user@example.com
📚 Books to return:
  - Book Title: 2 copies (BookID: lib123_abc456)
  📖 Book Title:
     - Current total: 10
     - Current available: 6
     - Returning: 2
     - Will become: 8
     ✅ Batch update queued: increment availableCopies by 2
📦 Committing batch...
✅ ========== TRANSACTION RETURNED SUCCESSFULLY ==========
```

## Testing Steps

### Step 1: Rebuild the App
```bash
flutter clean
flutter pub get
flutter run -d 10BCBF1272000H7
```

### Step 2: Test Issuing Books

1. **Login as Librarian**

2. **Go to "Issue & Return Books" tab**

3. **Issue a book:**
   - Scan or search for a reader
   - Add a book (note the current available copies)
   - Issue the transaction

4. **Watch Console Output:**
   - Look for the "CREATING TRANSACTION" section
   - Check "Current available" number
   - Check "Will become" number
   - Verify batch commits successfully

5. **Check Stock Management:**
   - Go to "Manage Stock"
   - Find the book you just issued
   - Verify "available" count decreased correctly

### Step 3: Test Returning Books

1. **Go to "Issue & Return Books" → "Return Books" tab**

2. **Return the transaction:**
   - Scan the transaction QR code or search
   - Complete the return

3. **Watch Console Output:**
   - Look for the "RETURNING TRANSACTION" section
   - Check "Current available" number
   - Check "Will become" number (should increase)
   - Verify batch commits successfully

4. **Check Stock Management:**
   - Go to "Manage Stock"
   - Find the same book
   - Verify "available" count increased correctly

## Common Issues and Solutions

### Issue 1: Stock Decreases But Doesn't Increase on Return

**Symptoms:**
- Issuing works (stock goes down)
- Returning doesn't work (stock stays low)

**Check Console For:**
```
📦 ========== RETURNING TRANSACTION ==========
...
❌ ERROR: Transaction not found
```
OR
```
📖 Book Title:
   - Current available: 6
   - Returning: 2
   - Will become: 8
✅ Batch update queued: increment availableCopies by 2
📦 Committing batch...
✅ ========== TRANSACTION RETURNED SUCCESSFULLY ==========
```

**If logs show success but UI doesn't update:**
- The Firestore update is working
- Issue is with real-time listener
- Check if BookProvider is listening to correct library

### Issue 2: Wrong Book ID

**Symptoms:**
- Console shows error: "Book not found"

**Check Console For:**
```
❌ ERROR: Book Book Title (lib123_abc456) not found in Firestore
```

**Solution:**
- The bookId in the transaction doesn't match Firestore
- Check how book IDs are generated (should be `libraryId_volumeId`)
- Verify book exists in Firestore with that exact ID

### Issue 3: Stock Goes Negative

**Symptoms:**
- Available copies shows negative number

**Check Console For:**
```
📖 Book Title:
   - Current available: 1
   - Borrowing: 2
❌ ERROR: Insufficient stock for Book Title
```

**If this check is bypassed:**
- There's a race condition
- Multiple transactions happening simultaneously
- Need to add Firestore security rules to prevent negative stock

### Issue 4: UI Not Updating

**Symptoms:**
- Console shows successful update
- Firestore shows correct numbers
- UI still shows old numbers

**Possible Causes:**

1. **BookProvider not listening to correct library:**
   - Check if `listenToLibraryBooks()` was called
   - Verify libraryId matches

2. **Widget not watching provider:**
   - Should use `context.watch<BookProvider>()`
   - Not `context.read<BookProvider>()`

3. **Filtering issue:**
   - Stock Management screen filters by libraryId
   - Verify book has correct libraryId field

## Verification Checklist

After issuing a book, verify:
- [ ] Console shows "TRANSACTION CREATED SUCCESSFULLY"
- [ ] Console shows correct "Will become" number
- [ ] Firestore console shows updated availableCopies
- [ ] Stock Management screen shows updated number
- [ ] Reader's transaction list shows the borrow

After returning a book, verify:
- [ ] Console shows "TRANSACTION RETURNED SUCCESSFULLY"
- [ ] Console shows correct "Will become" number (increased)
- [ ] Firestore console shows updated availableCopies
- [ ] Stock Management screen shows updated number
- [ ] Transaction status changed to "returned"

## Direct Firestore Check

If UI is not updating but you want to verify the data is correct:

1. **Open Firebase Console:**
   - Go to https://console.firebase.google.com/
   - Select your project: `lib-management-d6460`

2. **Check Books Collection:**
   - Go to Firestore Database
   - Open `books` collection
   - Find your book document
   - Check `availableCopies` and `totalCopies` fields
   - These should match what the console logs show

3. **Check Transactions Collection:**
   - Open `borrow_transactions` collection
   - Find your transaction
   - Verify `status` field (should be "active" or "returned")
   - Check `items` array has correct bookId and quantity

## Next Steps

1. Run the app with the enhanced logging
2. Perform a complete borrow → return cycle
3. Copy the console output
4. Share the logs so we can see exactly what's happening
5. Check Firestore console to verify data is correct

The logs will show us:
- If the batch operations are executing
- What the stock numbers are before and after
- If there are any errors during the process
- Whether the issue is with data updates or UI rendering
