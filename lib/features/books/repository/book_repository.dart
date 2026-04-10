import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/book_model.dart';

/// Firestore repository for library book stock.
class BookRepository {
  final _collection = FirebaseFirestore.instance.collection('books');
  final _librariesCollection = FirebaseFirestore.instance.collection('libraries');

  /// Add a new book to stock. Uses composite ID (libraryId_volumeId) as doc ID.
  /// If the book already exists in this library, increments the stock instead.
  Future<BookModel> addBook(BookModel book) async {
    final docRef = _collection.doc(book.id);
    final existing = await docRef.get();

    if (existing.exists) {
      // Book already in stock — increase copies
      final current = BookModel.fromJson(existing.data()!);
      final updated = current.copyWith(
        totalCopies: current.totalCopies + book.totalCopies,
      );
      await docRef.update({
        'totalCopies': updated.totalCopies,
      });
      return updated;
    } else {
      await docRef.set(book.toJson());
      // Increment library book count
      if (book.libraryId != null && book.libraryId!.isNotEmpty) {
        await _librariesCollection.doc(book.libraryId).update({
          'bookCount': FieldValue.increment(1),
        });
      }
      return book;
    }
  }

  /// Update stock quantity for a book.
  Future<void> updateStock(String bookId, int totalCopies) {
    return _collection.doc(bookId).update({
      'totalCopies': totalCopies,
    });
  }

  /// Delete a book from stock.
  Future<void> deleteBook(String bookId) async {
    // Get the book first to find its libraryId
    final doc = await _collection.doc(bookId).get();
    if (doc.exists) {
      final libraryId = doc.data()?['libraryId'] as String?;
      await _collection.doc(bookId).delete();
      // Decrement library book count
      if (libraryId != null && libraryId.isNotEmpty) {
        await _librariesCollection.doc(libraryId).update({
          'bookCount': FieldValue.increment(-1),
        });
      }
    }
  }

  /// Get all books in stock.
  Future<List<BookModel>> getAllBooks() async {
    final snapshot =
        await _collection.orderBy('addedAt', descending: true).get();
    return snapshot.docs
        .map((doc) => BookModel.fromJson(doc.data()))
        .toList();
  }

  /// Stream of all books (real-time).
  Stream<List<BookModel>> booksStream() {
    return _collection
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => BookModel.fromJson(doc.data())).toList());
  }

  /// Stream of books belonging to a specific library.
  Stream<List<BookModel>> booksStreamByLibrary(String libraryId) {
    debugPrint('📚 BookRepository: Setting up stream for library: $libraryId');
    return _collection
        .where('libraryId', isEqualTo: libraryId)
        .snapshots()
        .map((snap) {
      debugPrint('📚 BookRepository: Stream received ${snap.docs.length} books');
      final list = snap.docs.map((doc) {
        final data = doc.data();
        debugPrint('📚   - ${data['title']}: ${data['availableCopies']}/${data['totalCopies']}');
        return BookModel.fromJson(data);
      }).toList();
      list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      return list;
    });
  }

  /// Stream of books belonging to multiple libraries (for readers who joined multiple libraries).
  Stream<List<BookModel>> booksStreamByLibraries(List<String> libraryIds) {
    debugPrint('📚 BookRepository: Setting up stream for ${libraryIds.length} libraries: $libraryIds');
    
    if (libraryIds.isEmpty) {
      return Stream.value([]);
    }

    // Firestore 'whereIn' is limited to 30 values, but for most users this should be fine
    // If a user joins more than 30 libraries, we'd need to batch the queries
    if (libraryIds.length <= 30) {
      return _collection
          .where('libraryId', whereIn: libraryIds)
          .snapshots()
          .map((snap) {
        debugPrint('📚 BookRepository: Multi-library stream received ${snap.docs.length} books');
        final list = snap.docs.map((doc) {
          final data = doc.data();
          return BookModel.fromJson(data);
        }).toList();
        list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        return list;
      });
    } else {
      // For more than 30 libraries, we'd need to implement batching
      // For now, just take the first 30
      debugPrint('📚 BookRepository: Warning - User joined more than 30 libraries, limiting to first 30');
      return booksStreamByLibraries(libraryIds.take(30).toList());
    }
  }

  /// Get books for multiple libraries (for readers who joined multiple).
  Future<List<BookModel>> getBooksByLibraries(List<String> libraryIds) async {
    if (libraryIds.isEmpty) return [];
    // Firestore 'whereIn' limited to 30 values
    final results = <BookModel>[];
    for (var i = 0; i < libraryIds.length; i += 30) {
      final chunk = libraryIds.sublist(
        i,
        i + 30 > libraryIds.length ? libraryIds.length : i + 30,
      );
      final snap = await _collection
          .where('libraryId', whereIn: chunk)
          .get();
      results.addAll(
        snap.docs.map((doc) => BookModel.fromJson(doc.data())),
      );
    }
    results.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return results;
  }

  /// Check if a book already exists in stock.
  Future<BookModel?> getBook(String bookId) async {
    final doc = await _collection.doc(bookId).get();
    if (!doc.exists) return null;
    return BookModel.fromJson(doc.data()!);
  }
}
