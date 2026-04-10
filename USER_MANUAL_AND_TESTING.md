# 📖 User Manual & Testing Guide

## Table of Contents
1. [User Guide](#user-guide)
2. [Librarian Guide](#librarian-guide)
3. [Testing Scenarios](#testing-scenarios)
4. [Troubleshooting](#troubleshooting)

---

# User Guide

## For Library Members (Readers)

### Getting Your QR Code

1. **Open the App**
   - Launch LibraryOne app
   - Sign in with your account

2. **Navigate to Profile**
   - Tap the "Profile" tab at the bottom

3. **View Your QR Code**
   - Tap the "My QR Code" button
   - Your unique QR code will appear
   - This QR contains your user ID and email

4. **When to Use**
   - Show this QR to the librarian when borrowing books
   - Faster than manual email entry
   - Works even without internet (QR is generated locally)

---

### Borrowing a Book

#### Method 1: Direct Issue (At Library)
1. Find the book you want to borrow
2. Go to the librarian
3. Show your QR code (Profile → My QR Code)
4. Librarian scans your QR
5. Librarian selects the book
6. Book is issued to you
7. Check "My Borrows" tab to see your borrowed book

#### Method 2: Reserve First, Then Issue
1. **Reserve the Book**
   - Browse books in the app
   - Tap "Reserve" on desired book
   - Choose number of copies
   - Reservation created

2. **Show Reservation QR**
   - Go to "My Reservations" tab
   - Tap "QR" button on your reservation
   - Show this QR to librarian

3. **Quick Issue**
   - Librarian scans reservation QR
   - All details auto-filled
   - Book issued instantly
   - Reservation marked as fulfilled

---

### Returning a Book

1. **Open My Borrows**
   - Tap "My Borrows" tab
   - View your active borrows

2. **Get Return QR**
   - Find the book you want to return
   - Tap the "QR" button next to it
   - Your borrow QR code appears

3. **Show to Librarian**
   - Go to the library
   - Show the borrow QR to librarian
   - Librarian scans it

4. **Return Processed**
   - Librarian confirms return
   - If overdue, fine amount is shown
   - Book marked as returned
   - Stock updated automatically

---

### Checking Your Borrows

1. **Active Borrows Tab**
   - See all currently borrowed books
   - View due dates
   - Check days remaining
   - See overdue fines (if any)
   - Access borrow QR codes

2. **History Tab**
   - View all returned books
   - See return dates
   - Check past fines paid

---

### Managing Reservations

1. **View Reservations**
   - Tap "My Reservations" tab
   - See all pending reservations

2. **Reservation Status**
   - **Pending**: Waiting for librarian to fulfill
   - **Fulfilled**: Book has been issued
   - **Cancelled**: You cancelled it
   - **Expired**: Reservation time expired

3. **Cancel Reservation**
   - Tap "Cancel" on any pending reservation
   - Confirm cancellation
   - Reservation removed

---

# Librarian Guide

## Issue Book Workflow

### Setup
1. Open the app
2. Navigate to "Issue / Return" screen
3. Select "Issue Book" tab

---

### Method 1: Scan User QR

1. **Scan QR Code**
   - Tap "Scan QR Code" button
   - Camera opens
   - Point at user's QR code (from their profile)
   - QR scanned automatically

2. **User Details Loaded**
   - User name and email appear
   - Green checkmark confirms user found

3. **Select Book**
   - Tap "Select Book"
   - Modal sheet opens with available books
   - Scroll and find the book
   - Tap to select

4. **Choose Borrow Period**
   - Select: 7, 14, 21, or 30 days
   - Default is 14 days

5. **Issue Book**
   - Tap "Issue Book" button
   - Success message appears
   - Book issued
   - Stock decremented
   - User can see it in their "My Borrows"

---

### Method 2: Manual Email Search

1. **Enter Email**
   - Type user's email in the text field
   - Tap "Find" button

2. **User Found**
   - User details appear
   - Continue with book selection (same as Method 1)

---

### Method 3: Scan Reservation QR (Fastest)

1. **User Shows Reservation QR**
   - User opens "My Reservations"
   - Taps "QR" on their reservation
   - Shows QR to you

2. **Scan Reservation QR**
   - Tap "Scan QR Code"
   - Scan the reservation QR

3. **Auto-Filled**
   - User details loaded
   - Book pre-selected
   - Number of copies set
   - Banner shows "From reservation"

4. **Confirm and Issue**
   - Review details
   - Tap "Issue Book"
   - All copies issued at once
   - Reservation marked as fulfilled

---

## Return Book Workflow

### Method 1: Scan Borrow QR (Recommended)

1. **Open Returns Tab**
   - Navigate to "Issue / Return" screen
   - Select "Returns" tab

2. **Scan Borrow QR**
   - Tap "Scan Borrow QR to Return"
   - Camera opens
   - User shows their borrow QR
   - Scan the QR code

3. **Review Details**
   - Confirmation dialog appears
   - Shows:
     - Book title
     - Borrower name
     - Borrow date
     - Due date
     - Fine amount (if overdue)

4. **Confirm Return**
   - Review the information
   - Check fine amount
   - Tap "Confirm Return"

5. **Return Processed**
   - Book marked as returned
   - Return date saved
   - Fine recorded
   - Stock incremented
   - Success message shown

---

### Method 2: Manual Return from List

1. **View Active Borrows**
   - Returns tab shows all active borrows
   - Sorted by due date

2. **Find Borrow**
   - Scroll through the list
   - Find the specific borrow

3. **Tap Return**
   - Tap "Return" button on the borrow card
   - Same confirmation dialog appears

4. **Confirm**
   - Review details
   - Tap "Confirm Return"
   - Return processed

---

## Managing Active Borrows

### View All Active Borrows
- Returns tab shows real-time list
- See overdue books (red indicator)
- View fine amounts
- Sort by due date

### Overdue Books
- Highlighted in red
- Fine amount displayed
- ₹2 per day overdue
- Automatically calculated

### Search/Filter
- Use the list to find specific users
- Check book titles
- View due dates

---

# Testing Scenarios

## Test Case 1: User QR Generation

**Steps**:
1. Login as a reader
2. Go to Profile tab
3. Tap "My QR Code"

**Expected Result**:
- QR dialog appears
- QR code is visible
- User name displayed
- User email displayed
- Instructions shown

**Pass Criteria**: ✅ QR code displays correctly

---

## Test Case 2: Issue Book via User QR

**Steps**:
1. Login as librarian
2. Open Issue/Return → Issue tab
3. Tap "Scan QR Code"
4. Scan reader's user QR
5. Select a book
6. Choose 14 days
7. Tap "Issue Book"

**Expected Result**:
- User details loaded after scan
- Book selection works
- Issue succeeds
- Success message shown
- Book appears in reader's "My Borrows"
- Stock decremented by 1

**Pass Criteria**: ✅ Book issued successfully

---

## Test Case 3: Issue Book via Reservation QR

**Steps**:
1. Reader reserves a book (2 copies)
2. Reader shows reservation QR
3. Librarian scans reservation QR
4. Librarian taps "Issue Book"

**Expected Result**:
- User auto-filled
- Book auto-selected
- Copies set to 2
- "From reservation" banner shown
- 2 borrow records created
- Stock decremented by 2
- Reservation marked as fulfilled

**Pass Criteria**: ✅ Multiple copies issued from reservation

---

## Test Case 4: Return Book via Borrow QR

**Steps**:
1. Reader has an active borrow
2. Reader opens "My Borrows"
3. Reader taps "QR" on the borrow
4. Librarian scans borrow QR
5. Librarian confirms return

**Expected Result**:
- Borrow details shown in dialog
- Fine calculated if overdue
- Return confirmed
- Borrow marked as returned
- Stock incremented
- Success message shown

**Pass Criteria**: ✅ Book returned successfully

---

## Test Case 5: Overdue Fine Calculation

**Steps**:
1. Create a borrow with due date in the past
2. Return the book
3. Check fine amount

**Expected Result**:
- Fine = (days overdue) × ₹2
- Fine displayed in confirmation
- Fine saved in borrow record

**Pass Criteria**: ✅ Fine calculated correctly

---

## Test Case 6: Invalid QR Code

**Steps**:
1. Scan a random QR code (not from app)
2. Check error handling

**Expected Result**:
- Error message: "Invalid QR code"
- Red snackbar shown
- No crash
- Can try again

**Pass Criteria**: ✅ Error handled gracefully

---

## Test Case 7: User Not Found

**Steps**:
1. Enter non-existent email
2. Tap "Find"

**Expected Result**:
- Error message: "User not found"
- Red snackbar shown
- Can try again

**Pass Criteria**: ✅ Error handled gracefully

---

## Test Case 8: Book Out of Stock

**Steps**:
1. Try to issue a book with 0 available copies

**Expected Result**:
- Book not shown in selection list
- OR error message if attempted

**Pass Criteria**: ✅ Cannot issue unavailable books

---

## Test Case 9: Multiple Borrows

**Steps**:
1. Issue 3 different books to same user
2. Check "My Borrows"

**Expected Result**:
- All 3 books shown
- Each has unique QR code
- Each has correct due date
- Stock decremented for each

**Pass Criteria**: ✅ Multiple borrows work correctly

---

## Test Case 10: Reservation Expiry

**Steps**:
1. Create reservation
2. Wait for expiry time
3. Check status

**Expected Result**:
- Status changes to "Expired"
- Cannot be fulfilled
- Red indicator shown

**Pass Criteria**: ✅ Expiry handled correctly

---

# Troubleshooting

## QR Scanner Issues

### Problem: Camera Not Opening
**Solutions**:
- Check camera permissions in device settings
- Restart the app
- Grant camera permission when prompted

### Problem: QR Not Scanning
**Solutions**:
- Ensure good lighting
- Hold phone steady
- Clean camera lens
- Increase screen brightness of QR display
- Try manual entry as fallback

### Problem: Wrong QR Scanned
**Solutions**:
- Verify QR is from LibraryOne app
- Check QR format starts with "LIB_"
- Regenerate QR if corrupted

---

## Issue Book Problems

### Problem: User Not Found After Scan
**Solutions**:
- Verify user is registered
- Check user email is correct
- Try manual email search
- Ensure user account is active

### Problem: Book Not Available
**Solutions**:
- Check stock count
- Verify book belongs to correct library
- Ensure book not deleted
- Refresh book list

### Problem: Issue Button Disabled
**Solutions**:
- Ensure user is selected
- Ensure book is selected
- Check network connection
- Verify librarian permissions

---

## Return Book Problems

### Problem: Borrow Not Found
**Solutions**:
- Verify borrow is active (not already returned)
- Check borrow belongs to correct library
- Try manual return from list
- Refresh borrow list

### Problem: Fine Not Calculating
**Solutions**:
- Check due date is in the past
- Verify return date is set
- Refresh the screen
- Check borrow record in Firestore

### Problem: Stock Not Updating
**Solutions**:
- Check network connection
- Verify Firestore rules
- Wait a few seconds for sync
- Refresh book list

---

## General Issues

### Problem: App Crashes on QR Scan
**Solutions**:
- Update to latest app version
- Clear app cache
- Reinstall app
- Check device compatibility

### Problem: Data Not Syncing
**Solutions**:
- Check internet connection
- Verify Firebase is online
- Check Firestore rules
- Try logging out and back in

### Problem: QR Code Not Displaying
**Solutions**:
- Check data is not empty
- Verify qr_flutter package installed
- Restart app
- Clear app cache

---

## Contact Support

If issues persist:
1. Note the error message
2. Take screenshots
3. Check app version
4. Contact system administrator
5. Provide user ID and timestamp

---

## Best Practices

### For Users
- Keep QR code screen brightness high
- Hold phone steady when showing QR
- Check "My Borrows" regularly
- Return books before due date
- Cancel unused reservations

### For Librarians
- Verify user identity before issuing
- Double-check book selection
- Confirm fine amounts with users
- Keep scanner clean
- Use manual fallback when needed

---

## Performance Tips

- Close unused apps for better camera performance
- Ensure good lighting for QR scanning
- Keep app updated
- Clear cache periodically
- Use Wi-Fi for faster syncing

---

## Security Notes

- Never share your QR code screenshots
- QR codes are user-specific
- Librarians verify identity before issuing
- All actions are logged
- Report suspicious activity

---

**Version**: 1.0
**Last Updated**: 2024
**Status**: Production Ready ✅

