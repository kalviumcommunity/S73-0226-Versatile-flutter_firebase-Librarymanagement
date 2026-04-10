import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/book_model.dart';
import '../providers/book_provider.dart';
import 'add_book_screen.dart';

/// Screen showing all books in the library stock with
/// the ability to edit stock count or remove books.
class StockManagementScreen extends StatelessWidget {
  const StockManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookProvider = context.watch<BookProvider>();
    final userModel = context.watch<AuthProvider>().userModel;
    final libraryId = userModel?.libraryId ?? userModel?.uid ?? '';
    // Filter books for this library only
    final libraryBooks = bookProvider.books
        .where((b) => b.libraryId == libraryId)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Book Stock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Books',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddBookScreen()),
            ),
          ),
        ],
      ),
      body: _buildBody(context, bookProvider, libraryBooks),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddBookScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Books'),
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildBody(BuildContext context, BookProvider provider, List<BookModel> libraryBooks) {
    if (provider.isLoadingBooks) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }

    if (libraryBooks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64,
                color: AppColors.darkTextTertiary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text(
              'No books in stock',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.darkTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap "Add Books" to search Google Books\nand add them to your library.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.darkTextTertiary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Stats bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.pagePaddingH, vertical: 12),
          color: AppColors.darkSurface,
          child: Row(
            children: [
              _StatPill(
                label: 'Total Books',
                value: '${libraryBooks.length}',
                color: AppColors.darkPrimary,
              ),
              const SizedBox(width: 12),
              _StatPill(
                label: 'Total Copies',
                value: '${libraryBooks.fold<int>(0, (sum, b) => sum + b.totalCopies)}',
                color: AppColors.accent,
              ),
              const SizedBox(width: 12),
              _StatPill(
                label: 'Available',
                value: '${libraryBooks.fold<int>(0, (sum, b) => sum + b.availableCopies)}',
                color: AppColors.darkSuccess,
              ),
            ],
          ),
        ),

        // Book list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppDimens.pagePaddingH),
            itemCount: libraryBooks.length,
            itemBuilder: (context, index) {
              final book = libraryBooks[index];
              return _StockBookCard(book: book);
            },
          ),
        ),
      ],
    );
  }
}

// ── Stock book card ──

class _StockBookCard extends StatelessWidget {
  final BookModel book;

  const _StockBookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final borrowed = book.totalCopies - book.availableCopies;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: InkWell(
        onTap: () => _showStockDialog(context),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: book.thumbnail != null
                    ? Image.network(
                        book.thumbnail!,
                        width: 56,
                        height: 82,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkTextPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      book.authorsFormatted,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.darkTextSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _Badge(
                          label: '${book.totalCopies} total',
                          color: AppColors.darkPrimary,
                        ),
                        _Badge(
                          label: '${book.availableCopies} available',
                          color: AppColors.darkSuccess,
                        ),
                        if (borrowed > 0)
                          _Badge(
                            label: '$borrowed borrowed',
                            color: AppColors.darkWarning,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'edit') _showStockDialog(context);
                  if (val == 'delete') _showDeleteDialog(context);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Edit Stock'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppColors.darkError),
                        SizedBox(width: 8),
                        Text('Remove',
                            style: TextStyle(color: AppColors.darkError)),
                      ],
                    ),
                  ),
                ],
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.darkTextTertiary, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 82,
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.menu_book_rounded,
          color: AppColors.darkTextTertiary, size: 24),
    );
  }

  void _showStockDialog(BuildContext context) {
    final totalCtrl =
        TextEditingController(text: book.totalCopies.toString());
    final borrowed = book.totalCopies - book.availableCopies;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              book.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.darkTextPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Currently borrowed: $borrowed',
              style:
                  const TextStyle(fontSize: 13, color: AppColors.darkTextTertiary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: totalCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Total copies',
                helperText: 'Must be ≥ $borrowed (currently borrowed)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTotal = int.tryParse(totalCtrl.text.trim()) ?? 0;
              if (newTotal < borrowed) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Total can\'t be less than $borrowed (borrowed)'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.darkError,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              await context
                  .read<BookProvider>()
                  .updateBookStock(book.id, newTotal);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Stock updated: $newTotal total'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Book'),
        content: Text(
          'Remove "${book.title}" from stock? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<BookProvider>().deleteBook(book.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${book.title}" removed from stock'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.darkError),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ──

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
