import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../books/providers/book_provider.dart';
import '../models/borrow_transaction_model.dart';
import '../providers/borrow_transaction_provider.dart';

/// Librarian screen to return books via QR scanning
class LibrarianReturnScreen extends StatefulWidget {
  final String libraryId;

  const LibrarianReturnScreen({
    super.key,
    required this.libraryId,
  });

  @override
  State<LibrarianReturnScreen> createState() => _LibrarianReturnScreenState();
}

class _LibrarianReturnScreenState extends State<LibrarianReturnScreen> {
  // Scan transaction QR code
  Future<void> _scanTransactionQR() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const _QRScannerScreen(title: 'Scan Transaction QR Code'),
      ),
    );
    if (result == null || !mounted) return;

    // Support both old and new QR formats
    if (!result.startsWith('LIB_TRANSACTION:') && !result.startsWith('TRANSACTION:')) {
      _showError('Invalid QR code. Please scan a transaction QR code.');
      return;
    }

    final parts = result.split(':');
    String transactionId;
    String? qrLibraryId;
    
    if (result.startsWith('TRANSACTION:')) {
      // New format: TRANSACTION:<id>:<userId>:<libraryId>
      if (parts.length < 4) {
        _showError('Invalid QR code format.');
        return;
      }
      transactionId = parts[1];
      qrLibraryId = parts[3];
    } else {
      // Old format: LIB_TRANSACTION:<id>
      if (parts.length < 2) {
        _showError('Invalid QR code format.');
        return;
      }
      transactionId = parts[1];
    }

    // Load transaction
    final transaction = await context
        .read<BorrowTransactionProvider>()
        .getTransaction(transactionId);

    if (transaction == null) {
      if (mounted) {
        _showError('Transaction not found or already returned.');
      }
      return;
    }

    if (transaction.status != TransactionStatus.active) {
      if (mounted) {
        _showError('This transaction has already been returned.');
      }
      return;
    }

    // Validate library - transaction must be from this library
    if (transaction.libraryId != widget.libraryId) {
      if (mounted) {
        _showError('This transaction is from ${transaction.libraryName}. You can only process returns for your library.');
      }
      return;
    }

    // Double-check with QR libraryId if available
    if (qrLibraryId != null && qrLibraryId != widget.libraryId) {
      if (mounted) {
        _showError('This transaction is from a different library. You can only process returns for your library.');
      }
      return;
    }

    if (mounted) {
      _showReturnConfirmation(transaction);
    }
  }

  // Show manual search dialog
  void _showManualSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLg)),
      ),
      builder: (ctx) => _ManualSearchSheet(libraryId: widget.libraryId),
    );
  }

  // Show return confirmation dialog
  void _showReturnConfirmation(BorrowTransaction transaction) {
    final fine = transaction.calculatedFine;
    final dateFormat = DateFormat('dd MMM yyyy');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.assignment_return_rounded,
                color: AppColors.accent, size: 22),
            const SizedBox(width: 8),
            const Expanded(child: Text('Confirm Return')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'Reader', value: transaction.userName),
              _DetailRow(label: 'Email', value: transaction.userEmail),
              _DetailRow(
                  label: 'Issue Date',
                  value: dateFormat.format(transaction.issueDate)),
              _DetailRow(
                  label: 'Due Date',
                  value: dateFormat.format(transaction.dueDate)),
              const SizedBox(height: 12),
              const Text(
                'Books:',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ...transaction.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.book, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.bookTitle,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          '×${item.quantity}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )),
              if (transaction.isOverdue) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_rounded,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Overdue! Fine: ₹${fine.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _returnTransaction(transaction.id);
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Confirm Return'),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.success),
          ),
        ],
      ),
    );
  }

  // Return transaction
  Future<void> _returnTransaction(String transactionId) async {
    final success = await context
        .read<BorrowTransactionProvider>()
        .returnTransaction(transactionId);

    if (mounted) {
      if (success) {
        // Force refresh book provider to update stock immediately
        // This is needed because Firestore snapshots don't always trigger
        // immediately after batch updates with FieldValue.increment()
        context.read<BookProvider>().forceRefresh();
        
        _showSuccess('Books returned successfully!');
      } else {
        final error = context.read<BorrowTransactionProvider>().error;
        _showError(error ?? 'Failed to return books.');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Return Books'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.pagePaddingH),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.qr_code_scanner_rounded,
                size: 80,
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
              const SizedBox(height: AppDimens.lg),
              Text(
                'Scan Transaction QR Code',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimens.sm),
              Text(
                'Ask the reader to show their transaction QR code from the app',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimens.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _scanTransactionQR,
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 24),
                  label: const Text('Scan QR Code'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showManualSearch,
                  icon: const Icon(Icons.search, size: 20),
                  label: const Text('Manual Search'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Manual search sheet
class _ManualSearchSheet extends StatefulWidget {
  final String libraryId;

  const _ManualSearchSheet({required this.libraryId});

  @override
  State<_ManualSearchSheet> createState() => _ManualSearchSheetState();
}

class _ManualSearchSheetState extends State<_ManualSearchSheet> {
  final _searchController = TextEditingController();
  List<BorrowTransaction> _results = [];
  bool _isSearching = false;
  String _searchType = 'email'; // 'email' or 'name'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);

    final results = _searchType == 'email'
        ? await context
            .read<BorrowTransactionProvider>()
            .searchByEmail(query, widget.libraryId)
        : await context
            .read<BorrowTransactionProvider>()
            .searchByName(query, widget.libraryId);

    setState(() {
      _results = results;
      _isSearching = false;
    });
  }

  void _selectTransaction(BorrowTransaction transaction) {
    Navigator.pop(context);
    // Show confirmation dialog in parent
    final parentState =
        context.findAncestorStateOfType<_LibrarianReturnScreenState>();
    parentState?._showReturnConfirmation(transaction);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Manual Search',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.md),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'email',
                        label: Text('Email'),
                        icon: Icon(Icons.email_outlined, size: 16),
                      ),
                      ButtonSegment(
                        value: 'name',
                        label: Text('Name'),
                        icon: Icon(Icons.person_outline, size: 16),
                      ),
                    ],
                    selected: {_searchType},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _searchType = newSelection.first;
                        _results = [];
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: _searchType == 'email'
                          ? 'Enter reader email'
                          : 'Enter reader name',
                      prefixIcon: Icon(
                        _searchType == 'email'
                            ? Icons.email_outlined
                            : Icons.person_outline,
                        size: 20,
                      ),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: AppDimens.sm),
                ElevatedButton(
                  onPressed: _isSearching ? null : _search,
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(80, 52)),
                  child: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.md),
            if (_results.isEmpty && !_isSearching)
              const Padding(
                padding: EdgeInsets.all(AppDimens.lg),
                child: Text(
                  'No active transactions found',
                  style: TextStyle(color: AppColors.textTertiary),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final transaction = _results[index];
                    final dateFormat = DateFormat('dd MMM yyyy');
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppDimens.sm),
                      child: ListTile(
                        title: Text(transaction.userName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(transaction.userEmail,
                                style: const TextStyle(fontSize: 12)),
                            Text(
                              '${transaction.totalBooks} books · Due: ${dateFormat.format(transaction.dueDate)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: transaction.isOverdue
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        trailing: transaction.isOverdue
                            ? const Icon(Icons.warning_rounded,
                                color: AppColors.error)
                            : const Icon(Icons.chevron_right),
                        onTap: () => _selectTransaction(transaction),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Detail row widget
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// QR Scanner Screen
class _QRScannerScreen extends StatefulWidget {
  final String title;

  const _QRScannerScreen({required this.title});

  @override
  State<_QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<_QRScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _hasScanned = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _scannerController,
              builder: (_, state, __) {
                return Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                );
              },
            ),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android_rounded),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              if (_hasScanned) return;
              final barcode = capture.barcodes.firstOrNull;
              if (barcode?.rawValue == null) return;

              _hasScanned = true;
              Navigator.pop(context, barcode!.rawValue);
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accent, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Text(
              'Point the camera at a QR code',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
