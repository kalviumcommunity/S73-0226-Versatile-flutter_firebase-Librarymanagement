import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../auth/providers/auth_provider.dart';
import '../../books/models/book_model.dart';
import '../models/reservation_model.dart';
import '../providers/reservation_provider.dart';

/// Button widget to reserve a book
class BookReservationButton extends StatefulWidget {
  final BookModel book;
  final VoidCallback? onReserved;

  const BookReservationButton({
    super.key,
    required this.book,
    this.onReserved,
  });

  @override
  State<BookReservationButton> createState() => _BookReservationButtonState();
}

class _BookReservationButtonState extends State<BookReservationButton> {
  bool _isReserving = false;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    
    if (user == null) {
      return const SizedBox.shrink();
    }

    // Don't show if no available copies
    if (widget.book.availableCopies <= 0) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.block, size: 16),
        label: const Text('Not Available'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.getTextTertiary(context),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: _isReserving ? null : () => _showReservationDialog(context, user),
      icon: _isReserving 
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.bookmark_add, size: 16),
      label: Text(_isReserving ? 'Reserving...' : 'Reserve'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showReservationDialog(BuildContext context, user) {
    showDialog(
      context: context,
      builder: (ctx) => _ReservationDialog(
        book: widget.book,
        user: user,
        onReserve: _reserveBook,
      ),
    );
  }

  Future<void> _reserveBook(int quantity) async {
    final user = context.read<AuthProvider>().userModel;
    if (user == null) return;

    setState(() {
      _isReserving = true;
    });

    try {
      final item = ReservationItem(
        bookId: widget.book.id,
        bookTitle: widget.book.title,
        bookThumbnail: widget.book.thumbnail,
        quantity: quantity,
      );

      final success = await context.read<ReservationProvider>().createReservation(
        userId: user.uid,
        userName: user.name,
        userEmail: user.email,
        libraryId: user.libraryId ?? user.uid,
        items: [item],
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reserved ${quantity}x "${widget.book.title}"'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onReserved?.call();
      } else if (mounted) {
        final error = context.read<ReservationProvider>().error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to reserve book'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isReserving = false;
        });
      }
    }
  }
}

class _ReservationDialog extends StatefulWidget {
  final BookModel book;
  final dynamic user;
  final Function(int) onReserve;

  const _ReservationDialog({
    required this.book,
    required this.user,
    required this.onReserve,
  });

  @override
  State<_ReservationDialog> createState() => _ReservationDialogState();
}

class _ReservationDialogState extends State<_ReservationDialog> {
  int _quantity = 1;
  int _currentPendingCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentReservations();
  }

  Future<void> _loadCurrentReservations() async {
    try {
      final count = await context.read<ReservationProvider>()
          .getUserPendingReservationCount(widget.user.uid);
      
      if (mounted) {
        setState(() {
          _currentPendingCount = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading current reservations: $e');
      if (mounted) {
        setState(() {
          _currentPendingCount = 0;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final maxQuantity = (3 - _currentPendingCount).clamp(0, widget.book.availableCopies);
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      title: Row(
        children: [
          Icon(
            Icons.bookmark_add,
            color: AppColors.accent,
            size: 24,
          ),
          const SizedBox(width: AppDimens.sm),
          const Expanded(child: Text('Reserve Book')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book info
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                child: widget.book.thumbnail != null
                    ? Image.network(
                        widget.book.thumbnail!,
                        width: 50,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 50,
                          height: 70,
                          color: AppColors.getSurfaceVariant(context),
                          child: Icon(Icons.menu_book, size: 24, color: AppColors.getTextTertiary(context)),
                        ),
                      )
                    : Container(
                        width: 50,
                        height: 70,
                        color: AppColors.getSurfaceVariant(context),
                        child: Icon(Icons.menu_book, size: 24, color: AppColors.getTextTertiary(context)),
                      ),
              ),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.book.authorsFormatted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Available: ${widget.book.availableCopies}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppDimens.lg),

          // Quantity selector
          if (maxQuantity > 0) ...[
            Text(
              'Select Quantity',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppDimens.sm),
            
            Container(
              padding: const EdgeInsets.all(AppDimens.md),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.getBorder(context)),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _quantity > 1 
                        ? () => setState(() => _quantity--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Expanded(
                    child: Text(
                      _quantity.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: _quantity < maxQuantity
                        ? () => setState(() => _quantity++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppDimens.sm),
            
            // Limits info
            Container(
              padding: const EdgeInsets.all(AppDimens.sm),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reservation Limits:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                  ),
                  Text(
                    '• Maximum 3 books total',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.accent,
                        ),
                  ),
                  Text(
                    '• Currently reserved: $_currentPendingCount',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.accent,
                        ),
                  ),
                  Text(
                    '• Valid for 3 days',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.accent,
                        ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(AppDimens.md),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.block,
                    color: AppColors.error,
                    size: 32,
                  ),
                  const SizedBox(height: AppDimens.sm),
                  Text(
                    'Cannot Reserve',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentPendingCount >= 3
                        ? 'You have reached the maximum reservation limit (3 books)'
                        : 'No copies available for reservation',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
            if (maxQuantity > 0) ...[
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onReserve(_quantity);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Reserve'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}