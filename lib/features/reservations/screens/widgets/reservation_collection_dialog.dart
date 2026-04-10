import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../borrow/models/borrow_transaction_model.dart';
import '../../models/reservation_model.dart';
import '../../providers/reservation_provider.dart';

/// Dialog for librarian to process reservation collection
class ReservationCollectionDialog extends StatefulWidget {
  final Reservation reservation;
  final String librarianUserId;
  final ReservationProvider reservationProvider;

  const ReservationCollectionDialog({
    super.key,
    required this.reservation,
    required this.librarianUserId,
    required this.reservationProvider,
  });

  @override
  State<ReservationCollectionDialog> createState() => _ReservationCollectionDialogState();
}

class _ReservationCollectionDialogState extends State<ReservationCollectionDialog> {
  DateTime _dueDate = DateTime.now().add(const Duration(days: 14)); // Default 14 days
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.getSurface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      title: Row(
        children: [
          Icon(
            Icons.assignment_turned_in,
            color: AppColors.getAccent(context),
            size: 24,
          ),
          const SizedBox(width: AppDimens.sm),
          Expanded(child: Text('Issue Reserved Books', style: TextStyle(color: AppColors.getTextPrimary(context)))),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reader information
            Container(
              padding: const EdgeInsets.all(AppDimens.md),
              decoration: BoxDecoration(
                color: AppColors.getSurfaceVariant(context).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reader Information',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.getTextPrimary(context),
                        ),
                  ),
                  const SizedBox(height: AppDimens.sm),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: AppColors.getTextSecondary(context)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.reservation.userName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.getTextPrimary(context),
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.email, size: 16, color: AppColors.getTextSecondary(context)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.reservation.userEmail,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.getTextSecondary(context),
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppDimens.lg),

            // Reserved books
            Text(
              'Reserved Books',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.getTextPrimary(context),
                  ),
            ),
            const SizedBox(height: AppDimens.sm),
            
