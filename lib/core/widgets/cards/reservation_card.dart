import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../features/reservations/models/reservation_model.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';
import '../badges/status_badge.dart';

class ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback? onViewQR;
  final VoidCallback? onCancel;

  const ReservationCard({
    super.key,
    required this.reservation,
    this.onViewQR,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkOrange : AppColors.orange;
    final accentColor = isDark ? AppColors.darkYellow : AppColors.yellow;
    final dateFormat = DateFormat('MMM dd, yyyy');
    final status = reservation.isExpired ? ReservationStatus.expired : reservation.status;

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
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Reservation #${reservation.id.substring(0, 8)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: AppDimens.md),
              // Books list
              ...reservation.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        // Book cover thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
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
                      'Library: ${reservation.libraryName}',
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
              // Reservation date
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: AppDimens.iconSm,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Reserved: ${dateFormat.format(reservation.reservationDate)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.sm),
              // Expiry date
              Row(
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: AppDimens.iconSm,
                    color: reservation.isExpired ? AppColors.error : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Expires: ${dateFormat.format(reservation.expiryDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: reservation.isExpired ? AppColors.error : null,
                      fontWeight: reservation.isExpired ? FontWeight.w600 : null,
                    ),
                  ),
                ],
              ),
              // Days remaining (if pending and not expired)
              if (status == ReservationStatus.pending && !reservation.isExpired) ...[
                const SizedBox(height: AppDimens.sm),
                Text(
                  '${reservation.daysRemaining} days remaining',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: reservation.daysRemaining <= 1 ? AppColors.error : AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              // Action buttons
              if (status == ReservationStatus.pending && !reservation.isExpired && (onViewQR != null || onCancel != null)) ...[
                const SizedBox(height: AppDimens.md),
                Row(
                  children: [
                    if (onViewQR != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onViewQR,
                          icon: const Icon(Icons.qr_code, size: 18),
                          label: const Text('View QR'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            side: BorderSide(color: AppColors.accent.withOpacity(0.4)),
                          ),
                        ),
                      ),
                    if (onViewQR != null && onCancel != null) const SizedBox(width: 8),
                    if (onCancel != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onCancel,
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(color: AppColors.error.withOpacity(0.4)),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
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

  Widget _buildStatusBadge(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return StatusBadge(
          label: 'Pending',
          type: BadgeType.pending,
        );
      case ReservationStatus.collected:
        return StatusBadge(
          label: 'Collected',
          type: BadgeType.available,
        );
      case ReservationStatus.expired:
        return StatusBadge(
          label: 'Expired',
          type: BadgeType.unavailable,
        );
    }
  }
}
