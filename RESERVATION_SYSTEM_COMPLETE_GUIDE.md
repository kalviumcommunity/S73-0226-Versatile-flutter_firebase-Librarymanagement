# Complete Reservation System Implementation Guide

## Overview
This document provides a complete implementation guide for the Library Management System's Reservation feature. The system allows readers to reserve up to 3 books for 3 days, with QR-based collection by librarians.

## Architecture Summary

### 1. Data Models
- **Reservation**: Main reservation entity with multiple books
- **ReservationItem**: Individual book items within a reservation
- **ReservationStatus**: Enum (pending, collected, expired)

### 2. Key Features Implemented
✅ Multi-book reservations (up to 3 books total)
✅ 3-day validity period with automatic expiry
✅ QR code generation and scanning
✅ Stock management (reserved vs borrowed vs available)
✅ Seamless conversion to borrow transactions
✅ Complete UI for readers and librarians

## File Structure

```
lib/features/reservations/
├── models/
│   └── reservation_model.dart              # Updated model with new requirements
├── repository/
│   └── reservation_repository.dart         # Updated with stock management
├── providers/
│   └── reservation_provider.dart           # Updated provider logic
├── services/
│   └── reservation_expiry_service.dart     # Automatic expiry handling
├── screens/
│   ├── reader_reservation_screen.dart      # New: Reader reservation interface
│   ├── librarian_reservation_scanner.dart  # New: Librarian QR scanner
│   ├── my_reservations_screen.dart         # Updated: Reader's reservations
│   ├── manage_reservations_screen.dart     # Updated: Librarian management
│   └── widgets/
│       ├── reservation_qr_dialog.dart      # QR code display
│       └── reservation_collection_dialog.dart # Collection processing
└── widgets/
    └── book_reservation_button.dart        # Reusable reservation button
```

## Integration Steps

### 1. Update Main App
Add the expiry service to your main app:

```dart
// In main.dart or app initialization
import 'package:your_app/features/reservations/services/reservation_expiry_service.dart';

void main() {
  runApp(MyApp());
  
  // Start reservation expiry service
  ReservationExpiryService().start();
}
```

### 2. Add to Navigation
Update your navigation to include reservation screens:

```dart
// For readers
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ReaderReservationScreen(),
  ),
);

// For librarians
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const LibrarianReservationScanner(),
  ),
);
```

### 3. Add Reservation Button to Book Details
In your book detail screens, add the reservation button:

```dart
import 'package:your_app/features/reservations/widgets/book_reservation_button.dart';

// In your book detail widget
BookReservationButton(
  book: bookModel,
  onReserved: () {
    // Refresh book data or show success message
  },
)
```

### 4. Update Book Model Usage
Ensure your BookModel includes the new stock fields:
- `totalCopies`
- `borrowedStock` 
- `reservedStock`
- `availableCopies` (computed property)

### 5. Provider Registration
Make sure ReservationProvider is registered in your provider tree:

```dart
MultiProvider(
  providers: [
    // ... other providers
    ChangeNotifierProvider(create: (_) => ReservationProvider()),
  ],
  child: MyApp(),
)
```

## QR Code Format

The system uses this QR format for reservations:
```
RESERVATION:<reservationId>:<userId>
```

Example: `RESERVATION:abc123def456:user789xyz`

## Database Schema

### Firestore Collections

#### reservations
```json
{
  "id": "auto-generated",
  "userId": "string",
  "userName": "string", 
  "userEmail": "string",
  "libraryId": "string",
  "items": [
    {
      "bookId": "string",
      "bookTitle": "string",
      "bookThumbnail": "string?",
      "quantity": "number"
    }
  ],
  "reservationDate": "timestamp",
  "expiryDate": "timestamp", 
  "status": "pending|collected|expired",
  "collectedDate": "timestamp?"
}
```

#### books (updated fields)
```json
{
  // ... existing fields
  "totalCopies": "number",
  "borrowedStock": "number", 
  "reservedStock": "number"
  // availableCopies = totalCopies - borrowedStock - reservedStock
}
```

