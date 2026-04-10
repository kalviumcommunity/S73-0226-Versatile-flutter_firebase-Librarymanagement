import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../models/book_model.dart';

/// Full book detail screen with reserve and borrow info.
class BookDetailScreen extends StatelessWidget {
  final BookModel book;

  const BookDetailScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimens.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.06),
                    AppColors.background,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Book cover
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    child: book.thumbnail != null
                        ? Image.network(
                            book.thumbnail!,
                            height: 200,
                            width: 140,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 200,
                              width: 140,
                              color: AppColors.surfaceVariant,
                              child: const Icon(Icons.menu_book, size: 48),
                            ),
                          )
                        : Container(
                            height: 200,
                            width: 140,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radiusMd),
                            ),
                            child: const Icon(Icons.menu_book, size: 48),
                          ),
                  ),
                  const SizedBox(height: AppDimens.md),
                  Text(
                    book.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimens.xs),
                  Text(
                    book.authorsFormatted,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimens.md),
                  // Availability badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: book.availableCopies > 0
                          ? AppColors.availableBadge
                          : AppColors.unavailableBadge,
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusRound),
                    ),
                    child: Text(
                      book.availableCopies > 0
                          ? '${book.availableCopies} of ${book.totalCopies} available'
                          : 'All ${book.totalCopies} copies borrowed',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: book.availableCopies > 0
                            ? AppColors.availableBadgeText
                            : AppColors.unavailableBadgeText,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Details section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.pagePaddingH,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppDimens.md),
                  _DetailRow(label: 'Publisher', value: book.publisher ?? '—'),
                  _DetailRow(label: 'Published', value: book.publishedDate ?? '—'),
                  _DetailRow(label: 'Pages', value: book.pageCount > 0 ? '${book.pageCount}' : '—'),
                  _DetailRow(label: 'ISBN', value: book.isbn ?? '—'),
                  if (book.categories.isNotEmpty)
                    _DetailRow(label: 'Categories', value: book.categories.join(', ')),
                ],
              ),
            ),

            // Description
            if (book.description != null && book.description!.isNotEmpty) ...[
              const SizedBox(height: AppDimens.lg),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.pagePaddingH,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppDimens.sm),
                    Text(
                      book.description!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                          ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppDimens.xxl),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
