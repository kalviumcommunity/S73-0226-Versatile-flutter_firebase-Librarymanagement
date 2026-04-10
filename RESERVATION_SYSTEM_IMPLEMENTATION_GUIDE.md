# Reservation System - Complete Implementation Guide

## Overview
This guide provides a complete, step-by-step implementation of the Reservation System for the Library Management App.

## Architecture Summary

### Data Flow
```
Reader Reserves Books → reservedStock++ → QR Generated
↓ (3 days max)
Librarian Scans QR → Shows Reservation → Sets Due Date → Issue Books
↓
reservedStock-- → borrowedStock++ → Create BorrowTransaction
↓
Reservation Status = Collected (History)
Books appear in Borrowed Books
```

### Stock Calculation
```
availableStock = totalStock - borrowedStock - reservedStock
```

## Phase 1: Update Book Model (COMPLETED ✅)

The Book Model has been updated with:
- `borrowedStock` field
- `reservedStock` field
- `availableCopies` as computed property
- Updated serialization methods

## Phase 2: Create Reservation Models (COMPLETED ✅)

File: `lib/features/reservations/models/reservation_model.dart`

Contains:
- `ReservationStatus` enum (pending, collected, expired)
- `ReservationItem` class
- `Reservation` class with all required fields

## Phase 3: Create Reservation Repository

Create: `lib/features/reservations/repository/reservation_repository.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/reservation_model.dart';

class ReservationRepository {
  final FirebaseFirestore _firestore;

  ReservationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reservationsRef =>
      _firestore.collection('reservations');

  /// Create a new reservation
  Future<Reservation> createReservation(Reservation reservation) async {
    debugPrint('📚 Creating reservation for user: ${reservation.userEmail}');
    
    final batch = _firestore.batch();
    
    // Add reservation document
    final reservationRef = _reservationsRef.doc();
    batch.set(reservationRef, reservation.toJson());
    
    // Update reservedStock for each book
    for (final item in reservation.items) {
      final bookRef = _firestore.collection('books').doc(item.bookId);
      
      // Validate stock availability
      final bookDoc = await bookRef.get();
      if (!bookDoc.exists) {
        throw Exception('Book ${item.bookTitle} not found');
      }
      
      final bookData = bookDoc.data()!;
      final totalStock = bookData['totalCopies'] as int;
      final borrowedStock = bookData['borrowedStock'] as int? ?? 0;
      final reservedStock = bookData['reservedStock'] as int? ?? 0;
      final available = totalStock - borrowedStock - reservedStock;
      
      if (available < item.quantity) {
        throw Exception(
          'Insufficient stock for ${item.bookTitle}. Available: $available, Requested: ${item.quantity}'
        );
      }
      
      batch.update(bookRef, {
        'reservedStock': FieldValue.increment(item.quantity),
      });
      
      debugPrint('  ✅ Reserved ${item.quantity} copies of ${item.bookTitle}');
    }
    
    await batch.commit();
    debugPrint('✅ Reservation created: ${reservationRef.id}');
    
    return reservation.copyWith(id: reservationRef.id);
  }

  /// Get reservation by ID
  Future<Reservation?> getReservation(String reservationId) async {
    final doc = await _reservationsRef.doc(reservationId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Reservation.fromJson(doc.data()!, doc.id);
  }

  /// Stream of user's reservations
  Stream<List<Reservation>> userReservationsStream(String userId) {
    return _reservationsRef
        .where('userId', isEqualTo: userId)
        .orderBy('reservationDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Reservation.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Stream of pending reservations for a library
  Stream<List<Reservation>> pendingReservationsStream(String libraryId) {
    return _reservationsRef
        .where('libraryId', isEqualTo: libraryId)
        .where('status', isEqualTo: 'pending')
        .orderBy('reservationDate', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Reservation.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Convert reservation to borrow transaction
  Future<void> collectReservation({
    required String reservationId,
    required String transactionId,
    required int borrowDays,
  }) async {
    debugPrint('📚 Collecting reservation: $reservationId');
    
    final reservationDoc = await _reservationsRef.doc(reservationId).get();
    if (!reservationDoc.exists) {
      throw Exception('Reservation not found');
    }
    
    final reservation = Reservation.fromJson(reservationDoc.data()!, reservationDoc.id);
    
    if (reservation.status != ReservationStatus.pending) {
      throw Exception('Reservation is not pending');
    }
    
    final batch = _firestore.batch();
    
    // Update reservation status
    batch.update(_reservationsRef.doc(reservationId), {
      'status': 'collected',
      'collectedDate': Timestamp.fromDate(DateTime.now()),
    });
    
    // Update stock: reservedStock-- and borrowedStock++
    for (final item in reservation.items) {
      final bookRef = _firestore.collection('books').doc(item.bookId);
      batch.update(bookRef, {
        'reservedStock': FieldValue.increment(-item.quantity),
        'borrowedStock': FieldValue.increment(item.quantity),
      });
      debugPrint('  ✅ Moved ${item.quantity} copies from reserved to borrowed');
    }
    
    await batch.commit();
    debugPrint('✅ Reservation collected successfully');
  }

  /// Expire a reservation
  Future<void> expireReservation(String reservationId) async {
    debugPrint('📚 Expiring reservation: $reservationId');
    
    final reservationDoc = await _reservationsRef.doc(reservationId).get();
    if (!reservationDoc.exists) return;
    
    final reservation = Reservation.fromJson(reservationDoc.data()!, reservationDoc.id);
    
    if (reservation.status != ReservationStatus.pending) return;
    
    final batch = _firestore.batch();
    
    // Update reservation status
    batch.update(_reservationsRef.doc(reservationId), {
      'status': 'expired',
    });
    
    // Release reserved stock
    for (final item in reservation.items) {
      final bookRef = _firestore.collection('books').doc(item.bookId);
      batch.update(bookRef, {
        'reservedStock': FieldValue.increment(-item.quantity),
      });
      debugPrint('  ✅ Released ${item.quantity} copies of ${item.bookTitle}');
    }
    
    await batch.commit();
    debugPrint('✅ Reservation expired');
  }

  /// Check and expire old reservations
  Future<void> checkExpiredReservations(String libraryId) async {
    final now = DateTime.now();
    final snap = await _reservationsRef
        .where('libraryId', isEqualTo: libraryId)
        .where('status', isEqualTo: 'pending')
        .get();
    
    for (final doc in snap.docs) {
      final reservation = Reservation.fromJson(doc.data(), doc.id);
      if (reservation.isExpired) {
        await expireReservation(reservation.id);
      }
    }
  }
}
```

