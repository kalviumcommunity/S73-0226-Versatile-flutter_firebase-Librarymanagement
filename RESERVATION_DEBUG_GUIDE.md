# Reservation System Debug Guide

## Current Issues
1. Reservations not showing in reader portal
2. Reservations not showing in librarian portal

## Debug Steps

### Step 1: Check if reservations are being created
1. Go to book detail screen
2. Try to reserve a book
3. Check Firestore console for new reservation documents

### Step 2: Check provider initialization
1. Verify ReservationProvider is listening to correct streams
2. Check if user/library IDs are correct

### Step 3: Check data parsing
1. Verify reservation model parsing from Firestore
2. Check for null safety issues

## Potential Fixes

### Fix 1: Add debug logging to repository
Add console logs to track data flow

### Fix 2: Ensure proper user context
Make sure user authentication and library context is correct

### Fix 3: Check stream subscriptions
Verify that streams are properly subscribed and not cancelled

## Testing Checklist
- [ ] Can create reservation from book detail
- [ ] Reservation appears in Firestore
- [ ] Reader can see their reservations
- [ ] Librarian can see pending reservations
- [ ] QR code generation works
- [ ] QR code scanning works