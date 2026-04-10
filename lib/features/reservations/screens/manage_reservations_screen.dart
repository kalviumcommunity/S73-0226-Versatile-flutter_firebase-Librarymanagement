import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/reservation_model.dart';
import '../providers/reservation_provider.dart';
import 'widgets/reservation_collection_dialog.dart';
import 'reservation_processing_screen.dart';

/// Librarian screen to manage reservations (updated for new model).
class ManageReservationsScreen extends StatefulWidget {
  const ManageReservationsScreen({super.key});

  @override
  State<ManageReservationsScreen> createState() =>
      _ManageReservationsScreenState();
}

class _ManageReservationsScreenState extends State<ManageReservationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().userModel;
      final libraryId = user?.libraryId ?? user?.uid;
      if (libraryId != null) {
        context.read<ReservationProvider>().listenToLibraryReservations(libraryId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReservationProvider>();
    final pending = provider.reservations
        .where((r) =>
            r.status == ReservationStatus.pending && !r.isExpired)
        .toList();
    final history = provider.reservations
        .where((r) =>
            r.status != ReservationStatus.pending || r.isExpired)
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Reservations'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildList(pending, isPending: true),
                  _buildList(history, isPending: false),
                ],
              ),
      ),
    );
  }

  Widget _buildList(List<Reservation> items, {required bool isPending}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending
                  ? Icons.pending_actions_rounded
                  : Icons.history_rounded,
              size: 56,
              color: AppColors.textTertiary.withOpacity(0.4),
            ),
            const SizedBox(height: AppDimens.md),
            Text(
              isPending ? 'No pending reservations' : 'No reservation history',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppDimens.pagePaddingH),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppDimens.sm),
      itemBuilder: (context, index) {
        return _ReservationTile(
          reservation: items[index],
          isPending: isPending,
        );
      },
    );
  }
}

class _ReservationTile extends StatelessWidget {
  final Reservation reservation;
  final bool isPending;

  const _ReservationTile({
    required this.reservation,
    required this.isPending,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final status =
        reservation.isExpired ? ReservationStatus.expired : reservation.status;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info and status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation.userName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        reservation.userEmail,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
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
            Text(
              'Books (${reservation.totalBooks}):',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            ...reservation.items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    child: item.bookThumbnail != null
                        ? Image.network(
                            item.bookThumbnail!,
                            width: 30,
                            height: 42,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 30,
                              height: 42,
                              color: AppColors.surfaceVariant,
                              child: const Icon(Icons.menu_book, size: 16),
                            ),
                          )
                        : Container(
                            width: 30,
                            height: 42,
                            color: AppColors.surfaceVariant,
                            child: const Icon(Icons.menu_book, size: 16),
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
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Qty: ${item.quantity}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),

            const SizedBox(height: AppDimens.sm),
            const Divider(),
            const SizedBox(height: AppDimens.sm),

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
                      if (status == ReservationStatus.collected && reservation.collectedDate != null)
                        Text(
                          'Collected: ${dateFormat.format(reservation.collectedDate!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                    ],
                  ),
                ),

                // Process button for pending reservations
                if (isPending && status == ReservationStatus.pending && !reservation.isExpired)
                  Flexible(
                    child: ElevatedButton(
                      onPressed: () => _processReservation(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Process'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _processReservation(BuildContext context) async {
    final user = context.read<AuthProvider>().userModel;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: User not authenticated'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final reservationProvider = context.read<ReservationProvider>();

    // Navigate to processing screen instead of showing dialog
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationProcessingScreen(
          reservation: reservation,
        ),
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Books issued successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
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
