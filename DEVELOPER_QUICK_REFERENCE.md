# 🚀 Developer Quick Reference - QR Code System

## Quick Links

| Feature | File Location | Line |
|---------|--------------|------|
| User QR Display | `lib/features/profile/screens/profile_screen.dart` | ~300 |
| Issue Book Screen | `lib/features/borrow/screens/issue_return_screen.dart` | ~1 |
| Return Book Screen | `lib/features/borrow/screens/issue_return_screen.dart` | ~600 |
| Borrow QR Display | `lib/features/borrow/screens/my_borrows_screen.dart` | ~200 |
| Reservation QR | `lib/features/reservations/screens/my_reservations_screen.dart` | ~150 |
| QR Scanner Component | `lib/features/borrow/screens/issue_return_screen.dart` | ~960 |

---

## QR Data Formats

### User QR
```dart
String qrData = 'LIB_USER:${user.uid}:${user.email}';
```

### Borrow QR
```dart
String qrData = 'LIB_BORROW:${borrow.id}:${borrow.userId}';
```

### Reservation QR
```dart
String qrData = 'LIB_RESERVE:${reservation.id}:${reservation.bookId}:${reservation.userId}:${reservation.copies}';
```

---

## Key Functions

### Generate QR Code
```dart
QrImageView(
  data: qrData,
  version: QrVersions.auto,
  size: 200,
  backgroundColor: Colors.white,
  foregroundColor: const Color(0xFF1E3A8A),
)
```

### Scan QR Code
```dart
final result = await Navigator.push<String>(
  context,
  MaterialPageRoute(
    builder: (_) => const _QRScannerScreen(title: 'Scan QR Code'),
  ),
);
```

### Parse User QR
```dart
if (result.startsWith('LIB_USER:')) {
  final parts = result.split(':');
  final uid = parts[1];
  final email = parts.sublist(2).join(':');
  // Fetch user from Firestore
}
```

### Parse Borrow QR
```dart
if (result.startsWith('LIB_BORROW:')) {
  final parts = result.split(':');
  final borrowId = parts[1];
  final userId = parts[2];
  // Find borrow record
}
```

### Parse Reservation QR
```dart
if (result.startsWith('LIB_RESERVE:')) {
  final parts = result.split(':');
  final reservationId = parts[1];
  final bookId = parts[2];
  final userId = parts[3];
  final copies = int.tryParse(parts[4]) ?? 1;
  // Auto-fill issue form
}
```

---

## Common Operations

### Issue a Book
```dart
await context.read<BorrowProvider>().issueBook(
  bookId: book.id,
  bookTitle: book.title,
  bookThumbnail: book.thumbnail,
  userId: user.uid,
  userName: user.name,
  libraryId: libraryId,
  issuedBy: librarianUid,
  borrowDays: 14,
);
```

### Return a Book
```dart
await context.read<BorrowProvider>().returnBook(
  borrowId,
  bookId,
);
```

### Fulfill Reservation
```dart
await context.read<ReservationProvider>().fulfillReservation(
  reservationId,
);
```

---

## Error Handling

### Invalid QR Format
```dart
if (!result.startsWith('LIB_')) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Invalid QR code.'),
      backgroundColor: AppColors.error,
    ),
  );
  return;
}
```

### User Not Found
```dart
final user = await _repo.getUser(uid);
if (user == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('User not found.'),
      backgroundColor: AppColors.error,
    ),
  );
  return;
}
```

### Book Not Available
```dart
if (book.availableCopies <= 0) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Book is not available.'),
      backgroundColor: AppColors.error,
    ),
  );
  return;
}
```

---

## Testing Commands

### Run App
```bash
flutter run
```

### Run Tests
```bash
flutter test
```

### Check for Errors
```bash
flutter analyze
```

### Format Code
```bash
flutter format lib/
```

---

## Debugging Tips

### Enable QR Scanner Logs
```dart
debugPrint('QR Scanned: $result');
```

### Check Firestore Data
```dart
debugPrint('Borrow created: ${borrow.toJson()}');
```

### Monitor Provider State
```dart
debugPrint('Active borrows: ${borrowProvider.activeBorrows.length}');
```

---

## Common Issues & Solutions

### Issue: QR Scanner Not Working
**Solution**: Check camera permissions in AndroidManifest.xml and Info.plist

### Issue: QR Code Not Displaying
**Solution**: Ensure qr_flutter package is imported and data is not empty

### Issue: Borrow Not Creating
**Solution**: Check Firestore rules and user permissions

### Issue: Stock Not Updating
**Solution**: Verify BookRepository.updateStock() is called

---

## Package Versions

```yaml
qr_flutter: ^4.1.0
mobile_scanner: ^6.0.2
provider: ^6.1.5
cloud_firestore: ^5.0.0
```

---

## Firestore Collections

### borrows
```
{
  id: auto-generated
  userId: string
  bookId: string
  libraryId: string
  borrowDate: timestamp
  dueDate: timestamp
  returnDate: timestamp?
  status: string
  fineAmount: number
}
```

### books
```
{
  id: composite (libraryId_volumeId)
  totalCopies: number
  availableCopies: number
  libraryId: string
}
```

### reservations
```
{
  id: auto-generated
  userId: string
  bookId: string
  libraryId: string
  status: string
  copies: number
}
```

---

## State Management

### Listen to Borrows
```dart
context.read<BorrowProvider>().listenToUserBorrows(userId);
```

### Watch Provider
```dart
final borrowProvider = context.watch<BorrowProvider>();
final borrows = borrowProvider.activeBorrows;
```

### Read Provider (No Rebuild)
```dart
final success = await context.read<BorrowProvider>().issueBook(...);
```

---

## UI Components

### Show QR Dialog
```dart
showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
    title: const Text('QR Code'),
    content: QrImageView(data: qrData, size: 200),
    actions: [
      ElevatedButton(
        onPressed: () => Navigator.pop(ctx),
        child: const Text('Done'),
      ),
    ],
  ),
);
```

### Show Success Message
```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Book issued successfully!'),
    backgroundColor: AppColors.success,
    behavior: SnackBarBehavior.floating,
  ),
);
```

---

## Performance Tips

1. Use `const` constructors where possible
2. Dispose controllers in `dispose()`
3. Cancel stream subscriptions
4. Use `ListView.builder` for long lists
5. Cache QR images if needed

---

## Security Checklist

- [x] Validate QR format before processing
- [x] Check user permissions before operations
- [x] Verify book availability before issue
- [x] Validate borrow exists before return
- [x] Handle expired reservations
- [x] Sanitize user inputs

---

## Deployment Checklist

- [ ] Test on physical devices
- [ ] Test camera permissions
- [ ] Test QR scanning in different lighting
- [ ] Test with multiple users
- [ ] Test network error handling
- [ ] Test offline behavior
- [ ] Update Firestore security rules
- [ ] Enable Firebase App Check
- [ ] Set up error logging
- [ ] Configure analytics

---

## Support & Resources

- Flutter Docs: https://flutter.dev/docs
- QR Flutter: https://pub.dev/packages/qr_flutter
- Mobile Scanner: https://pub.dev/packages/mobile_scanner
- Firebase: https://firebase.google.com/docs

---

**Last Updated**: 2024
**Status**: Production Ready ✅
