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

/// Librarian screen to scan reservation QR codes and issue books
class LibrarianReservationScanner extends StatefulWidget {
  const LibrarianReservationScanner({super.key});

  @override
  State<LibrarianReservationScanner> createState() => _LibrarianReservationScannerState();
}

class _LibrarianReservationScannerState extends State<LibrarianReservationScanner> {
  MobileScannerController? controller;
  bool _isProcessing = false;
  DateTime? _lastErrorTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().userModel;
      final libraryId = user?.libraryId ?? user?.uid;
      if (libraryId != null) {
        context.read<ReservationProvider>().listenToPendingReservations(libraryId);
      }
    });
    controller = MobileScannerController();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reservation Scanner'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'QR Scanner'),
              Tab(text: 'Pending Reservations'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildScannerTab(),
            _buildPendingReservationsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerTab() {
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
                controller: controller,
                onDetect: _handleQRScan,
              ),
            ),
          ),
        ),

        // Processing indicator
        if (_isProcessing) ...[
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
      ],
    );
  }

  Widget _buildPendingReservationsTab() {
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
                Icon(
                  Icons.pending_actions_rounded,
                  size: 64,
                  color: AppColors.textTertiary.withOpacity(0.5),
                ),
                const SizedBox(height: AppDimens.md),
                Text(
                  'No pending reservations',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textTertiary),
                ),
                const SizedBox(height: AppDimens.sm),
                Text(
                  'Pending reservations will appear here',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppDimens.pagePaddingH),
          itemCount: pendingReservations.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppDimens.sm),
          itemBuilder: (context, index) {
            return _PendingReservationCard(
              reservation: pendingReservations[index],
              onTap: () => _processReservation(pendingReservations[index]),
            );
          },
        );
      },
    );
  }

  void _handleQRScan(BarcodeCapture capture) async {
    if (_isProcessing || capture.barcodes.isEmpty) return;

    final qrData = capture.barcodes.first.rawValue;
    if (qrData == null || qrData.trim().isEmpty) return;

    // Only process if it looks like a reservation QR code
    if (!qrData.startsWith('RESERVATION:')) {
      // Silently ignore non-reservation QR codes to avoid spam
      return;
    }

    // Pause scanner to prevent multiple scans
    controller?.stop();

    setState(() {
      _isProcessing = true;
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

      // Validate library - reservation must be for this librarian's library
      final user = context.read<AuthProvider>().userModel;
      final librarianLibraryId = user?.libraryId;
      
      debugPrint('🔍 Library Validation:');
      debugPrint('  Librarian: ${user?.name} (${user?.uid})');
      debugPrint('  Librarian Library ID: $librarianLibraryId');
      debugPrint('  Reservation Library ID: ${reservation.libraryId}');
      debugPrint('  Reservation Library Name: ${reservation.libraryName}');
      
      if (librarianLibraryId == null) {
        throw Exception('Librarian library not found. Please contact support.');
      }

      if (reservation.libraryId != librarianLibraryId) {
        throw Exception('This reservation is for ${reservation.libraryName}. You can only collect reservations for your library.');
      }
      
      debugPrint('✅ Library validation passed');

      // Show collection dialog
      if (mounted) {
        await _processReservation(reservation);
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
        
        // Restart scanner after error with delay
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            controller?.start();
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _processReservation(Reservation reservation) async {
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

    // Validate library - reservation must be for this librarian's library
    final librarianLibraryId = user.libraryId;
    
    debugPrint('🔍 Processing Reservation - Library Validation:');
    debugPrint('  Librarian: ${user.name} (${user.uid})');
    debugPrint('  Librarian Library ID: $librarianLibraryId');
    debugPrint('  Reservation Library ID: ${reservation.libraryId}');
    debugPrint('  Reservation Library Name: ${reservation.libraryName}');
    
    if (librarianLibraryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Librarian library not found. Please contact support.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (reservation.libraryId != librarianLibraryId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('This reservation is for ${reservation.libraryName}. You can only collect reservations for your library.'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    
    debugPrint('✅ Library validation passed');

    // Navigate to processing screen instead of showing dialog
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationProcessingScreen(
          reservation: reservation,
        ),
      ),
    );

    // Handle result and restart scanner
    if (result == true && mounted) {
      // Success - scanner will restart automatically when we return
      debugPrint('✅ Books issued successfully, restarting scanner');
    }
    
    // Restart scanner after navigation with delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        controller?.start();
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

class _PendingReservationCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback onTap;

  const _PendingReservationCard({
    super.key,
    required this.reservation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                    ),
                    child: Text(
                      '${reservation.daysRemaining}d left',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.sm),

              // Books
              Text(
                'Books (${reservation.totalBooks}):',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              ...reservation.items.map((item) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Text(
                  '• ${item.bookTitle} (${item.quantity}x)',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )),

              const SizedBox(height: AppDimens.sm),
              
              // Action hint
              Row(
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 16,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to process collection',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}