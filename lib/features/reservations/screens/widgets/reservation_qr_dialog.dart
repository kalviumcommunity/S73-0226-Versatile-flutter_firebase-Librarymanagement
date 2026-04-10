import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../models/reservation_model.dart';

/// Dialog to display reservation QR code
class ReservationQRDialog extends StatelessWidget {
  final Reservation reservation;

  const ReservationQRDialog({
    super.key,
    required this.reservation,
  });

  @override
  Widget build(BuildContext context) {
    // QR Data format: RESERVATION:<reservationId>:<userId>
    final qrData = 'RESERVATION:${reservation.id}:${reservation.userId}';
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      title: Row(
        children: [
          Icon(
            Icons.qr_code_rounded,
            color: AppColors.accent,
            size: 24,
          ),
          const SizedBox(width: AppDimens.sm),
          const Expanded(child: Text('Reservation QR Code')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // QR Code
            Container(
              padding: const EdgeInsets.all(AppDimens.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: SizedBox(
                width: 200,
                height: 200,
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E3A8A),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.lg),

            // Reservation details
            Container(
              padding: const EdgeInsets.all(AppDimens.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reservation Details',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppDimens.sm),
                  
                  // Library name
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.sm,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                      border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_library_rounded,
                          size: 14,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            reservation.libraryName,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimens.sm),
                  
                  // Books list
                  ...reservation.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.book, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${item.bookTitle} (${item.quantity}x)',
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )),
                  
                  const SizedBox(height: AppDimens.sm),
                  const Divider(),
                  const SizedBox(height: AppDimens.sm),
                  
                  // Expiry info
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: reservation.daysRemaining <= 1 
                            ? AppColors.error 
                            : AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Expires: ${_formatDate(reservation.expiryDate)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: reservation.daysRemaining <= 1 
                                  ? AppColors.error 
                                  : AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  
                  if (reservation.daysRemaining > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${reservation.daysRemaining} days remaining',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: AppDimens.lg),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(AppDimens.md),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.accent,
                    size: 20,
                  ),
                  const SizedBox(height: AppDimens.sm),
                  Text(
                    'Show this QR code to the librarian at ${reservation.libraryName} to collect your reserved books.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.accent,
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}