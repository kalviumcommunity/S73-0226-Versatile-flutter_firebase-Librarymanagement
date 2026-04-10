import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/providers/base_provider.dart';
import '../models/borrow_transaction_model.dart';
import '../repository/borrow_transaction_repository.dart';

/// Provider for borrow transaction operations
class BorrowTransactionProvider extends BaseProvider {
  final BorrowTransactionRepository _repo;

  List<BorrowTransaction> _transactions = [];
  List<BorrowTransaction> get transactions => _transactions;

  List<BorrowTransaction> get activeTransactions =>
      _transactions.where((t) => t.status == TransactionStatus.active).toList();

  List<BorrowTransaction> get returnedTransactions => _transactions
      .where((t) => t.status == TransactionStatus.returned)
      .toList();

  List<BorrowTransaction> get overdueTransactions =>
      _transactions.where((t) => t.isOverdue).toList();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  BorrowTransactionProvider({BorrowTransactionRepository? repository})
      : _repo = repository ?? BorrowTransactionRepository();

  /// Initialize the provider
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    debugPrint('📖 BorrowTransactionProvider: Initializing...');
    _isInitialized = true;
  }

  /// Listen to user's transactions
  void listenToUserTransactions(String userId) {
    if (isDisposed) return;
    
    _isLoading = true;
    notifyListeners();

    final subscription = _repo.userTransactionsStream(userId).listen(
      (list) {
        if (isDisposed) return;
        _transactions = list;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        if (isDisposed) return;
        debugPrint('📖 Transactions stream error: $e');
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
    
    addSubscription('user_transactions', subscription);
  }

  /// Listen to library's transactions
  void listenToLibraryTransactions(String libraryId) {
    if (isDisposed) return;
    
    _isLoading = true;
    notifyListeners();

    final subscription = _repo.libraryTransactionsStream(libraryId).listen(
      (list) {
        if (isDisposed) return;
        _transactions = list;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        if (isDisposed) return;
        debugPrint('📖 Library transactions stream error: $e');
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
    
    addSubscription('library_transactions', subscription);
  }

  /// Create a new borrow transaction
  Future<BorrowTransaction?> createTransaction({
    required String userId,
    required String userName,
    required String userEmail,
    required String libraryId,
    required String libraryName,
    required String issuedBy,
    required List<BorrowItem> items,
    int borrowDays = 14,
  }) async {
    try {
      _error = null;
      final now = DateTime.now();
      final transaction = BorrowTransaction(
        id: '',
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        libraryId: libraryId,
        libraryName: libraryName,
        issuedBy: issuedBy,
        items: items,
        issueDate: now,
        dueDate: now.add(Duration(days: borrowDays)),
      );

      final result = await _repo.createTransaction(transaction);
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Return a transaction
  Future<bool> returnTransaction(String transactionId) async {
    try {
      _error = null;
      await _repo.returnTransaction(transactionId);
      
      // Force refresh books after return to ensure UI updates
      // This is needed because Firestore snapshots don't always trigger
      // immediately after FieldValue.increment() batch updates
      debugPrint('📚 Forcing book refresh after return...');
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get transaction by ID
  Future<BorrowTransaction?> getTransaction(String transactionId) async {
    try {
      _error = null;
      return await _repo.getTransaction(transactionId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Search transactions by user email
  Future<List<BorrowTransaction>> searchByEmail(
      String email, String libraryId) async {
    try {
      _error = null;
      return await _repo.searchByUserEmail(email, libraryId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Search transactions by user name
  Future<List<BorrowTransaction>> searchByName(
      String name, String libraryId) async {
    try {
      _error = null;
      return await _repo.searchByUserName(name, libraryId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
