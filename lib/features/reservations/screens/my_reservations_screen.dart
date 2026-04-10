import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/reservation_model.dart';
import '../providers/reservation_provider.dart';

/// Reader's view of their reservations (updated for new model).
class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().userModel?.uid;
      if (uid != null) {
        context.read<ReservationProvider>().listenToUserReservations(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reservationProvider = context.watch<ReservationProvider>();
    final reservations = reservationProvider.reservations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reservations'),
      ),
      body: reservationProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : reservations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_outline_rounded,
                        size: 64,
                        color: AppColors.textTertiary.withOpacity(0.5),
                      ),
                      const SizedBox(height: AppDimens.md),
                      Text(
                        'No reservations yet',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textTertiary),
                      ),
                      const SizedBox(height: AppDimens.sm),
                      Text(
                        'Reserve books from the Browse tab',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppDimens.pagePaddingH),
                  itemCount: reservations.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppDimens.sm),
                  itemBuilder: (context, index) {
                    return _ReservationCard(reservation: reservations[index]);
                  },
                ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final Reservation reservation;

  const _ReservationCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final status = reservation.isExpired ? ReservationStatus.expired : reservation.status;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Reservation #${reservation.id.substring(0, 8)}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                  ),
                  child: Text(
                    status.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.sm),

            // Books list
            ...reservation.items.map((item) => Padding(
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
                              color: AppColors.surfaceVariant,
                              child: const Icon(Icons.menu_book, size: 20),
                            ),
                          )
                        : Container(
                            width: 40,
                            height: 56,
                            color: AppColors.surfaceVariant,
                            child: const Icon(Icons.menu_book, size: 20),
                          ),
                  ),
                  const SizedBox(width: AppDimens.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.bookTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Quantity: ${item.quantity}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),

            const Divider(),

            // Dates and actions
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reserved: ${dateFormat.format(reservation.reservationDate)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Expires: ${dateFormat.format(reservation.expiryDate)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: reservation.isExpired
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                      ),
                      if (status == ReservationStatus.pending && !reservation.isExpired)
                        Text(
                          '${reservation.daysRemaining} days remaining',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: reservation.daysRemaining <= 1
                                    ? AppColors.error
                                    : AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                    ],
                  ),
                ),

                // QR button for pending reservations
                if (status == ReservationStatus.pending && !reservation.isExpired)
                  Flexible(
                    child: ElevatedButton.icon(
                      onPressed: () => _showReservationQR(context),
                      icon: const Icon(Icons.qr_code, size: 16),
                      label: const Text('QR Code'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReservationQR(BuildContext context) {
    // QR Data format: RESERVATION:<reservationId>:<userId>
    final qrData = 'RESERVATION:${reservation.id}:${reservation.userId}';
    final dateFormat = DateFormat('dd MMM yyyy');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.qr_code_rounded, color: AppColors.accent, size: 22),
            const SizedBox(width: 8),
            const Expanded(child: Text('Reservation QR')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
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
              const SizedBox(height: 12),
              Text(
                'Total Books: ${reservation.totalBooks}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Expires: ${dateFormat.format(reservation.expiryDate)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                'Show this QR to the librarian\nto get your books issued.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return AppColors.warning;
      case ReservationStatus.collected:
        return AppColors.success;
      case ReservationStatus.expired:
        return AppColors.error;
    }
  }
}
