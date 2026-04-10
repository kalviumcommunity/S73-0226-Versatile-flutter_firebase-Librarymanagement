import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/reservation_model.dart';
import '../providers/reservation_provider.dart';
import 'widgets/reservation_collection_dialog.dart';
import 'reservation_processing_screen.dart';

/// Combined librarian reservation screen with 2 tabs:
/// 1. Scan QR - Scan reservation QR codes
/// 2. Manage - View and manage all reservations
class LibrarianCombinedReservationScreen extends StatefulWidget {
  const LibrarianCombinedReservationScreen({super.key});

  @override
  State<LibrarianCombinedReservationScreen> createState() => _LibrarianCombinedReservationScreenState();
}

class _LibrarianCombinedReservationScreenState extends State<LibrarianCombinedReservationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // QR Scanner variables
  MobileScannerController? _qrController;
  bool _isProcessingQR = false;
  DateTime? _lastErrorTime;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _qrController = MobileScannerController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().userModel;
      if (user != null) {
        final libraryId = user.libraryId ?? user.uid;
        context.read<ReservationProvider>().listenToPendingReservations(libraryId);
      }
    });
    
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
        title: const Text('Reservations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Scan QR'),
            Tab(text: 'Manage'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScanTab(),
          _buildManageTab(),
        ],
      ),
    );
  }

  Widget _buildScanTab() {
    return Column(
      children: [
        // Instructions
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimens.lg),
          margin: const EdgeInsets.all(AppDimens.pagePaddingH),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(color: AppColors.accent.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.qr_code_scanner,
                color: AppColors.accent,
                size: 32,
              ),
              const SizedBox(height: AppDimens.sm),
              Text(
                'Scan Reservation QR Code',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppDimens.sm),
              Text(
                'Ask the reader to show their reservation QR code and scan it to process the book collection.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.accent,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),

        // QR Scanner
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(AppDimens.pagePaddingH),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              child: MobileScanner(
                controller: _qrController,
                onDetect: _handleQRScan,
              ),
            ),
          ),
        ),

        // Processing indicator
        if (_isProcessingQR) ...[
          Container(
            padding: const EdgeInsets.all(AppDimens.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppDimens.md),
                Text(
                  'Processing QR code...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],

        // Stats
        Container(
          padding: const EdgeInsets.all(AppDimens.md),
          child: Consumer<ReservationProvider>(
            builder: (context, provider, child) {
              final pendingCount = provider.pendingReservations.length;
              return Text(
                'Pending Reservations: $pendingCount',
                style: Theme.of(context).textTheme.titleMedium,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildManageTab() {
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
                const Text('No Pending Reservations'),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppDimens.pagePaddingH),
          itemCount: pendingReservations.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppDimens.sm),
          itemBuilder: (context, index) {
            final reservation = pendingReservations[index];
            return Card(
              child: ListTile(
                title: Text(reservation.userName),
                subtitle: Text('${reservation.totalBooks} books - ${reservation.daysRemaining} days left\nFee: ₹${reservation.reservationFee.toInt()} (${reservation.feeStatus.displayName})'),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: AppColors.success),
                      onPressed: () => _processReservation(reservation),
                      tooltip: 'Process',
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: AppColors.error),
                      onPressed: () => _expireReservation(reservation),
                      tooltip: 'Expire',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // QR Scanner methods
  void _handleQRScan(BarcodeCapture capture) async {
    if (_isProcessingQR || capture.barcodes.isEmpty) return;

    final qrData = capture.barcodes.first.rawValue;
    if (qrData == null || qrData.trim().isEmpty) return;

    // Only process if it looks like a reservation QR code
    if (!qrData.startsWith('RESERVATION:')) {
      // Silently ignore non-reservation QR codes to avoid spam
      return;
    }

    setState(() {
      _isProcessingQR = true;
    });

    try {
      // Parse QR data: RESERVATION:<reservationId>:<userId>
      final parts = qrData.split(':');
      if (parts.length != 3 || parts[0] != 'RESERVATION') {
        throw Exception('Invalid reservation QR code format');
      }

      final reservationId = parts[1];
      final userId = parts[2];

      // Validate reservation ID and user ID are not empty
      if (reservationId.trim().isEmpty || userId.trim().isEmpty) {
        throw Exception('Invalid reservation QR code data');
      }

      // Get reservation details and validate
      final reservation = await context.read<ReservationProvider>().getReservation(reservationId);
      if (reservation == null) {
        throw Exception('Reservation not found');
      }

      if (reservation.userId != userId) {
        throw Exception('QR code does not match reservation');
      }

      if (reservation.status != ReservationStatus.pending) {
        throw Exception('Reservation is not pending (Status: ${reservation.status.displayName})');
      }

      if (reservation.isExpired) {
        throw Exception('Reservation has expired');
      }

      // Show collection dialog
      if (mounted) {
        _processReservation(reservation);
      }
    } catch (e) {
      if (mounted) {
        // Prevent spam by limiting error messages to once every 3 seconds
        final now = DateTime.now();
        if (_lastErrorTime == null || now.difference(_lastErrorTime!).inSeconds >= 3) {
          _lastErrorTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingQR = false;
        });
      }
    }
  }

  void _processReservation(Reservation reservation) async {
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

    if (result == true && mounted) {
      // Switch to scanner tab after successful processing
      _tabController.animateTo(0);
      
      // Restart QR scanner after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _qrController?.start();
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Books issued successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _expireReservation(Reservation reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Expire Reservation'),
        content: Text('Are you sure you want to expire this reservation?\n\nThis will forfeit the ₹${reservation.reservationFee.toInt()} fee.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Expire'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await context.read<ReservationProvider>().expireReservation(reservation.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reservation expired'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _qrController?.dispose();
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }
}