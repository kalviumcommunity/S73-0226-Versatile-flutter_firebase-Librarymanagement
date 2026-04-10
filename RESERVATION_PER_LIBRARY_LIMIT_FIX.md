# Reservation Per-Library Limit Implementation

## Summary
Fixed the reservation system to enforce a 3-book limit PER LIBRARY instead of globally, and added library name display throughout the reservation flow.

## Changes Made

### 1. Reservation Provider (`lib/features/reservations/providers/reservation_provider.dart`)
- **Added `libraryName` parameter** to `createReservation()` method (required)
- **Updated validation logic** to check per-library limits using `getUserPendingReservationCountForLibrary()`
- **Updated `reserveBook()` legacy method** to include `libraryName` parameter
- **Changed error messages** to mention specific library names

### 2. Reservation Repository (`lib/features/reservations/repository/reservation_repository.dart`)
- **Added new method**: `getUserPendingReservationCountForLibrary(userId, libraryId)`
  - Counts pending reservations for a specific library only
  - Filters by both userId and libraryId
  - Excludes expired reservations

### 3. Reader Reservation Screen (`lib/features/reservations/screens/reader_reservation_screen.dart`)
- **Added library selection dropdown** as Step 1
- **Added per-library reservation counting** with debug logging
- **Updated UI to show**:
  - "X/3 reserved" badge for selected library
  - "Selected: X/Y available slots" in confirmation card
  - Warning when library limit is reached
  - Info banner: "You can reserve up to X more books from [Library Name]"
- **Passes `libraryName`** to `createReservation()` call
- **Filters books** by selected library only
- **Clears selections** when library changes

### 4. Reservation Card (`lib/core/widgets/cards/reservation_card.dart`)
- **Added library name display** with library icon
- Shows as: "Library: [Library Name]" in accent color

### 5. Reservation QR Dialog (`lib/features/reservations/screens/widgets/reservation_qr_dialog.dart`)
- **Added library name badge** at top of reservation details
- **Updated instructions** to mention specific library: "Show this QR code to the librarian at [Library Name]"

### 6. Librarian Scanner (`lib/features/reservations/screens/librarian_reservation_scanner.dart`)
- **Added library validation** before processing reservation
- **Checks** if reservation's libraryId matches librarian's libraryId
- **Shows error** if QR is for different library: "This reservation is for [Library Name]. You can only collect reservations for your library."

## How It Works

### For Readers:
1. Select a library from dropdown
2. System checks existing active reservations for THAT library only
3. Shows remaining slots (0-3) for that specific library
4. Can reserve up to 3 books per library
5. Can switch libraries and reserve 3 more books from another library

### For Librarians:
1. Scan reservation QR code
2. System validates reservation is for their library
3. If wrong library, shows error with library name
4. Can only process reservations for their own library

## Benefits
- Readers can reserve books from multiple libraries (3 per library)
- Clear visibility of which library each reservation is for
- Prevents cross-library confusion
- Librarians can only process their own library's reservations
- Better user experience with library-specific limits

## Testing
1. Join multiple libraries as a reader
2. Reserve 3 books from Library A
3. Switch to Library B - should show 3 available slots
4. Reserve books from Library B
5. Check Active tab - should show library names
6. Scan QR at wrong library - should show error
7. Scan QR at correct library - should work

## Files Modified
- `lib/features/reservations/providers/reservation_provider.dart`
- `lib/features/reservations/repository/reservation_repository.dart`
- `lib/features/reservations/screens/reader_reservation_screen.dart`
- `lib/core/widgets/cards/reservation_card.dart`
- `lib/features/reservations/screens/widgets/reservation_qr_dialog.dart`
- `lib/features/reservations/screens/librarian_reservation_scanner.dart`
