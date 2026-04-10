import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation_model.dart';
import '../../borrow/models/borrow_transaction_model.dart';

/// Firestore repository for reservations.
class ReservationRepository {
  final FirebaseFirestore _firestore;

  ReservationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reservationsRef =>
      _firestore.collection('reservations');

  /// Create a reservation with multiple books using Firestore transaction for atomicity.
  Future<Reservation> createReservation(Reservation reservation) async {
    print('📋 ========== CREATING RESERVATION ==========');
    print('📋 User: ${reservation.userEmail}');
    print('📋 Books to reserve:');
    for (final item in reservation.items) {
      print('  - ${item.bookTitle}: ${item.quantity} copies (BookID: ${item.bookId})');
    }

    try {
      // Use Firestore transaction for atomic operations to prevent race conditions
      final result = await _firestore.runTransaction<Reservation>((transaction) async {
        // PHASE 1: ALL READS FIRST (Firestore requirement)
        print('📋 Phase 1: Reading all book documents...');
        final bookReads = <String, DocumentSnapshot<Map<String, dynamic>>>{};
        
        for (final item in reservation.items) {
          final bookRef = _firestore.collection('books').doc(item.bookId);
          final bookDoc = await transaction.get(bookRef);
          bookReads[item.bookId] = bookDoc;
        }
        print('📋 Phase 1 complete: Read ${bookReads.length} book documents');

        // PHASE 2: VALIDATE ALL READS
        print('📋 Phase 2: Validating stock availability...');
        for (final item in reservation.items) {
          final bookDoc = bookReads[item.bookId]!;
          
          if (!bookDoc.exists) {
            print('❌ ERROR: Book ${item.bookTitle} (${item.bookId}) not found in Firestore');
            throw Exception('Book ${item.bookTitle} not found');
          }
          
          final bookData = bookDoc.data()!;
          final currentBorrowed = bookData['borrowedStock'] as int? ?? 0;
          final currentReserved = bookData['reservedStock'] as int? ?? 0;
          final currentTotal = bookData['totalCopies'] as int? ?? 0;
          final currentAvailable = currentTotal - currentBorrowed - currentReserved;
          
          print('  📖 ${item.bookTitle}:');
          print('     - Current total: $currentTotal');
          print('     - Current borrowed: $currentBorrowed');
          print('     - Current reserved: $currentReserved');
          print('     - Current available: $currentAvailable');
          print('     - Reserving: ${item.quantity}');
          print('     - Will become available: ${currentAvailable - item.quantity}');
          
          if (currentAvailable < item.quantity) {
            print('❌ ERROR: Insufficient stock for ${item.bookTitle}');
            throw Exception(
                'Insufficient stock for ${item.bookTitle}. Available: $currentAvailable, Requested: ${item.quantity}');
          }
        }
        print('📋 Phase 2 complete: All stock validated');

        // PHASE 3: ALL WRITES (after all reads are done)
        print('📋 Phase 3: Performing all writes...');
        
        // Create reservation document
        final reservationRef = _reservationsRef.doc();
        print('📋 Reservation ID: ${reservationRef.id}');
        
        final reservationData = reservation.toJson();
        transaction.set(reservationRef, reservationData);
        print('📋 Write 1: Reservation creation queued');

        // Update stock for all books
        int writeCount = 2;
        for (final item in reservation.items) {
          final bookRef = _firestore.collection('books').doc(item.bookId);
          transaction.update(bookRef, {
            'reservedStock': FieldValue.increment(item.quantity),
          });
          print('📋 Write $writeCount: Update stock for ${item.bookTitle} - increment reservedStock by ${item.quantity}');
          writeCount++;
        }
        
        print('📋 Phase 3 complete: ${writeCount - 1} writes queued');
        print('📋 Committing transaction...');

        return reservation.copyWith(id: reservationRef.id);
      });

      print('✅ ========== RESERVATION CREATED SUCCESSFULLY ==========');
      print('✅ Reservation ID: ${result.id}');
      return result;
    } catch (e, stackTrace) {
      print('❌ ========== RESERVATION CREATION FAILED ==========');
      print('❌ Error: $e');
      print('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get reservation by ID
  Future<Reservation?> getReservation(String reservationId) async {
    final doc = await _reservationsRef.doc(reservationId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Reservation.fromJson(doc.data()!, doc.id);
  }

  /// Convert reservation to borrow transaction
  Future<BorrowTransaction> convertToBorrowTransaction(
    String reservationId,
    DateTime dueDate,
    String issuedBy,
  ) async {
    print('📋 ========== CONVERTING RESERVATION TO BORROW ==========');
    print('📋 Reservation ID: $reservationId');
    
    try {
      final reservationDoc = await _reservationsRef.doc(reservationId).get();
      if (!reservationDoc.exists) {
        print('❌ ERROR: Reservation document not found');
        throw Exception('Reservation not found');
      }

      final reservation = Reservation.fromJson(reservationDoc.data()!, reservationDoc.id);
      
      if (reservation.status != ReservationStatus.pending) {
        print('❌ ERROR: Reservation status is ${reservation.status}, expected pending');
        if (reservation.status == ReservationStatus.collected) {
          throw Exception('This reservation has already been collected.');
        } else if (reservation.status == ReservationStatus.expired) {
          throw Exception('This reservation has expired. Please ask the reader to create a new reservation.');
        } else {
          throw Exception('Reservation is not available for collection (Status: ${reservation.status.displayName})');
        }
      }

      if (reservation.isExpired) {
        print('❌ ERROR: Reservation has expired');
        throw Exception('This reservation has expired. Please ask the reader to create a new reservation.');
      }

      print('📋 User: ${reservation.userEmail}');
      print('📋 Converting books:');
      for (final item in reservation.items) {
        print('  - ${item.bookTitle}: ${item.quantity} copies (BookID: ${item.bookId})');
      }

      // Validate all books exist before proceeding
      for (final item in reservation.items) {
        final bookDoc = await _firestore.collection('books').doc(item.bookId).get();
        if (!bookDoc.exists) {
          print('❌ ERROR: Book ${item.bookTitle} (${item.bookId}) not found in Firestore');
          throw Exception('Book ${item.bookTitle} not found');
        }
        print('✅ Book ${item.bookTitle} exists in Firestore');
      }

      // Create borrow transaction
      final borrowTransaction = BorrowTransaction(
        id: '',
        userId: reservation.userId,
        userName: reservation.userName,
        userEmail: reservation.userEmail,
        libraryId: reservation.libraryId,
        libraryName: reservation.libraryName,
        issuedBy: issuedBy,
        items: reservation.items.map((item) => BorrowItem(
          bookId: item.bookId,
          bookTitle: item.bookTitle,
          bookThumbnail: item.bookThumbnail,
          quantity: item.quantity,
        )).toList(),
        issueDate: DateTime.now(),
        dueDate: dueDate,
      );

      print('📋 Created borrow transaction object');
      
      // Test serialization
      try {
        final jsonData = borrowTransaction.toJson();
        print('📋 BorrowTransaction serialization successful');
        print('📋 JSON keys: ${jsonData.keys.toList()}');
      } catch (e) {
        print('❌ ERROR: BorrowTransaction serialization failed: $e');
        throw Exception('Failed to serialize borrow transaction: $e');
      }

      // Use batch for atomic operations
      final batch = _firestore.batch();

      // Create borrow transaction
      final transactionRef = _firestore.collection('borrow_transactions').doc();
      batch.set(transactionRef, borrowTransaction.toJson());
      print('📋 Borrow transaction ID: ${transactionRef.id}');
      print('📋 Batch operation 1: Create borrow transaction');

      // Update reservation status to collected
      batch.update(_reservationsRef.doc(reservationId), {
        'status': ReservationStatus.collected.name,
        'collectedDate': Timestamp.fromDate(DateTime.now()),
      });
      print('📋 Batch operation 2: Mark reservation as collected');

      // Update stock for each book (reserved -> borrowed)
      for (final item in reservation.items) {
        final bookRef = _firestore.collection('books').doc(item.bookId);
        
        batch.update(bookRef, {
          'reservedStock': FieldValue.increment(-item.quantity),
          'borrowedStock': FieldValue.increment(item.quantity),
        });
        print('📋 Batch operation 3.${reservation.items.indexOf(item) + 1}: Update stock for ${item.bookTitle}');
      }

      print('📋 Committing batch with ${3 + reservation.items.length} operations...');
      await batch.commit();
      print('✅ ========== CONVERSION COMPLETED SUCCESSFULLY ==========');

      return borrowTransaction.copyWith(id: transactionRef.id);
    } catch (e) {
      print('❌ ========== CONVERSION FAILED ==========');
      print('❌ Error: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Expire a reservation and release stock
  Future<void> expireReservation(String reservationId) async {
    print('📋 ========== EXPIRING RESERVATION ==========');
    print('📋 Reservation ID: $reservationId');
    
    final reservationDoc = await _reservationsRef.doc(reservationId).get();
    if (!reservationDoc.exists) {
      throw Exception('Reservation not found');
    }

    final reservation = Reservation.fromJson(reservationDoc.data()!, reservationDoc.id);
    
    if (reservation.status != ReservationStatus.pending) {
      print('⚠️  WARNING: Reservation is not pending, current status: ${reservation.status}');
      return;
    }

    print('📋 Expiring books:');
    for (final item in reservation.items) {
      print('  - ${item.bookTitle}: ${item.quantity} copies');
    }

    // Use batch for atomic operations
    final batch = _firestore.batch();

    // Update reservation status to expired
    batch.update(_reservationsRef.doc(reservationId), {
      'status': ReservationStatus.expired.name,
    });
    print('📋 Batch update queued: mark reservation as expired');

    // Release reserved stock for each book
    for (final item in reservation.items) {
      final bookRef = _firestore.collection('books').doc(item.bookId);
      
      batch.update(bookRef, {
        'reservedStock': FieldValue.increment(-item.quantity),
      });
      print('     ✅ Batch update queued: ${item.bookTitle} - decrement reserved by ${item.quantity}');
    }

    print('📋 Committing batch...');
    await batch.commit();
    print('✅ ========== RESERVATION EXPIRED SUCCESSFULLY ==========');
  }

  /// Get user's total pending reservation quantity
  Future<int> getUserPendingReservationCount(String userId) async {
    final snap = await _reservationsRef
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: ReservationStatus.pending.name)
        .get();

    int totalQuantity = 0;
    for (final doc in snap.docs) {
      final reservation = Reservation.fromJson(doc.data(), doc.id);
      // Check if not expired
      if (!reservation.isExpired) {
        totalQuantity += reservation.totalBooks;
      }
    }
    return totalQuantity;
  }

  /// Get user's pending reservation count for a specific library
  Future<int> getUserPendingReservationCountForLibrary(String userId, String libraryId) async {
    final snap = await _reservationsRef
        .where('userId', isEqualTo: userId)
        .where('libraryId', isEqualTo: libraryId)
        .where('status', isEqualTo: ReservationStatus.pending.name)
        .get();

    int totalQuantity = 0;
    for (final doc in snap.docs) {
      final reservation = Reservation.fromJson(doc.data(), doc.id);
      // Check if not expired
      if (!reservation.isExpired) {
        totalQuantity += reservation.totalBooks;
      }
    }
    return totalQuantity;
  }

  /// Stream of user's reservations
  Stream<List<Reservation>> userReservationsStream(String userId) {
    print('📋 Setting up user reservations stream for userId: $userId');
    return _reservationsRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      print('📋 User reservations stream received ${snap.docs.length} documents');
      final list = snap.docs
          .map((doc) {
            try {
              print('📋 Parsing reservation doc: ${doc.id}');
              return Reservation.fromJson(doc.data(), doc.id);
            } catch (e) {
              print('📋 Error parsing reservation ${doc.id}: $e');
              return null;
            }
          })
          .where((r) => r != null)
          .cast<Reservation>()
          .toList();
      list.sort((a, b) => b.reservationDate.compareTo(a.reservationDate));
      print('📋 Returning ${list.length} parsed reservations for user');
      return list;
    });
  }

  /// Stream of library's pending reservations only
  Stream<List<Reservation>> pendingReservationsStream(String libraryId) {
    print('📋 Setting up pending reservations stream for libraryId: $libraryId');
    return _reservationsRef
        .where('libraryId', isEqualTo: libraryId)
        .where('status', isEqualTo: ReservationStatus.pending.name)
        .snapshots()
        .map((snap) {
      print('📋 Pending reservations stream received ${snap.docs.length} documents');
      final list = snap.docs
          .map((doc) {
            try {
              print('📋 Parsing pending reservation doc: ${doc.id}');
              return Reservation.fromJson(doc.data(), doc.id);
            } catch (e) {
              print('📋 Error parsing pending reservation ${doc.id}: $e');
              return null;
            }
          })
          .where((r) => r != null && !r!.isExpired) // Filter out expired ones
          .cast<Reservation>()
          .toList();
      list.sort((a, b) => a.reservationDate.compareTo(b.reservationDate));
      print('📋 Returning ${list.length} pending reservations for library');
      return list;
    });
  }

  /// Stream of library's all reservations (for history)
  Stream<List<Reservation>> libraryReservationsStream(String libraryId) {
    print('📋 Setting up library reservations stream for libraryId: $libraryId');
    return _reservationsRef
        .where('libraryId', isEqualTo: libraryId)
        .snapshots()
        .map((snap) {
      print('📋 Library reservations stream received ${snap.docs.length} documents');
      final list = snap.docs
          .map((doc) {
            try {
              print('📋 Parsing library reservation doc: ${doc.id}');
              return Reservation.fromJson(doc.data(), doc.id);
            } catch (e) {
              print('📋 Error parsing library reservation ${doc.id}: $e');
              return null;
            }
          })
          .where((r) => r != null)
          .cast<Reservation>()
          .toList();
      list.sort((a, b) => b.reservationDate.compareTo(a.reservationDate));
      print('📋 Returning ${list.length} library reservations');
      return list;
    });
  }

  /// Process expired reservations (should be called periodically)
  Future<void> processExpiredReservations() async {
    final now = DateTime.now();
    final snap = await _reservationsRef
        .where('status', isEqualTo: ReservationStatus.pending.name)
        .where('expiryDate', isLessThan: Timestamp.fromDate(now))
        .get();

    for (final doc in snap.docs) {
      try {
        await expireReservation(doc.id);
      } catch (e) {
        print('Error expiring reservation ${doc.id}: $e');
      }
    }
  }
}
