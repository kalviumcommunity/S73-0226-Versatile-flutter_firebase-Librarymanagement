import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../features/borrow/models/borrow_transaction_model.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';
import '../badges/status_badge.dart';

class TransactionCard extends StatelessWidget {
  final BorrowTransaction transaction;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCoral : AppColors.coral;
    final accentColor = isDark ? AppColors.darkOrange : AppColors.orange;
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isActive = transaction.status == TransactionStatus.active;
    final isOverdue = transaction.isOverdue;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        gradient: LinearGradient(
          colors: [
            cardColor.withOpacity(0.06),
            accentColor.withOpacity(0.03),
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
            padding: const EdgeInsets.all(AppDimens.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with book count and status badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${transaction.totalBooks} ${transaction.totalBooks == 1 ? "Book" : "Books"}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _buildStatusBadge(),
                  ],
                ),
                const SizedBox(height: AppDimens.md),
                // Books list
                ...transaction.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          // Book cover thumbnail
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusSm),
                            child: Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: _buildCoverThumbnail(item.bookThumbnail),
                            ),
                          ),
                          const SizedBox(width: AppDimens.sm),
                          // Book info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.bookTitle,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Quantity: ${item.quantity}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: AppDimens.sm),
                const Divider(height: 1),
                const SizedBox(height: AppDimens.sm),
                // Library name
                Row(
                  children: [
                    Icon(
                      Icons.local_library_rounded,
                      size: AppDimens.iconSm,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Library: ${transaction.libraryName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.sm),
                // Borrow date
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: AppDimens.iconSm,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Borrowed: ${dateFormat.format(transaction.issueDate)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.sm),
                // Due date or return date
                Row(
                  children: [
                    Icon(
                      isActive ? Icons.event_outlined : Icons.check_circle_outline,
                      size: AppDimens.iconSm,
                      color: isActive
                          ? (isOverdue ? AppColors.error : AppColors.textSecondary)
                          : AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isActive
                          ? 'Due: ${dateFormat.format(transaction.dueDate)}'
                          : 'Returned: ${dateFormat.format(transaction.returnDate!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isOverdue ? AppColors.error : null,
                        fontWeight: isOverdue ? FontWeight.w600 : null,
                      ),
                    ),
                  ],
                ),
                // Fee (if applicable)
                if (transaction.calculatedFine > 0) ...[
                  const SizedBox(height: AppDimens.sm),
                  Row(
                    children: [
                      Icon(
                        Icons.attach_money,
                        size: AppDimens.iconSm,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Fine: ₹${transaction.calculatedFine.toStringAsFixed(0)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverThumbnail(String? thumbnailUrl) {
    if (thumbnailUrl == null || thumbnailUrl.isEmpty) {
      return Container(
        width: 40,
        height: 56,
        color: AppColors.surfaceVariant,
        child: const Icon(
          Icons.menu_book,
          size: 20,
          color: AppColors.textTertiary,
        ),
      );
    }

    return Image.network(
      thumbnailUrl,
      width: 40,
      height: 56,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 40,
        height: 56,
        color: AppColors.surfaceVariant,
        child: const Icon(
          Icons.menu_book,
          size: 20,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (transaction.status == TransactionStatus.returned) {
      return StatusBadge(
        label: 'Returned',
        type: BadgeType.pending,
      );
    } else if (transaction.isOverdue) {
      return StatusBadge(
        label: 'Overdue',
        type: BadgeType.unavailable,
      );
    } else {
      return StatusBadge(
        label: 'Active',
        type: BadgeType.available,
      );
    }
  }
}
