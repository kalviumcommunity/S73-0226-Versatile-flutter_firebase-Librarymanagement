import 'package:flutter/material.dart';
import '../../../features/books/models/book_model.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';
import '../badges/status_badge.dart';

class BookCard extends StatelessWidget {
  final BookModel book;
  final VoidCallback? onTap;
  final String? libraryName;

  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.libraryName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkPurple : AppColors.purple;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        gradient: LinearGradient(
          colors: [
            cardColor.withOpacity(0.06),
            primaryColor.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: cardColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book cover with 3:4 aspect ratio
                Expanded(
                  flex: 5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildCover(),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Title
                Text(
                  book.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // Author
                Text(
                  book.authorsFormatted,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Library name (if provided)
                if (libraryName != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.local_library,
                        size: 11,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          libraryName!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                // Availability badge
                _buildAvailabilityBadge(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
    if (book.thumbnail == null || book.thumbnail!.isEmpty) {
      return Container(
        color: AppColors.surfaceVariant,
        child: const Icon(
          Icons.menu_book,
          size: 48,
          color: AppColors.textTertiary,
        ),
      );
    }

    return Image.network(
      book.thumbnail!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppColors.surfaceVariant,
        child: const Icon(
          Icons.broken_image,
          size: 48,
          color: AppColors.textTertiary,
        ),
      ),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: AppColors.surfaceVariant,
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvailabilityBadge() {
    if (book.availableCopies > 0) {
      return StatusBadge(
        label: 'Available',
        type: BadgeType.available,
      );
    } else if (book.totalCopies > 0) {
      return StatusBadge(
        label: 'Unavailable',
        type: BadgeType.unavailable,
      );
    } else {
      return StatusBadge(
        label: 'Out of Stock',
        type: BadgeType.unavailable,
      );
    }
  }
}
