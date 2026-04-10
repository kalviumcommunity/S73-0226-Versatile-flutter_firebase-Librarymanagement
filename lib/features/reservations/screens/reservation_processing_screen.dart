import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/reservation_model.dart';
import '../providers/reservation_provider.dart';

/// Dedicated screen for processing reservation collection
/// This replaces the dialog approach to avoid context issues
class ReservationProcessingScreen extends StatefulWidget {
  final Reservation reservation;

  const ReservationProcessingScreen({
    super.key,
    required this.reservation,
  });

  @override
  State<ReservationProcessingScreen> createState() => _ReservationProcessingScreenState();
}

class _ReservationProcessingScreenState extends State<ReservationProcessingScreen> {
  DateTime _dueDate = DateTime.now().add(const Duration(days: 14)); // Default 14 days
  bool _isProcessing = false;
  bool _isSuccess = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Reserved Books'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.pagePaddingH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimens.lg),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 48,
                  ),
                  const SizedBox(height: AppDimens.sm),
                  Text(
                    'Reservation Validated',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppDimens.sm),
                  Text(
                    'Ready to issue books to the reader',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.success,
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.xl),

            // Reader information
            _buildSection(
              'Reader Information',
              Icons.person,
              Container(
                padding: const EdgeInsets.all(AppDimens.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, size: 20, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.reservation.userName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.email, size: 20, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.reservation.userEmail,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppDimens.xl),

            // Reserved books
            _buildSection(
              'Reserved Books (${widget.reservation.totalBooks})',
              Icons.menu_book,
              Column(
                children: widget.reservation.items.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: AppDimens.sm),
                  padding: const EdgeInsets.all(AppDimens.md),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                        child: item.bookThumbnail != null
                            ? Image.network(
                                item.bookThumbnail!,
                                width: 50,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 50,
                                  height: 70,
                                  color: AppColors.surfaceVariant,
                                  child: const Icon(Icons.menu_book, size: 24),
                                ),
                              )
                            : Container(
                                width: 50,
                                height: 70,
                                color: AppColors.surfaceVariant,
                                child: const Icon(Icons.menu_book, size: 24),
                              ),
                      ),
                      const SizedBox(width: AppDimens.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.bookTitle,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Quantity: ${item.quantity}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
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

            const SizedBox(height: AppDimens.xl),

            // Due date selection
            _buildSection(
              'Set Due Date',
              Icons.calendar_today,
              Container(
                padding: const EdgeInsets.all(AppDimens.md),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 24, color: AppColors.accent),
                        const SizedBox(width: AppDimens.md),
                        Expanded(
                          child: Text(
                            'Due Date: ${_formatDate(_dueDate)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        TextButton(
                          onPressed: _selectDueDate,
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.md),
                    
                    // Quick date options
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
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
            ),

            const SizedBox(height: AppDimens.xl),

            // Reservation info
            Container(
              padding: const EdgeInsets.all(AppDimens.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Reservation Details',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.warning,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reserved: ${_formatDate(widget.reservation.reservationDate)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Expires: ${_formatDate(widget.reservation.expiryDate)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Library: ${widget.reservation.libraryName}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.xxl),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppDimens.pagePaddingH),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isProcessing ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: (_isProcessing || _isSuccess) ? null : _issueBooks,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSuccess ? AppColors.success : AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : _isSuccess
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, size: 20),
                              SizedBox(width: 8),
                              Text('Success! Returning...'),
                            ],
                          )
                        : const Text('Issue Books'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 24, color: AppColors.accent),
            const SizedBox(width: AppDimens.sm),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.md),
        content,
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
    print('🔄 Processing screen: _issueBooks() called');
    if (_isProcessing) {
      print('⚠️ Processing screen: Already processing, returning');
      return;
    }
    
    print('🔄 Processing screen: Setting processing state to true');
    setState(() {
      _isProcessing = true;
    });

    try {
      final user = context.read<AuthProvider>().userModel;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      print('🔄 Starting book issue process...');
      print('🔄 Reservation ID: ${widget.reservation.id}');
      print('🔄 Due Date: $_dueDate');
      print('🔄 Issued By: ${user.uid}');

      final reservationProvider = context.read<ReservationProvider>();
      print('🔄 Processing screen: Calling convertToBorrowTransaction...');
      final transaction = await reservationProvider.convertToBorrowTransaction(
        widget.reservation.id,
        _dueDate,
        user.uid,
      );

      print('🔄 Processing screen: convertToBorrowTransaction completed');
      print('🔄 Processing screen: Transaction result: ${transaction != null ? 'SUCCESS' : 'FAILED'}');

      if (!mounted) return;

      if (transaction != null) {
        try {
          print('✅ Transaction created: ${transaction.id}');
          print('🔄 Processing screen: Starting success flow...');
          
          // Update to success state
          setState(() {
            _isProcessing = false;
            _isSuccess = true;
          });
          
          print('🔄 Processing screen: Success state updated');
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text('Books issued successfully! Returning to scanner...')),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
          
          print('🔄 Processing screen: Snackbar shown, scheduling navigation...');
          
          // Navigate back after showing success message
          Future.delayed(const Duration(milliseconds: 1500), () {
            print('🔄 Processing screen: Navigation delay completed, checking mounted...');
            if (mounted) {
              print('🔄 Processing screen: Widget is mounted, calling Navigator.pop()...');
              Navigator.pop(context, true);
              print('✅ Processing screen: Navigation completed successfully!');
            } else {
              print('❌ Processing screen: Widget not mounted, skipping navigation');
            }
          });
          
          // Refresh data in background
          Future.delayed(const Duration(milliseconds: 2000), () {
            print('🔄 Processing screen: Starting background refresh...');
            reservationProvider.refreshUserReservations(widget.reservation.userId);
            reservationProvider.refreshPendingReservations(widget.reservation.libraryId);
            print('✅ Processing screen: Background refresh completed');
          });
        } catch (e, stackTrace) {
          print('❌ Processing screen: Error in success flow: $e');
          print('❌ Processing screen: Stack trace: $stackTrace');
        }
      } else {
        throw Exception(reservationProvider.error ?? 'Failed to issue books');
      }
    } catch (e) {
      print('❌ Error issuing books: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isProcessing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.accent 
              : AppColors.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(AppDimens.radiusRound),
          border: Border.all(
            color: isSelected 
                ? AppColors.accent 
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected 
                ? Colors.white 
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}