## Business Logic

### Reservation Limits
- Maximum 3 books per user across all pending reservations
- Can be same book (3x) or different books (1+1+1)
- Validation happens before creation

### Stock Management
- **Available Stock** = Total - Borrowed - Reserved
- **When Reserved**: `reservedStock += quantity`
- **When Collected**: `reservedStock -= quantity`, `borrowedStock += quantity`  
- **When Expired**: `reservedStock -= quantity`

### Expiry Logic
- Reservations expire after 3 days
- Automatic processing runs every hour
- Manual processing available via service
- Expired reservations remain as history

## User Workflows

### Reader Workflow
1. **Browse & Reserve**
   - Search books in reservation screen
   - Select quantities (max 3 total)
   - Create reservation
   - Get QR code

2. **Collection**
   - Show QR to librarian
   - Librarian scans and processes
   - Books move to borrowed status
   - Reservation marked as collected

### Librarian Workflow
1. **QR Scanning**
   - Open reservation scanner
   - Scan reader's QR code
   - Review reservation details
   - Set due date and issue books

2. **Manual Processing**
   - View pending reservations
   - Process without QR scanning
   - Same collection flow

## Error Handling

### Common Scenarios
- **Insufficient Stock**: Check available copies before reservation
- **Limit Exceeded**: Validate total pending reservations
- **Expired QR**: Check expiry date before processing
- **Invalid QR**: Validate format and reservation existence

### Error Messages
- "Maximum 3 books can be reserved at once"
- "You currently have X reserved books"
- "Insufficient stock available"
- "Reservation has expired"
- "Invalid QR code"

## Testing Checklist

### Reader Tests
- [ ] Can search and reserve books
- [ ] Quantity limits enforced (max 3)
- [ ] QR code generation works
- [ ] Reservation history displays correctly
- [ ] Status updates properly

### Librarian Tests  
- [ ] QR scanner works correctly
- [ ] Can process reservations manually
- [ ] Due date selection works
- [ ] Stock updates correctly
- [ ] Conversion to borrow transaction works

### System Tests
- [ ] Expiry service processes expired reservations
- [ ] Stock calculations are accurate
- [ ] Concurrent reservations handled properly
- [ ] Database transactions are atomic

## Performance Considerations

### Optimization Tips
1. **Indexing**: Create Firestore indexes for common queries
2. **Pagination**: Implement pagination for large reservation lists
3. **Caching**: Cache user's current reservation count
4. **Batch Operations**: Use Firestore batches for atomic updates

### Monitoring
- Track reservation creation/collection rates
- Monitor expiry processing performance
- Watch for stock inconsistencies
- Alert on failed QR scans

## Security Notes

### Access Control
- Readers can only see their own reservations
- Librarians can see all library reservations
- QR codes include user validation
- Stock updates require proper permissions

### Data Validation
- Validate reservation limits server-side
- Check stock availability before creation
- Verify QR code authenticity
- Ensure atomic stock updates

## Future Enhancements

### Possible Improvements
1. **Notifications**: Email/SMS reminders for expiring reservations
2. **Waitlists**: Queue system when books unavailable
3. **Flexible Expiry**: Different expiry periods per book type
4. **Bulk Operations**: Reserve multiple different books at once
5. **Analytics**: Reservation patterns and popular books

## Troubleshooting

### Common Issues
1. **Stock Mismatch**: Run stock reconciliation script
2. **Expired Not Processing**: Check expiry service status
3. **QR Not Scanning**: Verify camera permissions
4. **Reservation Not Found**: Check Firestore rules and indexes

### Debug Tools
- Enable debug logging in repository classes
- Use Firestore console to verify data
- Test QR generation/scanning separately
- Monitor provider state changes

## Conclusion

This reservation system provides a complete solution for book reservations with proper stock management, QR-based collection, and automatic expiry handling. The modular architecture allows for easy maintenance and future enhancements.

For support or questions, refer to the individual file documentation or the main project README.