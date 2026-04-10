# Browse Books UI Fixes

## Issues Fixed

### 1. Pixel Overflow in "My Libraries" Toggle
**Problem**: The SegmentedButton was wrapped in a Row with Expanded, causing pixel overflow on smaller screens.

**Solution**: Removed the unnecessary Row wrapper and let the SegmentedButton take full width naturally. Also reduced font size to 13px for better fit.

**Files Modified**:
- `lib/features/books/screens/browse_books_screen.dart`

### 2. Missing Library Name Display
**Problem**: Book cards in "My Libraries" mode didn't show which library each book belongs to.

**Solution**: 
- Added optional `libraryName` parameter to `BookCard` widget
- Display library name with library icon below the author name
- Fetch library name from `LibraryProvider` using the book's `libraryId`
- Library name is shown in primary color with icon for visual distinction

**Files Modified**:
- `lib/core/widgets/cards/book_card.dart` - Added libraryName parameter and display logic
- `lib/features/books/screens/browse_books_screen.dart` - Pass library name to BookCard

## Visual Changes

### BookCard Layout (when libraryName is provided):
```
┌─────────────────┐
│  Book Cover     │
│   (3:4 ratio)   │
└─────────────────┘
Book Title (2 lines max)
Author Name (1 line)
📚 Library Name (1 line) ← NEW
[Availability Badge]
```

## Testing

To see the changes:
1. Do a full app restart (not hot reload)
2. Navigate to Browse Books screen
3. Verify:
   - "My Libraries" / "All Libraries" toggle fits without overflow
   - Each book card shows the library name below the author
   - Library name has a library icon and is in primary color
   - Text truncates properly if library name is too long

## Technical Details

- Library name lookup uses `LibraryProvider.libraries` to find library by ID
- Uses `firstOrNull` for safe null handling
- Library name only displays when `libraryId` exists and library is found
- Responsive text with ellipsis overflow handling
