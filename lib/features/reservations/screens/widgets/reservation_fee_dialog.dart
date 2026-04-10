import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';

/// Dialog to confirm reservation fee payment
class ReservationFeeDialog extends StatelessWidget {
  final int totalBooks;
  final double reservationFee;

  const ReservationFeeDialog({
    super.key,
    required this.totalBooks,
    required this.reservationFee,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.getSurface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      title: Row(
        children: [
          Icon(Icons.payment, color: AppColors.getWarning(context), size: 28),
          const SizedBox(width: AppDimens.sm),
          Text('Reservation Fee', style: TextStyle(color: AppColors.getTextPrimary(context))),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fee breakdown
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Books to Reserve:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.getTextPrimary(context),
                          ),
                    ),
                    Text(
                      '$totalBooks book${totalBooks > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextPrimary(context),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reservation Fee:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.getTextPrimary(context),
                          ),
                    ),
                    Text(
                      '₹${reservationFee.toInt()}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.getWarning(context),
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppDimens.lg),
          
          // Fee policy explanation
          Container(
            padding: const EdgeInsets.all(AppDimens.md),
            decoration: BoxDecoration(
              color: AppColors.getPrimary(context).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.getPrimary(context), size: 20),
                    const SizedBox(width: AppDimens.sm),
                    Text(
                      'Fee Policy',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.getPrimary(context),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.sm),
                _buildPolicyPoint(
                  context,
                  Icons.check_circle_outline,
                  'Fee is fully refundable if books are collected within 3 days',
                  AppColors.getSuccess(context),
                ),
                const SizedBox(height: AppDimens.xs),
                _buildPolicyPoint(
                  context,
                  Icons.cancel_outlined,
                  'Fee is forfeited if reservation expires (after 3 days)',
                  AppColors.getError(context),
                ),
                const SizedBox(height: AppDimens.xs),
                _buildPolicyPoint(
                  context,
                  Icons.payment,
                  'Fee can be paid at the library when collecting books',
                  AppColors.getPrimary(context),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppDimens.lg),
          
          // Payment notice
          Container(
            padding: const EdgeInsets.all(AppDimens.md),
            decoration: BoxDecoration(
              color: AppColors.getAccent(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              border: Border.all(color: AppColors.getAccent(context).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.store, color: AppColors.getAccent(context), size: 20),
                const SizedBox(width: AppDimens.sm),
                Expanded(
                  child: Text(
                    'You can pay the ₹${reservationFee.toInt()} fee at the library when you collect your reserved books.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.getAccent(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppColors.getTextSecondary(context)),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.check_circle, size: 18),
          label: const Text('Confirm Reservation'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.getAccent(context),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyPoint(BuildContext context, IconData icon, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppDimens.sm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}