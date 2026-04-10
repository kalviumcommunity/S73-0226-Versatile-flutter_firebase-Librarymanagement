import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/book_model.dart';
import '../repository/book_repository.dart';
import '../services/google_books_service.dart';

/// Provider for book operations and state management.
class BookProvider extends ChangeNotifier {
  final BookRepository _repo = BookRepository();
  final GoogleBooksService _googleBooksService = GoogleBooksService();

  List<BookModel> _books = [];
  List<BookModel> get books => _books;

  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> get searchResults => _searchResults;

  bool _isLoadingBooks = false;
  bool get isLoadingBooks => _isLoadingBooks;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  String? _error;
  String? get error => _error;

  StreamSubscription? _booksSub;
  String? _currentLibraryId;
  List<String> _currentLibraryIds = []; // Track multiple library IDs

  /// Listen to books for a specific library.
  void listenToLibraryBooks(String libraryId) {
    debugPrint('📚 BookProvider: Starting to listen to library books for libraryId: $libraryId');
    _currentLibraryId = libraryId;
    _currentLibraryIds = [libraryId]; // Single library mode
    _booksSub?.cancel();
    _isLoadingBooks = true;
    _error = null;
    notifyListeners();

    _booksSub = _repo.booksStreamByLibrary(libraryId).listen(
      (list) {
        debugPrint('📚 BookProvider: Received ${list.length} books from Firestore stream');
        _books = list;
        _isLoadingBooks = false;
        _error = null;
        debugPrint('📚 BookProvider: notifyListeners() called, UI should update');
        notifyListeners();
      },
      onError: (e) {
        debugPrint('📚 Books stream error: $e');
        _error = e.toString();
        _isLoadingBooks = false;
        notifyListeners();
      },
    );
  }

  /// Listen to books from multiple libraries (for readers who joined multiple libraries).
  void listenToMultipleLibraryBooks(List<String> libraryIds) {
    debugPrint('📚 BookProvider: Starting to listen to books from ${libraryIds.length} libraries: $libraryIds');
    _currentLibraryIds = List.from(libraryIds);
    _currentLibraryId = null; // Clear single library mode
    _booksSub?.cancel();
    _isLoadingBooks = true;
    _error = null;
    notifyListeners();

    if (libraryIds.isEmpty) {
      _books = [];
      _isLoadingBooks = false;
      notifyListeners();
      return;
    }

    // Use the repository method to get books from multiple libraries
    _booksSub = _repo.booksStreamByLibraries(libraryIds).listen(
      (list) {
        debugPrint('📚 BookProvider: Received ${list.length} books from ${libraryIds.length} libraries');
        _books = list;
        _isLoadingBooks = false;
        _error = null;
        debugPrint('📚 BookProvider: notifyListeners() called, UI should update');
        notifyListeners();
      },
      onError: (e) {
        debugPrint('📚 Multi-library books stream error: $e');
        _error = e.toString();
        _isLoadingBooks = false;
        notifyListeners();
      },
    );
  }

  /// Force refresh the current library books stream.
  void forceRefresh() {
    if (_currentLibraryId == null) return;
    debugPrint('📚 BookProvider: Force refreshing books...');
    final libraryId = _currentLibraryId!;
    _booksSub?.cancel();
    _booksSub = _repo.booksStreamByLibrary(libraryId).listen(
      (list) {
        debugPrint('📚 BookProvider: Received ${list.length} books from force refresh');
        _books = list;
        _isLoadingBooks = false;
        _error = null;
        debugPrint('📚 BookProvider: notifyListeners() called');
        notifyListeners();
      },
      onError: (e) {
        debugPrint('📚 Force refresh error: $e');
        _error = e.toString();
        _isLoadingBooks = false;
        notifyListeners();
      },
    );
  }

  /// Search books using Google Books API.
  Future<void> searchGoogleBooks(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      final results = await _googleBooksService.searchBooks(query);
      _searchResults = results;
      _isSearching = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isSearching = false;
      _searchResults = [];
      notifyListeners();
    }
  }

  /// Search existing books in the library.
  Future<List<BookModel>> searchBooks(String query) async {
    if (query.trim().isEmpty) return [];
    
    final lowercaseQuery = query.toLowerCase();
    return _books.where((book) {
      return book.title.toLowerCase().contains(lowercaseQuery) ||
             book.authors.any((author) => author.toLowerCase().contains(lowercaseQuery)) ||
             (book.isbn?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  /// Clear search results.
  void clearSearch() {
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }

  /// Add a book to stock from Google Books API result.
  Future<BookModel> addBookToStock(
    Map<String, dynamic> volumeJson, {
    required String addedBy,
    int copies = 1,
    String? libraryId,
  }) async {
    try {
      _error = null;
      final book = BookModel.fromGoogleBooks(
        volumeJson,
        addedBy: addedBy,
        copies: copies,
        libraryId: libraryId,
      );
      final result = await _repo.addBook(book);
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Update book stock quantity.
  Future<void> updateBookStock(String bookId, int totalCopies) async {
    try {
      _error = null;
      await _repo.updateStock(bookId, totalCopies);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Delete a book from stock.
  Future<void> deleteBook(String bookId) async {
    try {
      _error = null;
      await _repo.deleteBook(bookId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Get a specific book by ID.
  Future<BookModel?> getBook(String bookId) async {
    try {
      return await _repo.getBook(bookId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _booksSub?.cancel();
    super.dispose();
  }
}