import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/borrow_transaction_model.dart';

/// Firestore repository for borrow transactions.
class BorrowTransactionRepository {
  final FirebaseFirestore _firestore;

  BorrowTransactionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _transactionsRef =>
      _firestore.collection('borrow_transactions');

  /// Create a borrow transaction with multiple books
  Future<BorrowTransaction> createTransaction(
      BorrowTransaction transaction) async {
    print('📦 ========== CREATING TRANSACTION ==========');
    print('📦 User: ${transaction.userEmail}');
    print('📦 Books to borrow:');
    for (final item in transaction.items) {
      print('  - ${item.bookTitle}: ${item.quantity} copies (BookID: ${item.bookId})');
    }

    // Use Firestore batch for atomic operations
    final batch = _firestore.batch();

    // Add transaction document
    final transactionRef = _transactionsRef.doc();
    batch.set(transactionRef, transaction.toJson());
    print('📦 Transaction ID: ${transactionRef.id}');

    // Update stock for each book
    for (final item in transaction.items) {
      final bookRef = _firestore.collection('books').doc(item.bookId);
      
      // Get current stock to validate
      final bookDoc = await bookRef.get();
      if (!bookDoc.exists) {
        print('❌ ERROR: Book ${item.bookTitle} (${item.bookId}) not found in Firestore');
        throw Exception('Book ${item.bookTitle} not found');
      }
      
      final bookData = bookDoc.data();
      final currentBorrowed = bookData?['borrowedStock'] as int? ?? 0;
      final currentReserved = bookData?['reservedStock'] as int? ?? 0;
      final currentTotal = bookData?['totalCopies'] as int? ?? 0;
      final currentAvailable = currentTotal - currentBorrowed - currentReserved;
      
      print('  📖 ${item.bookTitle}:');
      print('     - Current total: $currentTotal');
      print('     - Current borrowed: $currentBorrowed');
      print('     - Current reserved: $currentReserved');
      print('     - Current available: $currentAvailable');
      print('     - Borrowing: ${item.quantity}');
      print('     - Will become available: ${currentAvailable - item.quantity}');
      
      if (currentAvailable < item.quantity) {
        print('❌ ERROR: Insufficient stock for ${item.bookTitle}');
        throw Exception(
            'Insufficient stock for ${item.bookTitle}. Available: $currentAvailable, Requested: ${item.quantity}');
      }

      batch.update(bookRef, {
        'borrowedStock': FieldValue.increment(item.quantity),
      });
      print('     ✅ Batch update queued: increment borrowedStock by ${item.quantity}');
    }

    // Commit all changes atomically
    print('📦 Committing batch...');
    await batch.commit();
    print('✅ ========== TRANSACTION CREATED SUCCESSFULLY ==========');
    print('✅ Transaction ID: ${transactionRef.id}');

    return transaction.copyWith(id: transactionRef.id);
  }

  /// Return a borrow transaction
  Future<void> returnTransaction(String transactionId) async {
    print('📦 ========== RETURNING TRANSACTION ==========');
    print('📦 Transaction ID: $transactionId');
    
    final now = DateTime.now();
    final transactionDoc = await _transactionsRef.doc(transactionId).get();
    
    if (!transactionDoc.exists) {
      print('❌ ERROR: Transaction document not found in Firestore');
      throw Exception('Transaction not found');
    }

    final transactionData = transactionDoc.data();
    if (transactionData == null) {
      print('❌ ERROR: Transaction data is null');
      throw Exception('Transaction data is null');
    }

    final transaction = BorrowTransaction.fromJson(transactionData, transactionDoc.id);

    print('📦 User: ${transaction.userEmail}');
    print('📦 Current status: ${transaction.status}');
    
    // Check if already returned
    if (transaction.status == TransactionStatus.returned) {
      print('⚠️  WARNING: Transaction already returned');
      throw Exception('This transaction has already been returned');
    }

    print('📚 Books to return:');
    for (final item in transaction.items) {
      print('  - ${item.bookTitle}: ${item.quantity} copies (BookID: ${item.bookId})');
    }

    // Calculate fine
    double fine = 0;
    final overdueDays = now.difference(transaction.dueDate).inDays;
    if (overdueDays > 0) {
      fine = overdueDays * BorrowTransaction.finePerDay;
      print('📦 Overdue by $overdueDays days, fine: ₹$fine');
    } else {
      print('📦 Returned on time, no fine');
    }

    // Use batch for atomic operations
    final batch = _firestore.batch();

    // Update transaction
    batch.update(_transactionsRef.doc(transactionId), {
      'returnDate': Timestamp.fromDate(now),
      'status': 'returned',
      'fineAmount': fine,
    });
    print('📦 Batch update queued: mark transaction as returned');

    // Restore stock for each book
    for (final item in transaction.items) {
      final bookRef = _firestore.collection('books').doc(item.bookId);
      
      // Get current stock for logging
      final bookDoc = await bookRef.get();
      if (!bookDoc.exists) {
        print('⚠️  WARNING: Book ${item.bookTitle} (${item.bookId}) not found in Firestore');
        print('   Skipping stock restoration for this book');
        continue;
      }
      
      final bookData = bookDoc.data();
      final currentAvailable = bookData?['availableCopies'] as int? ?? 0;
      final currentTotal = bookData?['totalCopies'] as int? ?? 0;
      
      print('  📖 ${item.bookTitle}:');
      print('     - Current total: $currentTotal');
      print('     - Current available: $currentAvailable');
      print('     - Returning: ${item.quantity}');
      print('     - Will become: ${currentAvailable + item.quantity}');
      
      batch.update(bookRef, {
        'borrowedStock': FieldValue.increment(-item.quantity),
      });
      print('     ✅ Batch update queued: decrement borrowedStock by ${item.quantity}');
    }

    print('📦 Committing batch...');
    await batch.commit();
    print('✅ ========== TRANSACTION RETURNED SUCCESSFULLY ==========');
    print('✅ Stock should now be updated in Firestore');
    
    // Verify the updates were applied
    print('📦 Verifying updates...');
    for (final item in transaction.items) {
      final bookRef = _firestore.collection('books').doc(item.bookId);
      final bookDoc = await bookRef.get();
      if (bookDoc.exists) {
        final bookData = bookDoc.data();
        final newBorrowed = bookData?['borrowedStock'] as int? ?? 0;
        final newReserved = bookData?['reservedStock'] as int? ?? 0;
        final newTotal = bookData?['totalCopies'] as int? ?? 0;
        final newAvailable = newTotal - newBorrowed - newReserved;
        print('  ✅ ${item.bookTitle}: available is now $newAvailable (total: $newTotal, borrowed: $newBorrowed, reserved: $newReserved)');
      }
    }
    print('📦 Verification complete');
  }

