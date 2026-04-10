import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/reservation_model.dart';
import '../providers/reservation_provider.dart';
import 'widgets/reservation_collection_dialog.dart';

/// Enhanced Librarian's reservation management screen with two divisions:
/// 1. Scan QR Codes - Scan and process reservation QR codes
/// 2. Manage Reservations - View, manage, and delete reservations
class EnhancedLibrarianReservationScreen extends StatefulWidget {
  EnhancedLibrarianReservationScreen({super.key});

  @override
  State<EnhancedLibrarianReservationScreen> createState() => _EnhancedLibrarianReservationScreenState();
}

class _EnhancedLibrarianReservationScreenState extends State<EnhancedLibrarianReservationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // QR Scanner variables
  QRViewController? _qrController;
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  bool _isProcessingQR = false;
  String? _lastProcessedCode;
  DateTime? _lastErrorTime;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    final user = context.read<AuthProvider>().userModel;
    if (user != null) {
      final libraryId = user.libraryId ?? user.uid;
      context.read<ReservationProvider>().listenToPendingReservations(libraryId);
    }
    
    // Set up periodic refresh
    _setupPeriodicRefresh();
  }

  void _setupPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final user = context.read<AuthProvider>().userModel;
      if (user != null) {
        final libraryId = user.libraryId ?? user.uid;
        context.read<ReservationProvider>().refreshPendingReservations(libraryId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservation Management'),
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
              icon: Icon(Icons.qr_code_scanner),
              text: 'Scan QR Codes',
            ),
            Tab(
              icon: Icon(Icons.manage_accounts),
              text: 'Manage Reservations',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQRScannerTab(),
          _buildManageReservationsTab(),
        ],
      ),
    );
  }

  Widget _buildQRScannerTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_scanner, size: 64, color: AppColors.primary),
          const SizedBox(height: AppDimens.md),
          Text(
            'QR Scanner',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppDimens.sm),
          Text(
            'Scan reservation QR codes here',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildManageReservationsTab() {
    return Consumer<ReservationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final pendingReservations = provider.pendingReservations;
        
        if (pendingReservations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: AppColors.textTertiary.withOpacity(0.5)),
                const SizedBox(height: AppDimens.md),
                Text(
                  'No Pending Reservations',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppDimens.lg),
          itemCount: pendingReservations.length,
          itemBuilder: (context, index) {
            final reservation = pendingReservations[index];
            return Card(
              child: ListTile(
                title: Text(reservation.userName),
                subtitle: Text('${reservation.totalBooks} books'),
                trailing: Text(reservation.status.displayName),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _qrController?.dispose();
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }
}