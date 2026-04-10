import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../auth/providers/auth_provider.dart';
import '../../books/models/book_model.dart';
import '../../books/providers/book_provider.dart';
import '../../library/models/library_model.dart';
import '../../library/providers/library_provider.dart';
import '../models/reservation_model.dart';
import '../providers/reservation_provider.dart';
import 'widgets/reservation_qr_dialog.dart';

/// Enhanced Reader's reservation page with three divisions:
/// 1. Reserve Books (select library and books)
/// 2. My Active Reservations (pending reservations with QR)
/// 3. Reservation History (collected/expired reservations)
class EnhancedReaderReservationScreen extends StatefulWidget {
  EnhancedReaderReservationScreen({super.key});

  @override
  State<EnhancedReaderReservationScreen> createState() => _EnhancedReaderReservationScreenState();
}

class _EnhancedReaderReservationScreenState extends State<EnhancedReaderReservationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    final uid = context.read<AuthProvider>().userModel?.uid;
    if (uid != null) {
      context.read<ReservationProvider>().listenToUserReservations(uid);
    }
    
    // Load libraries
    context.read<LibraryProvider>().initialize();
    
    // Set up periodic refresh
    _setupPeriodicRefresh();
  }

  void _setupPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final uid = context.read<AuthProvider>().userModel?.uid;
      if (uid != null) {
        context.read<ReservationProvider>().refreshUserReservations(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Reservations'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.add_shopping_cart),
              text: 'Reserve Books',
            ),
            Tab(
              icon: Icon(Icons.pending_actions),
              text: 'Active',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'History',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReserveBooksTab(),
          _buildActiveReservationsTab(),
          _buildReservationHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildReserveBooksTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books, size: 64, color: AppColors.primary),
          const SizedBox(height: AppDimens.md),
          Text(
            'Reserve Books',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppDimens.sm),
          Text(
            'Select a library and choose up to 3 books',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveReservationsTab() {
    return Consumer<ReservationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final activeReservations = provider.reservations
            .where((r) => r.status == ReservationStatus.pending && !r.isExpired)
            .toList();

        if (activeReservations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pending_actions, size: 64, color: AppColors.textTertiary.withOpacity(0.5)),
                const SizedBox(height: AppDimens.md),
                Text(
                  'No Active Reservations',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppDimens.lg),
          itemCount: activeReservations.length,
          itemBuilder: (context, index) {
            final reservation = activeReservations[index];
            return Card(
              child: ListTile(
                title: Text('Reservation #${reservation.id.substring(0, 8)}'),
                subtitle: Text('${reservation.totalBooks} books - ${reservation.daysRemaining} days left'),
                trailing: IconButton(
                  icon: const Icon(Icons.qr_code),
                  onPressed: () => _showReservationQR(context, reservation),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReservationHistoryTab() {
    return Consumer<ReservationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final historyReservations = provider.reservations
            .where((r) => r.status == ReservationStatus.collected || r.isExpired)
            .toList();

        if (historyReservations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: AppColors.textTertiary.withOpacity(0.5)),
                const SizedBox(height: AppDimens.md),
                Text(
                  'No Reservation History',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppDimens.lg),
          itemCount: historyReservations.length,
          itemBuilder: (context, index) {
            final reservation = historyReservations[index];
            return Card(
              child: ListTile(
                title: Text('Reservation #${reservation.id.substring(0, 8)}'),
                subtitle: Text('${reservation.totalBooks} books'),
                trailing: Text(reservation.status.displayName),
              ),
            );
          },
        );
      },
    );
  }

  void _showReservationQR(BuildContext context, Reservation reservation) {
    showDialog(
      context: context,
      builder: (ctx) => ReservationQRDialog(reservation: reservation),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }
}