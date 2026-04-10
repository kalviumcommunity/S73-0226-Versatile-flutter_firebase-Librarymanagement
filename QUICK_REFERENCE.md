# Quick Reference - Multi-Book Transaction System

## 🎯 What Changed

### For Librarians
- **Borrow Tab**: Now uses new multi-book transaction screen
- **Workflow**: Scan reader QR → Select multiple books → Issue transaction
- **Return**: Scan transaction QR → Confirm return (with fine if overdue)

### For Readers
- **Borrows Tab**: Shows transaction-based borrows (replaces old "Saved" tab)
- **QR Codes**: Can show transaction QR for easy returns
- **History**: View all past transactions

### For Admins
- **No Changes**: Admin functionality unchanged
- **QR Codes**: Admins do NOT have QR codes (reader-only feature)

## 📱 User Flows

### Librarian: Issue Books
```
1. Tap "Borrow" tab
2. Tap "Scan Reader QR Code"
3. Scan reader's QR
4. Tap "Add Book"
5. Select book and quantity
6. Repeat for more books
7. Select borrow period
8. Tap "Issue Books"
```

### Librarian: Return Books
```
1. Tap "Borrow" tab (or dedicated return screen)
2. Tap "Scan QR Code"
3. Scan transaction QR from reader
4. Review details and fine
5. Tap "Confirm Return"
```

### Reader: View Transactions
```
1. Tap "Borrows" tab
2. View active transactions
3. Tap "Show QR for Return"
4. Show QR to librarian
```

## 🔑 Key Features

| Feature | Description |
|---------|-------------|
| **Multi-Book Borrowing** | Issue multiple books in one transaction |
| **Quantity Selection** | Borrow multiple copies of same book |
| **QR Code Scanning** | Fast reader and transaction identification |
| **Stock Validation** | Prevents over-borrowing |
| **Automatic Fines** | ₹2 per day for overdue books |
| **Transaction History** | Complete borrow/return records |
| **Real-time Updates** | Instant synchronization across devices |

## 📊 QR Code Formats

| Type | Format | Usage |
|------|--------|-------|
| **User QR** | `LIB_USER:<uid>:<email>` | Reader identification |
| **Transaction QR** | `LIB_TRANSACTION:<id>` | Return processing |

## 🎨 UI Components

### Librarian Borrow Screen
- Reader identification (QR scan or email search)
- Book selection with quantity picker
- Borrow period selector (7, 14, 21, 30 days)
- Selected books list with remove option
- Issue confirmation button

### Librarian Return Screen
- QR scanner (primary)
- Manual search button (fallback)
- Transaction details display
- Fine calculation (if overdue)
- Return confirmation dialog

### Reader Transaction Screen
- Active transactions section
- History section (returned)
- Transaction cards with book details
- "Show QR for Return" button
- Status badges (ACTIVE, OVERDUE, RETURNED)

## 🔒 Business Rules

1. **QR Codes**: Only readers have QR codes
2. **Stock**: Cannot go negative (validation enforced)
3. **Fines**: ₹2 per day overdue
4. **Transactions**: Multiple books per transaction
5. **Returns**: QR scanning is primary method
6. **Roles**: Only readers can borrow books

## 📁 File Locations

### New Files
```
lib/features/borrow/
├── models/borrow_transaction_model.dart
├── repository/borrow_transaction_repository.dart
├── providers/borrow_transaction_provider.dart
└── screens/
    ├── librarian_borrow_screen.dart
    ├── librarian_return_screen.dart
    └── reader_transactions_screen.dart
```

### Modified Files
```
lib/shared/widgets/
├── animated_splash_screen.dart (provider registration)
├── librarian_main_screen.dart (navigation update)
└── reader_main_screen.dart (navigation update)

lib/features/profile/screens/
└── profile_screen.dart (QR enforcement)
```

## 🐛 Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| QR not scanning | Check camera permissions |
| Stock validation error | Reduce quantity or select different book |
| Transaction not found | Ensure QR code is for active transaction |
| Fine not calculating | Check due date is in the past |
| Books not appearing | Verify library has books in stock |

## 🧪 Quick Test

1. **Create Transaction**
   - Login as librarian
   - Scan reader QR
   - Add 2-3 books
   - Issue transaction

2. **View Transaction**
   - Login as reader
   - Check "Borrows" tab
   - Verify books listed
   - Show transaction QR

3. **Return Transaction**
   - Login as librarian
   - Scan transaction QR
   - Confirm return
   - Verify stock restored

## 📞 Need Help?

- **Implementation Details**: See `TRANSACTION_SYSTEM_IMPLEMENTATION.md`
- **Testing Guide**: See `TESTING_GUIDE.md`
- **Full Summary**: See `IMPLEMENTATION_SUMMARY.md`

## ✅ Status

**System Status**: ✅ Complete and Production-Ready

**Last Updated**: March 11, 2026

**Version**: 1.0.0
