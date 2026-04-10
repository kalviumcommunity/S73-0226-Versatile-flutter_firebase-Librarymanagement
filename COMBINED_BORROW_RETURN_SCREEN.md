# Combined Borrow & Return Screen

## What Changed

The librarian "Borrow" tab now has **two sub-tabs**:
1. **Issue Books** - For issuing books to readers
2. **Return Books** - For returning books from readers

This provides a unified interface similar to the old system.

## Implementation

### New File Created
- `lib/features/borrow/screens/librarian_borrow_return_screen.dart`
  - Combined screen with TabBar
  - Two tabs: Issue and Return
  - Uses existing screens as tab content

### Modified Files
1. **librarian_borrow_screen.dart**
   - Added `showAppBar` parameter (default: true)
   - Can be used standalone or as tab content

2. **librarian_return_screen.dart**
   - Added `showAppBar` parameter (default: true)
   - Can be used standalone or as tab content

3. **librarian_main_screen.dart**
   - Updated to use `LibrarianBorrowReturnScreen`
   - Combines both issue and return functionality

## UI Structure

```
Librarian Main Screen
└── Bottom Navigation
    ├── Home
    ├── Manage
    ├── Borrow (NEW: Combined Screen)
    │   ├── Tab 1: Issue Books
    │   │   ├── Scan Reader QR
    │   │   ├── Select Books
    │   │   └── Issue Transaction
    │   └── Tab 2: Return Books
    │       ├── Scan Transaction QR
    │       ├── Manual Search
    │       └── Confirm Return
    └── Profile
```

## Features

### Issue Books Tab
- Scan reader QR code
- Manual email search
- Multi-book selection with quantities
- Borrow period selection
- Stock validation
- Transaction creation

### Return Books Tab
- Scan transaction QR code
- Manual search by email/name
- Transaction details display
- Fine calculation (if overdue)
- Return confirmation
- Stock restoration

## User Experience

### Before
- Only "Issue Books" screen
- No return functionality visible

### After
- Unified "Borrow & Return" screen
- Two tabs for easy switching
- Issue books in first tab
- Return books in second tab
- Seamless navigation between operations

## Visual Design

### Tab Bar
- Two tabs with icons
- Active tab highlighted in primary color
- Smooth tab switching animation
- Icons:
  - Issue: `add_circle_outline`
  - Return: `assignment_return_outlined`

### Tab Content
- Full-screen content for each tab
- No nested AppBars (clean UI)
- Consistent styling across tabs

## Code Quality

- ✅ No syntax errors
- ✅ No linting issues
- ✅ Reusable components
- ✅ Clean architecture
- ✅ Proper state management

## Testing

### Test Scenarios

1. **Tab Navigation**
   - [ ] Tap "Borrow" in bottom nav
   - [ ] See two tabs: "Issue Books" and "Return Books"
   - [ ] Tap "Issue Books" tab - shows issue interface
   - [ ] Tap "Return Books" tab - shows return interface
   - [ ] Switch between tabs smoothly

2. **Issue Books Tab**
   - [ ] Scan reader QR code
   - [ ] Add multiple books
   - [ ] Issue transaction
   - [ ] Verify success

3. **Return Books Tab**
   - [ ] Scan transaction QR code
   - [ ] View transaction details
   - [ ] Confirm return
   - [ ] Verify success

4. **Tab State Preservation**
   - [ ] Add books in Issue tab
   - [ ] Switch to Return tab
   - [ ] Switch back to Issue tab
   - [ ] Verify selected books are still there

## Benefits

1. **Unified Interface** - Both operations in one place
2. **Easy Navigation** - Simple tab switching
3. **Consistent UX** - Similar to old system
4. **Clean Design** - No nested screens
5. **Efficient Workflow** - Quick access to both operations

## Migration from Old System

### Old Structure
```
IssueReturnScreen (single screen with sections)
```

### New Structure
```
LibrarianBorrowReturnScreen (tabbed interface)
├── LibrarianBorrowScreen (Issue tab)
└── LibrarianReturnScreen (Return tab)
```

## Deployment

The changes are ready to use:
1. Hot reload or restart the app
2. Login as librarian
3. Tap "Borrow" in bottom navigation
4. See the new tabbed interface

## Status

✅ **COMPLETE** - Combined screen implemented and integrated

## Next Steps

1. Test the tabbed interface
2. Verify both tabs work correctly
3. Ensure smooth tab switching
4. Test issue and return workflows
5. Gather user feedback

## Notes

- Both screens can still be used standalone if needed
- The `showAppBar` parameter controls whether they show their own AppBar
- When used as tabs, they don't show AppBars (cleaner UI)
- The combined screen provides the AppBar with tabs