  /// Get transaction by ID
  Future<BorrowTransaction?> getTransaction(String transactionId) async {
    final doc = await _transactionsRef.doc(transactionId).get();
    if (!doc.exists || doc.data() == null) return null;
    return BorrowTransaction.fromJson(doc.data()!, doc.id);
  }

  /// Stream of user's transactions
  Stream<List<BorrowTransaction>> userTransactionsStream(String userId) {
    return _transactionsRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => BorrowTransaction.fromJson(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.issueDate.compareTo(a.issueDate));
      return list;
    });
  }

  /// Stream of library's transactions
  Stream<List<BorrowTransaction>> libraryTransactionsStream(String libraryId) {
    return _transactionsRef
        .where('libraryId', isEqualTo: libraryId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => BorrowTransaction.fromJson(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.issueDate.compareTo(a.issueDate));
      return list;
    });
  }

  /// Stream of active transactions for a library
  Stream<List<BorrowTransaction>> activeTransactionsStream(String libraryId) {
    return _transactionsRef
        .where('libraryId', isEqualTo: libraryId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => BorrowTransaction.fromJson(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return list;
    });
  }

  /// Search transactions by user email
  Future<List<BorrowTransaction>> searchByUserEmail(
      String email, String libraryId) async {
    final snap = await _transactionsRef
        .where('libraryId', isEqualTo: libraryId)
        .where('userEmail', isEqualTo: email.trim().toLowerCase())
        .where('status', isEqualTo: 'active')
        .get();

    return snap.docs
        .map((doc) => BorrowTransaction.fromJson(doc.data(), doc.id))
        .toList();
  }

  /// Search transactions by user name
  Future<List<BorrowTransaction>> searchByUserName(
      String name, String libraryId) async {
    final snap = await _transactionsRef
        .where('libraryId', isEqualTo: libraryId)
        .where('status', isEqualTo: 'active')
        .get();

    // Filter by name (Firestore doesn't support case-insensitive search)
    final nameQuery = name.trim().toLowerCase();
    return snap.docs
        .map((doc) => BorrowTransaction.fromJson(doc.data(), doc.id))
        .where((t) => t.userName.toLowerCase().contains(nameQuery))
        .toList();
  }

  /// Count active transactions for a library
  Future<int> countActiveTransactions(String libraryId) async {
    final snap = await _transactionsRef
        .where('libraryId', isEqualTo: libraryId)
        .where('status', isEqualTo: 'active')
        .get();
    return snap.docs.length;
  }

  /// Count overdue transactions for a library
  Future<int> countOverdueTransactions(String libraryId) async {
    final snap = await _transactionsRef
        .where('libraryId', isEqualTo: libraryId)
        .where('status', isEqualTo: 'active')
        .where('dueDate', isLessThan: Timestamp.fromDate(DateTime.now()))
        .get();
    return snap.docs.length;
  }
}