## Phase 4: Create Reservation Provider

Create: `lib/features/reservations/providers/reservation_provider.dart`

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/reservation_model.dart';
import '../repository/reservation_repository.dart';

class ReservationProvider extends ChangeNotifier {
  final ReservationRepository _repo;

  List<Reservation> _reservations = [];
  List<Reservation> get reservations => _reservations;

  List<Reservation> get pendingReservations =>
      _reservations.where((r) => r.status == ReservationStatus.pending).toList();

  List<Reservation> get collectedReservations =>
      _reservations.where((r) => r.status == ReservationStatus.collected).toList();

  List<Reservation> get expiredReservations =>
      _reservations.where((r) => r.status == ReservationStatus.expired).toList();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  StreamSubscription? _reservationsSub;

  ReservationProvider({ReservationRepository? repository})
      : _repo = repository ?? ReservationRepository();

  /// Listen to user's reservations
  void listenToUserReservations(String userId) {
    _reservationsSub?.cancel();
    _isLoading = true;
    notifyListeners();

    _reservationsSub = _repo.userReservationsStream(userId).listen(
      (list) {
        _reservations = list;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('📚 Reservations stream error: $e');
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Listen to pending reservations for library
  void listenToPendingReservations(String libraryId) {
    _reservationsSub?.cancel();
    _isLoading = true;
    notifyListeners();

    _reservationsSub = _repo.pendingReservationsStream(libraryId).listen(
      (list) {
        _reservations = list;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('📚 Pending reservations stream error: $e');
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Create a new reservation
  Future<Reservation?> createReservation({
    required String userId,
    required String userName,
    required String userEmail,
    required String libraryId,
    required List<ReservationItem> items,
  }) async {
    try {
      _error = null;
      
      // Validate total quantity (max 3)
      final totalQuantity = items.fold(0, (sum, item) => sum + item.quantity);
      if (totalQuantity > 3) {
        _error = 'Maximum 3 books can be reserved at once';
        notifyListeners();
        return null;
      }
      
      final now = DateTime.now();
      final reservation = Reservation(
        id: '',
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        libraryId: libraryId,
        items: items,
        reservationDate: now,
        expiryDate: now.add(const Duration(days: 3)),
        status: ReservationStatus.pending,
      );

      final result = await _repo.createReservation(reservation);
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Get reservation by ID
  Future<Reservation?> getReservation(String reservationId) async {
    try {
      _error = null;
      return await _repo.getReservation(reservationId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Collect reservation (convert to borrow)
  Future<bool> collectReservation({
    required String reservationId,
    required String transactionId,
    required int borrowDays,
  }) async {
    try {
      _error = null;
      await _repo.collectReservation(
        reservationId: reservationId,
        transactionId: transactionId,
        borrowDays: borrowDays,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Check and expire old reservations
  Future<void> checkExpiredReservations(String libraryId) async {
    try {
      await _repo.checkExpiredReservations(libraryId);
    } catch (e) {
      debugPrint('Error checking expired reservations: $e');
    }
  }

  @override
  void dispose() {
    _reservationsSub?.cancel();
    super.dispose();
  }
}
```

## Phase 5: Update BookProvider

Update: `lib/features/books/providers/book_provider.dart`

Change the `updateBookStock` method:

```dart
/// Update stock count for an existing book.
Future<bool> updateBookStock(String bookId, int totalCopies) async {
  try {
    await _repo.updateStock(bookId, totalCopies);
    return true;
  } catch (e) {
    _error = e.toString();
    notifyListeners();
    return false;
  }
}
```

## Phase 6: Register Providers

Update: `lib/shared/widgets/animated_splash_screen.dart`

Add ReservationProvider to the MultiProvider:

```dart
ChangeNotifierProvider(create: (_) => ReservationProvider()),
```

## Phase 7: Update Firestore Rules

Update: `firestore.rules`

Add reservation rules:

```
match /reservations/{reservationId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null && 
                request.resource.data.userId == request.auth.uid;
  allow update: if request.auth != null && 
                (resource.data.userId == request.auth.uid || 
                 get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'librarian']);
}
```

## Phase 8: Create Reader Reservation Screen

Create: `lib/features/reservations/screens/reader_reservation_screen.dart`

This screen should have:
1. Search books functionality
2. Add to reservation cart (max 3 total)
3. Show available stock
4. Create reservation button
5. Show QR code after creation
6. List of user's reservations with status

## Phase 9: Create Librarian Reservation Scanner

Create: `lib/features/reservations/screens/librarian_reservation_scanner.dart`

This screen should:
1. Show QR scanner
2. Parse QR code (format: `LIB_RESERVATION:reservationId:userId`)
3. Load reservation data
4. Show reservation details
5. Allow setting borrow days
6. Issue books button that:
   - Creates BorrowTransaction
   - Calls collectReservation
   - Updates stocks

## Phase 10: Integration Points

### Update Reader Main Screen
Add Reservations tab/button

### Update Librarian Main Screen  
Add Reservation Scanner option

### QR Code Format
```
LIB_RESERVATION:reservationId:userId
```

## Testing Checklist

- [ ] Create reservation with 1 book
- [ ] Create reservation with 3 books (max)
- [ ] Try to create reservation with 4 books (should fail)
- [ ] Check reservedStock increases
- [ ] Check availableStock decreases
- [ ] Generate and display QR code
- [ ] Scan QR code as librarian
- [ ] Collect reservation (issue books)
- [ ] Verify reservedStock decreases
- [ ] Verify borrowedStock increases
- [ ] Verify reservation status = collected
- [ ] Verify books appear in borrowed section
- [ ] Wait 3 days for expiry (or manually expire)
- [ ] Verify expired reservation releases stock
- [ ] Check reservation history shows all statuses

## Database Migration

Since we changed the Book model structure, existing books need migration:

```dart
// Run this once to migrate existing books
Future<void> migrateBooks() async {
  final books = await FirebaseFirestore.instance.collection('books').get();
  
  for (final doc in books.docs) {
    final data = doc.data();
    if (!data.containsKey('borrowedStock')) {
      await doc.reference.update({
        'borrowedStock': 0,
        'reservedStock': 0,
      });
    }
  }
}
```

## Summary

This implementation provides:
- ✅ 3-book reservation limit
- ✅ 3-day expiry
- ✅ QR code generation
- ✅ Stock tracking (total, borrowed, reserved)
- ✅ Reservation → Borrow conversion
- ✅ History preservation
- ✅ Expiry handling
- ✅ Clean architecture

The system is modular and doesn't break existing functionality.