            Container(
              padding: const EdgeInsets.all(AppDimens.md),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.getBorder(context)),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: Column(
                children: widget.reservation.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                        child: item.bookThumbnail != null
                            ? Image.network(
                                item.bookThumbnail!,
                                width: 40,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 40,
                                  height: 56,
                                  color: AppColors.getSurfaceVariant(context),
                                  child: Icon(Icons.menu_book, size: 20, color: AppColors.getTextTertiary(context)),
                                ),
                              )
                            : Container(
                                width: 40,
                                height: 56,
                                color: AppColors.getSurfaceVariant(context),
                                child: Icon(Icons.menu_book, size: 20, color: AppColors.getTextTertiary(context)),
                              ),
                      ),
                      const SizedBox(width: AppDimens.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.bookTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.getTextPrimary(context),
                                  ),
                            ),
                            Text(
                              'Quantity: ${item.quantity}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.getTextSecondary(context),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),

            const SizedBox(height: AppDimens.lg),

            // Due date selection
            Text(
              'Set Due Date',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.getTextPrimary(context),
                  ),
            ),
            const SizedBox(height: AppDimens.sm),
            
            Container(
              padding: const EdgeInsets.all(AppDimens.md),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.getBorder(context)),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 20, color: AppColors.getAccent(context)),
                      const SizedBox(width: AppDimens.sm),
                      Expanded(
                        child: Text(
                          'Due Date: ${_formatDate(_dueDate)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.getTextPrimary(context),
                              ),
                        ),
                      ),
                      TextButton(
                        onPressed: _selectDueDate,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.getPrimary(context),
                        ),
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.sm),
                  
                  // Quick date options
                  Wrap(
                    spacing: 8,
                    children: [
                      _QuickDateChip(
                        label: '7 days',
                        days: 7,
                        isSelected: _isDateSelected(7),
                        onTap: () => _setDueDate(7),
                      ),
                      _QuickDateChip(
                        label: '14 days',
                        days: 14,
                        isSelected: _isDateSelected(14),
                        onTap: () => _setDueDate(14),
                      ),
                      _QuickDateChip(
                        label: '21 days',
                        days: 21,
                        isSelected: _isDateSelected(21),
                        onTap: () => _setDueDate(21),
                      ),
                      _QuickDateChip(
                        label: '30 days',
                        days: 30,
                        isSelected: _isDateSelected(30),
                        onTap: () => _setDueDate(30),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.lg),

            // Reservation info
            Container(
              padding: const EdgeInsets.all(AppDimens.md),
              decoration: BoxDecoration(
                color: AppColors.getWarning(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(color: AppColors.getWarning(context).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.getWarning(context),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Reservation Details',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.getWarning(context),
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reserved: ${_formatDate(widget.reservation.reservationDate)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.getTextSecondary(context),
                        ),
                  ),
                  Text(
                    'Expires: ${_formatDate(widget.reservation.expiryDate)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.getTextSecondary(context),
                        ),
                  ),
                  Text(
                    'Total books: ${widget.reservation.totalBooks}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.getTextSecondary(context),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isProcessing ? null : () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.getTextSecondary(context),
                  side: BorderSide(color: AppColors.getBorder(context)),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _issueBooks,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.getSuccess(context),
                  foregroundColor: Colors.white,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Issue Books'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _selectDueDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      setState(() {
        _dueDate = selectedDate;
      });
    }
  }

  void _setDueDate(int days) {
    setState(() {
      _dueDate = DateTime.now().add(Duration(days: days));
    });
  }

  bool _isDateSelected(int days) {
    final targetDate = DateTime.now().add(Duration(days: days));
    return _dueDate.year == targetDate.year &&
           _dueDate.month == targetDate.month &&
           _dueDate.day == targetDate.day;
  }

  void _issueBooks() async {
    if (_isProcessing) return; // Prevent double-tap
    
    setState(() {
      _isProcessing = true;
    });

    try {
      print('🔄 Starting book issue process...');
      print('🔄 Reservation ID: ${widget.reservation.id}');
      print('🔄 Due Date: $_dueDate');
      print('🔄 Issued By: ${widget.librarianUserId}');

      final transaction = await widget.reservationProvider.convertToBorrowTransaction(
        widget.reservation.id,
        _dueDate,
        widget.librarianUserId,
      );

      print('🔄 Transaction result: ${transaction != null ? 'SUCCESS' : 'FAILED'}');
      
      if (transaction != null) {
        print('✅ Transaction created: ${transaction.id}');
      } else {
        print('❌ Transaction is null');
        print('❌ Provider error: ${widget.reservationProvider.error}');
      }

      // Check if widget is still mounted
      if (!mounted) {
        print('⚠️ Widget not mounted, cannot update UI');
        return;
      }

      if (transaction != null) {
        print('✅ Books issued successfully, closing dialog...');
        
        // CRITICAL FIX: Close dialog IMMEDIATELY before any other operations
        // Store context reference before any async operations
        final navigatorContext = context;
        
        // Close dialog synchronously
        if (mounted) {
          Navigator.of(navigatorContext).pop(true);
          print('🚪 Dialog closed successfully');
        }
        
        // Refresh views in background AFTER dialog is closed
        // Use a longer delay to ensure dialog is fully dismissed
        Future.delayed(const Duration(milliseconds: 300), () {
          try {
            widget.reservationProvider.refreshUserReservations(widget.reservation.userId);
            widget.reservationProvider.refreshPendingReservations(widget.reservation.libraryId);
            print('🔄 Background refresh completed');
          } catch (e) {
            print('⚠️ Background refresh error (non-critical): $e');
          }
        });
      } else {
        // Handle error case
        final error = widget.reservationProvider.error ?? 'Failed to issue books. Please try again.';
        print('❌ Showing error to user: $error');
        
        setState(() {
          _isProcessing = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: AppColors.getError(context),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ Exception in _issueBooks: $e');
      print('❌ Stack trace: $stackTrace');
      
      if (!mounted) return;
      
      setState(() {
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.getError(context),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _QuickDateChip extends StatelessWidget {
  final String label;
  final int days;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickDateChip({
    required this.label,
    required this.days,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.getAccent(context) 
              : AppColors.getSurfaceVariant(context).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppDimens.radiusRound),
          border: Border.all(
            color: isSelected 
                ? AppColors.getAccent(context) 
                : AppColors.getBorder(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected 
                ? Colors.white 
                : AppColors.getTextSecondary(context),
          ),
        ),
      ),
    );
  }
}