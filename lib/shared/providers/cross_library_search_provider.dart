import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/books/models/book_model.dart';
import '../../features/library/models/library_model.dart';
import 'location_provider.dart';

/// Result model for cross-library book search
class BookSearchResult {
  final BookModel book;
  final LibraryModel library;
  final double? distanceKm;
  final int availableCopies;

  const BookSearchResult({
    required this.book,
    required this.library,
    this.distanceKm,
    required this.availableCopies,
  });
}

/// Provider for searching books across all libraries with distance-based sorting
class CrossLibrarySearchProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationProvider _locationProvider;

  List<BookSearchResult> _searchResults = [];
  bool _isSearching = false;
  String _lastQuery = '';
  DateTime? _lastSearchTime;
  String? _error;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  // Setter for error
  set error(String? value) {
    _error = value;
    notifyListeners();
  }

  CrossLibrarySearchProvider(this._locationProvider);

  List<BookSearchResult> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String get lastQuery => _lastQuery;
  String? get error => _error;

  /// Searches for books across all libraries with distance-based sorting
  /// 
  /// [query] - Search term to match against book title, author, or ISBN
  /// If query is empty, shows all books from all libraries
  /// Results are cached for 5 minutes to improve performance
  Future<void> searchBooksAcrossLibraries(String query) async {
    final trimmedQuery = query.trim().toLowerCase();
    
    print('🔍 CrossLibrarySearchProvider: Starting search with query: "$trimmedQuery"');
    
    // Check cache
    if (_lastQuery == trimmedQuery && 
        _lastSearchTime != null && 
        DateTime.now().difference(_lastSearchTime!).compareTo(_cacheTimeout) < 0) {
      print('🔍 CrossLibrarySearchProvider: Using cached results');
      // Use cached results but update distances if location changed
      if (_locationProvider.userLocation != null) {
        _updateResultDistances();
        _sortResultsByDistance();
        notifyListeners();
      }
      return;
    }

    _isSearching = true;
    _lastQuery = trimmedQuery;
    notifyListeners();

    try {
      print('🔍 CrossLibrarySearchProvider: Performing Firestore search...');
      // Search across all libraries (or get all books if no query)
      final results = await _performCrossLibrarySearch(trimmedQuery);
      
      print('🔍 CrossLibrarySearchProvider: Found ${results.length} results');
      _searchResults = results;
      _lastSearchTime = DateTime.now();
      
      // Update distances if location is available
      if (_locationProvider.userLocation != null) {
        print('🔍 CrossLibrarySearchProvider: Updating distances and sorting');
        _updateResultDistances();
        _sortResultsByDistance();
      } else {
        print('🔍 CrossLibrarySearchProvider: No location, sorting alphabetically');
        // Sort alphabetically by library name if no location
        _sortResultsAlphabetically();
      }
      
    } catch (e) {
      print('CrossLibrarySearchProvider: Search failed - $e');
      _error = 'Search failed: ${e.toString()}';
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Load all books from all libraries (for initial display)
  Future<void> loadAllBooks() async {
    await searchBooksAcrossLibraries(''); // Empty query loads all books
  }

  /// Performs the actual Firestore search across all libraries
  Future<List<BookSearchResult>> _performCrossLibrarySearch(String query) async {
    final results = <BookSearchResult>[];
    
    try {
      print('🔍 CrossLibrarySearchProvider: Getting all libraries...');
      // First, get all libraries
      final librariesSnapshot = await _firestore.collection('libraries').get();
      final libraries = librariesSnapshot.docs
          .map((doc) => LibraryModel.fromJson(doc.data(), doc.id))
          .toList();

      print('🔍 CrossLibrarySearchProvider: Found ${libraries.length} libraries');

      // Get all books from the global books collection
      print('🔍 CrossLibrarySearchProvider: Querying global books collection...');
      final booksSnapshot = await _firestore.collection('books').get();
      print('🔍 CrossLibrarySearchProvider: Found ${booksSnapshot.docs.length} total books');

      // Group books by library and filter by search query
      for (final library in libraries) {
        try {
          print('🔍 CrossLibrarySearchProvider: Processing library: ${library.name} (${library.id})');
          
          // Filter books for this library
          final libraryBooks = booksSnapshot.docs.where((bookDoc) {
            final bookData = bookDoc.data();
            return bookData['libraryId'] == library.id;
          }).toList();

          print('🔍 CrossLibrarySearchProvider: Found ${libraryBooks.length} books in ${library.name}');

          for (final bookDoc in libraryBooks) {
            final bookData = bookDoc.data();
            final book = BookModel.fromJson({...bookData, 'id': bookDoc.id});
            
            // Check if book matches search query
            if (_matchesSearchQuery(book, query)) {
              final availableCopies = _calculateAvailableCopies(book);
              
              results.add(BookSearchResult(
                book: book,
                library: library,
                availableCopies: availableCopies,
              ));
              print('🔍 CrossLibrarySearchProvider: Added book: ${book.title} from ${library.name}');
            }
          }
        } catch (e) {
          print('CrossLibrarySearchProvider: Error processing library ${library.id} - $e');
          // Continue with other libraries even if one fails
        }
      }
    } catch (e) {
      print('CrossLibrarySearchProvider: Error getting books - $e');
      rethrow;
    }

    print('🔍 CrossLibrarySearchProvider: Total results: ${results.length}');
    return results;
  }

  /// Checks if a book matches the search query
  /// If query is empty, returns true (show all books)
  bool _matchesSearchQuery(BookModel book, String query) {
    // If no query, show all books
    if (query.isEmpty) return true;
    
    final searchTerms = query.toLowerCase().split(' ');
    final bookText = '${book.title} ${book.authorsFormatted} ${book.isbn}'.toLowerCase();
    
    // All search terms must be found in the book text
    return searchTerms.every((term) => bookText.contains(term));
  }

  /// Calculates available copies for a book
  int _calculateAvailableCopies(BookModel book) {
    return book.totalCopies - book.borrowedStock - book.reservedStock;
  }

  /// Updates distance information for all search results
  void _updateResultDistances() {
    if (_locationProvider.userLocation == null) return;

    for (final result in _searchResults) {
      if (result.library.latitude != null && result.library.longitude != null) {
        final distance = _locationProvider.calculateDistance(
          _locationProvider.userLocation!.latitude,
          _locationProvider.userLocation!.longitude,
          result.library.latitude!,
          result.library.longitude!,
        );
        
        // Update the library's distance field
        result.library.distanceFromUser = distance;
      }
    }
  }

  /// Sorts search results by distance (nearest first)
  void _sortResultsByDistance() {
    _searchResults.sort((a, b) {
      final distanceA = a.library.distanceFromUser;
      final distanceB = b.library.distanceFromUser;
      
      // Libraries without distance go to the end
      if (distanceA == null && distanceB == null) return 0;
      if (distanceA == null) return 1;
      if (distanceB == null) return -1;
      
      return distanceA.compareTo(distanceB);
    });
  }

  /// Sorts search results alphabetically by library name
  void _sortResultsAlphabetically() {
    _searchResults.sort((a, b) => a.library.name.compareTo(b.library.name));
  }

  /// Clears search results and cache
  void clearSearch() {
    _searchResults = [];
    _lastQuery = '';
    _lastSearchTime = null;
    _error = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Updates distances when user location changes
  void onLocationChanged() {
    if (_searchResults.isNotEmpty && _locationProvider.userLocation != null) {
      _updateResultDistances();
      _sortResultsByDistance();
      notifyListeners();
    }
  }

  /// Gets formatted distance for a search result
  String? getFormattedDistance(BookSearchResult result) {
    if (result.library.distanceFromUser == null) return null;
    return _locationProvider.formatDistance(result.library.distanceFromUser);
  }

  /// Groups results by book (for when multiple libraries have the same book)
  Map<String, List<BookSearchResult>> getGroupedResults() {
    final grouped = <String, List<BookSearchResult>>{};
    
    for (final result in _searchResults) {
      final key = '${result.book.title}_${result.book.authorsFormatted}';
      grouped.putIfAbsent(key, () => []).add(result);
    }
    
    return grouped;
  }

  @override
  void dispose() {
    super.dispose();
  }
}