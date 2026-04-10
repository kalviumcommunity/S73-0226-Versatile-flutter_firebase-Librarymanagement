import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/widgets/cards/book_card.dart';
import '../../../core/widgets/empty_states/empty_state_widget.dart';
import '../../../shared/providers/cross_library_search_provider.dart';
import '../../../shared/providers/location_provider.dart';
import '../../books/models/book_model.dart';
import '../../books/providers/book_provider.dart';
import '../../library/providers/library_provider.dart';
import '../../library/screens/library_detail_screen.dart';
import 'book_detail_screen.dart';

/// Browse all books from libraries the reader has joined.
class BrowseBooksScreen extends StatefulWidget {
  const BrowseBooksScreen({super.key});

  @override
  State<BrowseBooksScreen> createState() => _BrowseBooksScreenState();
}

class _BrowseBooksScreenState extends State<BrowseBooksScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  bool _isAllLibrariesMode = false; // Toggle between My Libraries and All Libraries
  bool _hasTriggeredInitialSearch = false; // Track if we've done initial search

  @override
  void initState() {
    super.initState();
    // Initialize location for cross-library search
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().requestLocation();
    });
  }

  void _performCrossLibrarySearch() {
    if (_isAllLibrariesMode) {
      print('🔍 BrowseBooksScreen: Triggering cross-library search with query: "$_searchQuery"');
      context.read<CrossLibrarySearchProvider>().searchBooksAcrossLibraries(_searchQuery);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BookModel> _filterBooks(List<BookModel> allBooks) {
    final libraryProvider = context.read<LibraryProvider>();
    final joinedLibraryIds =
        libraryProvider.memberships.map((m) => m.libraryId).toSet();

    var books = allBooks
        .where((b) => joinedLibraryIds.contains(b.libraryId))
        .toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      books = books
          .where((b) =>
              b.title.toLowerCase().contains(q) ||
              b.authorsFormatted.toLowerCase().contains(q))
          .toList();
    }

    if (_selectedCategory != null) {
      books = books
          .where((b) => b.categories.contains(_selectedCategory))
          .toList();
    }

    return books;
  }

  Set<String> _getAllCategories(List<BookModel> books) {
    final cats = <String>{};
    for (final book in books) {
      cats.addAll(book.categories);
    }
    return cats;
  }

  @override
  Widget build(BuildContext context) {
    final allBooks = context.watch<BookProvider>().books;
    final crossLibraryProvider = context.watch<CrossLibrarySearchProvider>();
    final locationProvider = context.watch<LocationProvider>();
    
    // Trigger initial search when switching to All Libraries mode
    if (_isAllLibrariesMode && !_hasTriggeredInitialSearch) {
      _hasTriggeredInitialSearch = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('🔍 BrowseBooksScreen: Initial load of all books');
        _performCrossLibrarySearch();
      });
    }

    final books = _isAllLibrariesMode ? <BookModel>[] : _filterBooks(allBooks);
    final categories = _getAllCategories(allBooks);
    final crossLibraryResults = _isAllLibrariesMode ? crossLibraryProvider.searchResults : <BookSearchResult>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Books'),
      ),
      body: Column(
        children: [
          // Search mode toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.pagePaddingH,
              AppDimens.sm,
              AppDimens.pagePaddingH,
              0,
            ),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: false,
                  label: Text('My Libraries', style: TextStyle(fontSize: 13)),
                  icon: Icon(Icons.library_books, size: 16),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text('All Libraries', style: TextStyle(fontSize: 13)),
                  icon: Icon(Icons.public, size: 16),
                ),
              ],
              selected: {_isAllLibrariesMode},
              onSelectionChanged: (Set<bool> selection) {
                setState(() {
                  _isAllLibrariesMode = selection.first;
                  _hasTriggeredInitialSearch = false; // Reset search flag
                  if (_isAllLibrariesMode) {
                    _selectedCategory = null; // Clear category filter for cross-library search
                  } else {
                    // Clear cross-library search results when switching back to My Libraries
                    context.read<CrossLibrarySearchProvider>().clearSearch();
                  }
                });
              },
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.pagePaddingH,
              AppDimens.sm,
              AppDimens.pagePaddingH,
              AppDimens.sm,
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (v) {
                    setState(() => _searchQuery = v);
                    // Trigger search for cross-library mode
                    if (_isAllLibrariesMode) {
                      _performCrossLibrarySearch();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: _isAllLibrariesMode 
                        ? 'Search books across all libraries...'
                        : 'Search books...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 22),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
                // Cross-library search status
                if (_isAllLibrariesMode) ...[
                  const SizedBox(height: 8),
                  if (crossLibraryProvider.isSearching)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Searching across all libraries...',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (crossLibraryResults.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 12, color: AppColors.success),
                          const SizedBox(width: 6),
                          Text(
                            _searchQuery.isNotEmpty 
                                ? 'Found ${crossLibraryResults.length} results'
                                : 'Showing ${crossLibraryResults.length} books from all libraries',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (locationProvider.userLocation != null) ...[
                            const SizedBox(width: 4),
                            const Text(
                              '• Sorted by distance',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),

          // Category chips (only for My Libraries mode)
          if (!_isAllLibrariesMode && categories.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.pagePaddingH,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: AppDimens.sm),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: _selectedCategory == null,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = null),
                    ),
                  ),
                  ...categories.map((cat) => Padding(
                        padding: const EdgeInsets.only(right: AppDimens.sm),
                        child: FilterChip(
                          label: Text(cat),
                          selected: _selectedCategory == cat,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = cat),
                        ),
                      )),
                ],
              ),
            ),

          const SizedBox(height: AppDimens.sm),

          // Main content
          Expanded(
            child: _isAllLibrariesMode
                ? _buildCrossLibraryResults(crossLibraryResults, crossLibraryProvider)
                : _buildMyLibrariesResults(books),
          ),
        ],
      ),
    );
  }

  Widget _buildMyLibrariesResults(List<BookModel> books) {
    final libraryProvider = context.read<LibraryProvider>();
    
    return books.isEmpty
        ? EmptyStateWidget(
            icon: Icons.menu_book_outlined,
            title: libraryProvider.memberships.isEmpty
                ? 'Join a library to browse books'
                : 'No books found',
            message: libraryProvider.memberships.isEmpty
                ? 'Discover and join libraries to access their book collections'
                : 'Try adjusting your search or category filter',
          )
        : GridView.builder(
            padding: const EdgeInsets.all(AppDimens.pagePaddingH),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.58, // Adjusted for library name
            ),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              
              // Get library name from libraryId
              String? libraryName;
              if (book.libraryId != null) {
                final library = libraryProvider.libraries
                    .where((lib) => lib.id == book.libraryId)
                    .firstOrNull;
                libraryName = library?.name;
              }
              
              return BookCard(
                book: book,
                libraryName: libraryName,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookDetailScreen(book: book),
                  ),
                ),
              );
            },
          );
  }

  Widget _buildCrossLibraryResults(List<BookSearchResult> results, CrossLibrarySearchProvider provider) {
    if (provider.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (results.isEmpty && _searchQuery.isNotEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off,
        title: 'No books found across all libraries',
        message: 'Try different search terms',
      );
    }

    if (results.isEmpty && _searchQuery.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.public,
        title: 'Loading books from all libraries...',
        message: 'Please wait while we fetch books from all libraries',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppDimens.pagePaddingH),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _CrossLibraryResultCard(result: results[index]),
    );
  }
}

class _CrossLibraryResultCard extends StatelessWidget {
  final BookSearchResult result;

  const _CrossLibraryResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final distanceText = result.library.distanceFromUser != null
        ? locationProvider.formatDistance(result.library.distanceFromUser)
        : null;

    return Card(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LibraryDetailScreen(libraryId: result.library.id),
          ),
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.md),
          child: Row(
            children: [
              // Book cover
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
                child: result.book.thumbnail != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                        child: Image.network(
                          result.book.thumbnail!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.menu_book, size: 24),
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.menu_book, size: 24),
                      ),
              ),
              const SizedBox(width: AppDimens.md),

              // Book and library info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.book.title,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'by ${result.book.authorsFormatted}',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.local_library, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            result.library.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (distanceText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              distanceText,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: result.availableCopies > 0
                                ? AppColors.availableBadge
                                : AppColors.unavailableBadge,
                            borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                          ),
                          child: Text(
                            result.availableCopies > 0
                                ? '${result.availableCopies} available'
                                : 'Unavailable',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: result.availableCopies > 0
                                  ? AppColors.availableBadgeText
                                  : AppColors.unavailableBadgeText,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
