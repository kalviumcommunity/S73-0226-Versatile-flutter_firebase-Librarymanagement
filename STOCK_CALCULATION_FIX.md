# Stock Calculation & Navigation Fixes

## Issues Fixed

### 1. Reader "My Borrows" Navigation
**Problem:** The "My Borrows" button on the reader home screen was navigating to the old `MyBorrowsScreen` instead of the new transaction-based screen.

**Solution:** Updated `reader_home_screen.dart` to navigate to `ReaderTransactionsScreen` instead.

**Changes:**
- Updated import from `my_borrows_screen.dart` to `reader_transactions_screen.dart`
- Changed navigation to use the new screen

### 2. Stock Calculation Debugging
**Problem:** Stock not being added back correctly on return (reported by user).

**Investigation:** Added debug logging to track stock updates during borrow and return operations.

**Debug Logs Added:**
```dart
// In createTransaction:
print('📦 Creating transaction for user: ${transaction.userEmail}');
print('📚 Books to borrow:');
print('  📖 ${item.bookTitle}: Current stock = $currentStock, Borrowing = ${item.quantity}');
print('  ✅ Will deduct ${item.quantity} copies from book: ${item.bookId}');

// In returnTransaction:
print('📦 Returning transaction: $transactionId');
print('📚 Books to return:');
print('  ✅ Restoring ${item.quantity} copies to book: ${item.bookId}');
```

**How to Verify:**
1. Open the app and check the console/logs
2. Issue books to a reader
3. Check the logs - you should see:
   - Current stock before borrowing
   - Quantity being deducted
   - Confirmation of deduction
4. Return the books
5. Check the logs - you should see:
   - Books being returned
   - Quantity being restored
   - Confirmation of restoration

## Stock Update Logic

### Borrow (Deduct Stock)
```dart
batch.update(bookRef, {
  'availableCopies': FieldValue.increment(-item.quantity),
});
```

### Return (Restore Stock)
```dart
batch.update(bookRef, {
  'availableCopies': FieldValue.increment(item.quantity),
});
```

Both operations use `FieldValue.increment()` which is atomic and handles concurrent updates correctly.

## Testing Steps

### Test Stock Deduction
1. Login as librarian
2. Note the current stock of a book (e.g., 10 copies)
3. Issue 2 copies to a reader
4. Check the book stock - should be 8 copies
5. Check console logs for confirmation

### Test Stock Restoration
1. Login as librarian
2. Scan the transaction QR from reader
3. Confirm return
4. Check the book stock - should be back to 10 copies
5. Check console logs for confirmation

### Test Multiple Books
1. Issue multiple books with different quantities:
   - Book A: 2 copies
   - Book B: 1 copy
   - Book C: 3 copies
2. Verify each book's stock is reduced correctly
3. Return the transaction
4. Verify each book's stock is restored correctly

## Common Issues & Solutions

### Issue: Stock not updating in UI
**Cause:** UI not refreshing after Firestore update
**Solution:** The app uses real-time streams, so updates should be automatic. If not:
1. Check if the book provider is listening to the correct library
2. Verify Firestore security rules allow updates
3. Check console for any errors

### Issue: Stock goes negative
**Cause:** Validation not working
**Solution:** The code validates stock before borrowing:
```dart
if (currentStock < item.quantity) {
  throw Exception('Insufficient stock...');
}
```
This should prevent negative stock.

### Issue: Stock not restored on return
**Cause:** Possible Firestore permission issue or batch commit failure
**Solution:** 
1. Check console logs for errors
2. Verify Firestore rules allow updates to books collection
3. Check if batch.commit() completes successfully

## Firestore Security Rules

Ensure your `firestore.rules` includes:

```javascript
// ── Books ──
match /books/{bookId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null;
}

// ── Borrow Transactions ──
match /borrow_transactions/{transactionId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null;
}
```

## Files Modified

1. **lib/features/borrow/repository/borrow_transaction_repository.dart**
   - Added debug logging to `createTransaction()`
   - Added debug logging to `returnTransaction()`

2. **lib/features/books/screens/reader_home_screen.dart**
   - Changed import from `my_borrows_screen.dart` to `reader_transactions_screen.dart`
   - Updated navigation to use `ReaderTransactionsScreen`

## Next Steps

1. **Run the app** and test borrow/return operations
2. **Check console logs** to verify stock updates are happening
3. **Monitor Firestore** directly to see if the `availableCopies` field is updating
4. **Report findings** - if stock still not updating correctly, check:
   - Console logs for errors
   - Firestore console for actual data
   - Network tab for failed requests

## Expected Console Output

### When Borrowing:
```
📦 Creating transaction for user: reader@example.com
📚 Books to borrow:
  - Book Title 1: 2 copies
  - Book Title 2: 1 copy
  📖 Book Title 1: Current stock = 10, Borrowing = 2
  ✅ Will deduct 2 copies from book: lib123_abc456
  📖 Book Title 2: Current stock = 5, Borrowing = 1
  ✅ Will deduct 1 copies from book: lib123_def789
✅ Transaction created successfully: trans_xyz123
```

### When Returning:
```
📦 Returning transaction: trans_xyz123
📚 Books to return:
  - Book Title 1: 2 copies
  - Book Title 2: 1 copy
  ✅ Restoring 2 copies to book: lib123_abc456
  ✅ Restoring 1 copies to book: lib123_def789
✅ Transaction returned successfully
```

## Status

✅ Navigation fixed - Reader "My Borrows" now goes to new transactions screen
✅ Debug logging added - Can now track stock updates in console
⏳ Awaiting user testing - Need to verify stock calculations work correctly

If stock calculations still don't work after these changes, the logs will help identify the exact issue!
