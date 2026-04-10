import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/providers/base_provider.dart';
import '../models/borrow_model.dart';
import '../repository/borrow_repository.dart';

/// Provider for borrow/return operations.
class BorrowProvider extends BaseProvider {
  final BorrowRepository _repo = BorrowRepository();

  List<BorrowModel> _borrows = [];
  List<BorrowModel> get borrows => _borrows;

  List<BorrowModel> get activeBorrows =>
      _borrows.where((b) => b.status == BorrowStatus.active).toList();

  List<BorrowModel> get returnedBorrows =>
      _borrows.where((b) => b.status == BorrowStatus.returned).toList();

  List<BorrowModel> get overdueBorrows =>
      _borrows.where((b) => b.isOverdue).toList();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize the provider
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    debugPrint('📖 BorrowProvider: Initializing...');
    _isInitialized = true;
  }

  /// Listen to borrows for a specific user.
  void listenToUserBorrows(String userId) {
    if (isDisposed) return;
    
    _isLoading = true;
    notifyListeners();

    final subscription = _repo.userBorrowsStream(userId).listen(
      (list) {
        if (isDisposed) return;
        _borrows = list;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        if (isDisposed) return;
        debugPrint('📖 Borrows stream error: $e');
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
    
    addSubscription('user_borrows', subscription);
  }

  /// Listen to borrows for a library (librarian view).
  void listenToLibraryBorrows(String libraryId) {
    if (isDisposed) return;
    
    _isLoading = true;
    notifyListeners();

    final subscription = _repo.libraryBorrowsStream(libraryId).listen(
      (list) {
        if (isDisposed) return;
        _borrows = list;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        if (isDisposed) return;
        debugPrint('📖 Library borrows stream error: $e');
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
    
    addSubscription('library_borrows', subscription);
  }

  /// Issue a book to a reader.
  Future<bool> issueBook({
    required String bookId,
    required String bookTitle,
    String? bookThumbnail,
    required String userId,
    required String userName,
    required String libraryId,
    required String issuedBy,
    int borrowDays = 14,
  }) async {
    try {
      _error = null;
      final now = DateTime.now();
      final borrow = BorrowModel(
        id: '',
        bookId: bookId,
        bookTitle: bookTitle,
        bookThumbnail: bookThumbnail,
        userId: userId,
        userName: userName,
        libraryId: libraryId,
        issuedBy: issuedBy,
        borrowDate: now,
        dueDate: now.add(Duration(days: borrowDays)),
      );
      await _repo.issueBorrow(borrow);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Return a borrowed book.
  Future<bool> returnBook(String borrowId, String bookId) async {
    try {
      _error = null;
      await _repo.returnBook(borrowId, bookId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Check if user has active borrow for a book.
  Future<bool> hasActiveBorrow(String userId, String bookId) async {
    return _repo.hasActiveBorrow(userId, bookId);
  }
}
