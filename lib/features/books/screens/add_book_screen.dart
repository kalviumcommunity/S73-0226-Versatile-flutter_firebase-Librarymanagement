import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/book_provider.dart';

/// Screen to search Google Books and add books to library stock.
class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<BookProvider>().searchGoogleBooks(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookProvider = context.watch<BookProvider>();

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        title: const Text('Add Books'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (q) =>
                  context.read<BookProvider>().searchGoogleBooks(q),
              style: TextStyle(color: AppColors.getTextPrimary(context)),
              decoration: InputDecoration(
                hintText: 'Search by title, author, or ISBN...',
                hintStyle: TextStyle(color: AppColors.getTextTertiary(context)),
                prefixIcon: Icon(Icons.search_rounded, size: 22, color: AppColors.getTextSecondary(context)),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, size: 20, color: AppColors.getTextSecondary(context)),
                        onPressed: () {
                          _searchCtrl.clear();
                          context.read<BookProvider>().clearSearch();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.getSurface(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(bookProvider),
    );
  }

  Widget _buildBody(BookProvider provider) {
    if (provider.isSearching) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }

    if (provider.error != null && provider.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.getError(context)),
            const SizedBox(height: 12),
            Text('Search failed', style: TextStyle(color: AppColors.getError(context))),
            const SizedBox(height: 4),
            Text(provider.error!,
                style: TextStyle(
                    fontSize: 12, color: AppColors.getTextTertiary(context))),
          ],
        ),
      );
    }

    if (_searchCtrl.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded,
                size: 64,
                color: AppColors.getTextTertiary(context).withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'Search Google Books',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextSecondary(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Find books by title, author, or ISBN\nand add them to your library stock.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.getTextTertiary(context)),
            ),
          ],
        ),
      );
    }

    if (provider.searchResults.isEmpty) {
      return Center(
        child: Text(
          'No books found. Try a different search.',
          style: TextStyle(color: AppColors.getTextTertiary(context)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimens.pagePaddingH),
      itemCount: provider.searchResults.length,
      itemBuilder: (context, index) {
        final volume = provider.searchResults[index];
        return _SearchResultCard(
          volumeJson: volume,
          onAdd: () => _showAddDialog(volume),
        );
      },
    );
  }

  void _showAddDialog(Map<String, dynamic> volumeJson) {
    final info = volumeJson['volumeInfo'] as Map<String, dynamic>? ?? {};
    final title = info['title'] ?? 'Untitled';
    final copiesCtrl = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getSurface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add to Stock', style: TextStyle(color: AppColors.getTextPrimary(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimary(context),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: copiesCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(color: AppColors.getTextPrimary(context)),
              decoration: InputDecoration(
                labelText: 'Number of copies',
                labelStyle: TextStyle(color: AppColors.getTextSecondary(context)),
                filled: true,
                fillColor: AppColors.getSurfaceVariant(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  borderSide: BorderSide(color: AppColors.getBorder(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  borderSide: BorderSide(color: AppColors.getBorder(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  borderSide: BorderSide(color: AppColors.getPrimary(context), width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.getTextSecondary(context),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final copies = int.tryParse(copiesCtrl.text.trim()) ?? 1;
              if (copies < 1) return;
              Navigator.pop(ctx);

              final uid = context.read<AuthProvider>().userModel?.uid ?? '';
              final userModel = context.read<AuthProvider>().userModel;
              final libraryId = userModel?.libraryId ?? uid;
              try {
                final result =
                    await context.read<BookProvider>().addBookToStock(
                          volumeJson,
                          addedBy: uid,
                          copies: copies,
                          libraryId: libraryId,
                        );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '✅ "${result.title}" added — ${result.totalCopies} total copies'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to add: $e'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.getError(context),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.getPrimary(context),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ── Search result card ──

class _SearchResultCard extends StatelessWidget {
  final Map<String, dynamic> volumeJson;
  final VoidCallback onAdd;

  const _SearchResultCard({
    required this.volumeJson,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final info = volumeJson['volumeInfo'] as Map<String, dynamic>? ?? {};
    final title = info['title'] as String? ?? 'Untitled';
    final authors = (info['authors'] as List?)?.join(', ') ?? 'Unknown';
    final imageLinks = info['imageLinks'] as Map<String, dynamic>?;
    String? thumb = imageLinks?['thumbnail'] as String? ??
        imageLinks?['smallThumbnail'] as String?;
    if (thumb != null && thumb.startsWith('http:')) {
      thumb = thumb.replaceFirst('http:', 'https:');
    }
    final publisher = info['publisher'] as String?;
    final publishedDate = info['publishedDate'] as String?;
    final pageCount = info['pageCount'] as int?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: InkWell(
        onTap: () => _showBookDetails(context, info, thumb),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: thumb != null
                    ? Image.network(
                        thumb,
                        width: 60,
                        height: 88,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderCover(context),
                      )
                    : _placeholderCover(context),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextPrimary(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authors,
                      style: TextStyle(
                          fontSize: 13, color: AppColors.getTextSecondary(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (publishedDate != null)
                          _InfoChip(icon: Icons.calendar_today, text: publishedDate),
                        if (pageCount != null && pageCount > 0)
                          _InfoChip(
                              icon: Icons.menu_book, text: '$pageCount pp'),
                        if (publisher != null)
                          _InfoChip(icon: Icons.business, text: publisher),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Add button
              IconButton(
                onPressed: onAdd,
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.getPrimary(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 20),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderCover(BuildContext context) {
    return Container(
      width: 60,
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.getSurfaceVariant(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.menu_book_rounded,
          color: AppColors.getTextTertiary(context), size: 28),
    );
  }

  void _showBookDetails(
      BuildContext context, Map<String, dynamic> info, String? thumb) {
    final title = info['title'] as String? ?? 'Untitled';
    final authors = (info['authors'] as List?)?.join(', ') ?? 'Unknown';
    final description = info['description'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getSurface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.getBorder(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: thumb != null
                        ? Image.network(thumb,
                            width: 100, height: 148, fit: BoxFit.cover)
                        : Container(
                            width: 100,
                            height: 148,
                            color: AppColors.getSurfaceVariant(context),
                            child: Icon(Icons.menu_book_rounded,
                                size: 40, color: AppColors.getTextTertiary(context)),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.w700,
                                color: AppColors.getTextPrimary(context))),
                        const SizedBox(height: 6),
                        Text(authors,
                            style: TextStyle(
                                fontSize: 14,
                                color: AppColors.getTextSecondary(context))),
                      ],
                    ),
                  ),
                ],
              ),
              if (description != null) ...[
                const SizedBox(height: 20),
                Text('Description',
                    style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextPrimary(context))),
                const SizedBox(height: 8),
                Text(description,
                    style: TextStyle(
                        fontSize: 14,
                        color: AppColors.getTextSecondary(context),
                        height: 1.5)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onAdd();
                  },
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Add to Stock'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.getPrimary(context),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.getTextTertiary(context)),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            text,
            style: TextStyle(fontSize: 11, color: AppColors.getTextTertiary(context)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
