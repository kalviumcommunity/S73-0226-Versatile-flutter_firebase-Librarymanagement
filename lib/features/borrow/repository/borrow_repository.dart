import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/borrow_model.dart';

/// Firestore repository for borrow records.
class BorrowRepository {
  final FirebaseFirestore _firestore;

  BorrowRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _borrowsRef =>
      _firestore.collection('borrows');

  /// Issue a book (create borrow record).
  Future<BorrowModel> issueBorrow(BorrowModel borrow) async {
    final docRef = await _borrowsRef.add(borrow.toJson());

    // Decrement available copies
    await _firestore.collection('books').doc(borrow.bookId).update({
      'availableCopies': FieldValue.increment(-1),
    });

    return borrow.copyWith(id: docRef.id);
  }

  /// Return a book.
  Future<void> returnBook(String borrowId, String bookId) async {
    final now = DateTime.now();
    final borrowDoc = await _borrowsRef.doc(borrowId).get();
    final borrow = BorrowModel.fromJson(borrowDoc.data()!, borrowDoc.id);

    // Calculate fine
    double fine = 0;
    final overdueDays = now.difference(borrow.dueDate).inDays;
    if (overdueDays > 0) {
      fine = overdueDays * BorrowModel.finePerDay;
    }

    await _borrowsRef.doc(borrowId).update({
      'returnDate': Timestamp.fromDate(now),
      'status': 'returned',
      'fineAmount': fine,
    });

    // Increment available copies
    await _firestore.collection('books').doc(bookId).update({
      'availableCopies': FieldValue.increment(1),
    });
  }

  /// Get all borrows for a user (reader).
  Stream<List<BorrowModel>> userBorrowsStream(String userId) {
    return _borrowsRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => BorrowModel.fromJson(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.borrowDate.compareTo(a.borrowDate));
      return list;
    });
  }

  /// Get all active borrows for a library (librarian view).
  Stream<List<BorrowModel>> libraryBorrowsStream(String libraryId) {
    return _borrowsRef
        .where('libraryId', isEqualTo: libraryId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => BorrowModel.fromJson(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.borrowDate.compareTo(a.borrowDate));
      return list;
    });
  }

  /// Get all active borrows (not returned).
  Stream<List<BorrowModel>> activeBorrowsStream(String libraryId) {
    return _borrowsRef
        .where('libraryId', isEqualTo: libraryId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => BorrowModel.fromJson(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return list;
    });
  }

  /// Check if user already has this book borrowed (active).
  Future<bool> hasActiveBorrow(String userId, String bookId) async {
    final snap = await _borrowsRef
        .where('userId', isEqualTo: userId)
        .where('bookId', isEqualTo: bookId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Count active borrows for a library.
  Future<int> countActiveBorrows(String libraryId) async {
    final snap = await _borrowsRef
        .where('libraryId', isEqualTo: libraryId)
        .where('status', isEqualTo: 'active')
        .get();
    return snap.docs.length;
  }

  /// Count overdue borrows for a library.
  Future<int> countOverdueBorrows(String libraryId) async {
    final snap = await _borrowsRef
        .where('libraryId', isEqualTo: libraryId)
        .where('status', isEqualTo: 'active')
        .where('dueDate', isLessThan: Timestamp.fromDate(DateTime.now()))
        .get();
    return snap.docs.length;
  }
}
