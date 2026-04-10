import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/widgets/cards/reservation_card.dart';
import '../../../core/widgets/empty_states/empty_state_widget.dart';
import '../../../shared/services/payment_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../books/models/book_model.dart';
import '../../books/providers/book_provider.dart';
import '../../library/providers/library_provider.dart';
import '../models/reservation_model.dart';
import '../providers/reservation_provider.dart';
import 'widgets/reservation_qr_dialog.dart';

/// Reader's reservation page - search and reserve books
class ReaderReservationScreen extends StatefulWidget {
  const ReaderReservationScreen({super.key});

  @override
  State<ReaderReservationScreen> createState() => _ReaderReservationScreenState();
}

class _ReaderReservationScreenState extends State<ReaderReservationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, int> _selectedBooks = {}; // bookId -> quantity
  bool _isSearching = false;
  List<BookModel> _searchResults = [];
  String? _selectedLibraryId;
  String? _selectedLibraryName;

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthProvider>().userModel?.uid;
    if (uid != null) {
      context.read<ReservationProvider>().listenToUserReservations(uid);
    }
    
    // Set up periodic refresh to catch status updates
    _setupPeriodicRefresh();
  }

  void _setupPeriodicRefresh() {
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final uid = context.read<AuthProvider>().userModel?.uid;
      if (uid != null) {
        // Refresh reservations to catch any status updates
        context.read<ReservationProvider>().refreshUserReservations(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reservations'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Reserve Books'),
              Tab(text: 'Active'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildReserveTab(),
            _buildActiveReservationsTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildReserveTab() {
    final totalSelected = _selectedBooks.values.fold(0, (sum, qty) => sum + qty);
    final bookProvider = context.watch<BookProvider>();
    final libraryProvider = context.watch<LibraryProvider>();
    final reservationProvider = context.watch<ReservationProvider>();
    final memberships = libraryProvider.memberships;
    
    // Calculate existing active reservations for selected library
    int existingReservationsCount = 0;
    if (_selectedLibraryId != null) {
      final libraryReservations = reservationProvider.reservations
          .where((r) => 
              r.libraryId == _selectedLibraryId && 
              r.status == ReservationStatus.pending && 
              !r.isExpired)
          .toList();
      
      existingReservationsCount = libraryReservations
          .fold(0, (sum, r) => sum + r.items.fold(0, (itemSum, item) => itemSum + item.quantity));
      
      // Debug: Print to console
      print('DEBUG: Selected library: $_selectedLibraryId ($_selectedLibraryName)');
      print('DEBUG: Total reservations: ${reservationProvider.reservations.length}');
      print('DEBUG: Library reservations: ${libraryReservations.length}');
      print('DEBUG: Existing books count: $existingReservationsCount');
    }
    
    // Calculate remaining slots for this library
    final remainingSlots = (3 - existingReservationsCount).clamp(0, 3);
    final canReserveMore = remainingSlots > 0;
    
    // Filter books by selected library
    final availableBooks = _selectedLibraryId != null
        ? bookProvider.books.where((book) => 
            book.libraryId == _selectedLibraryId && book.availableCopies > 0).toList()
        : <BookModel>[];
    
    // Show search results or all books from selected library
    final displayBooks = _searchResults.isEmpty && _searchController.text.isEmpty
        ? availableBooks
        : _searchResults;
    
    return Column(
      children: [
        // Step 1: Library Selection
        Container(
          padding: const EdgeInsets.all(AppDimens.pagePaddingH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. Select Library',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppDimens.sm),
              
              if (memberships.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppDimens.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: AppDimens.sm),
                      Expanded(
                        child: Text(
                          'Please join a library first to reserve books',
                          style: TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: _selectedLibraryId,
                  decoration: InputDecoration(
                    hintText: 'Choose a library',
                    prefixIcon: const Icon(Icons.local_library_rounded, size: 20),
                    filled: true,
                    fillColor: AppColors.darkSurface,
                  ),
                  items: memberships.map((membership) {
                    return DropdownMenuItem(
                      value: membership.libraryId,
                      child: Text(
                        membership.libraryName,
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLibraryId = value;
                      _selectedLibraryName = memberships
                          .firstWhere((m) => m.libraryId == value)
                          .libraryName;
                      _selectedBooks.clear(); // Clear selections when library changes
                      _searchResults.clear();
                      _searchController.clear();
                    });
                  },
                ),
            ],
          ),
        ),

        // Show rest only if library is selected
        if (_selectedLibraryId != null) ...[
          // Show existing reservations warning if at limit
          if (!canReserveMore)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppDimens.pagePaddingH),
              padding: const EdgeInsets.all(AppDimens.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                  const SizedBox(width: AppDimens.sm),
                  Expanded(
                    child: Text(
                      'You have reached the limit of 3 active reservations for $_selectedLibraryName. Collect or cancel existing reservations to reserve more.',
                      style: TextStyle(color: AppColors.warning, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          
          if (!canReserveMore)
            const SizedBox(height: AppDimens.sm),
          
          // Step 2: Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePaddingH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '2. Search & Select Books',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (existingReservationsCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                        ),
                        child: Text(
                          '$existingReservationsCount/3 reserved',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimens.sm),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search books in $_selectedLibraryName...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults.clear();
                                _isSearching = false;
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: _onSearchChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.sm),

          // Selected books summary
          if (_selectedBooks.isNotEmpty) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: AppDimens.pagePaddingH),
              padding: const EdgeInsets.all(AppDimens.md),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.bookmark_added, color: Colors.white, size: 20),
                      const SizedBox(width: AppDimens.sm),
                      Expanded(
                        child: Text(
                          'Selected: $totalSelected/${remainingSlots} available slots',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'From $_selectedLibraryName',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: AppDimens.sm),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: totalSelected > 0 ? _createReservation : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Confirm & Reserve',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.sm),
          ],

          // Books list
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : displayBooks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 64,
                              color: AppColors.darkTextTertiary.withOpacity(0.5),
                            ),
                            const SizedBox(height: AppDimens.md),
                            Text(
                              _searchController.text.isNotEmpty 
                                  ? 'No books found'
                                  : 'No available books',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.darkTextSecondary),
                            ),
                            const SizedBox(height: AppDimens.sm),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'Try a different search term'
                                  : 'Check back later for available books',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.darkTextTertiary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // Info banner
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: AppDimens.pagePaddingH),
                            padding: const EdgeInsets.all(AppDimens.sm),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                                const SizedBox(width: AppDimens.sm),
                                Expanded(
                                  child: Text(
                                    canReserveMore
                                        ? 'You can reserve up to $remainingSlots more ${remainingSlots == 1 ? "book" : "books"} from $_selectedLibraryName'
                                        : 'Reservation limit reached for $_selectedLibraryName',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppDimens.sm),
                          
                          // Books list
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.all(AppDimens.pagePaddingH),
                              itemCount: displayBooks.length,
                              separatorBuilder: (_, __) => const SizedBox(height: AppDimens.sm),
                              itemBuilder: (context, index) {
                                final book = displayBooks[index];
                                final selectedQty = _selectedBooks[book.id] ?? 0;
                                return _BookSelectionCard(
                                  key: ValueKey(book.id),
                                  book: book,
                                  selectedQuantity: selectedQty,
                                  totalSelected: totalSelected,
                                  maxAllowed: remainingSlots,
                                  onQuantityChanged: (qty) {
                                    setState(() {
                                      if (qty > 0) {
                                        _selectedBooks[book.id] = qty;
                                      } else {
                                        _selectedBooks.remove(book.id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
          ),
        ] else
          // Show instruction when no library selected
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_library_rounded,
                    size: 64,
                    color: AppColors.darkTextTertiary.withOpacity(0.5),
                  ),
                  const SizedBox(height: AppDimens.md),
                  Text(
                    'Select a library to start',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppColors.darkTextSecondary),
                  ),
                  const SizedBox(height: AppDimens.sm),
                  Text(
                    'Choose a library from the dropdown above',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.darkTextTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
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
          return EmptyStateWidget(
            icon: Icons.pending_actions,
            title: 'No Active Reservations',
            message: 'Your pending reservations will appear here',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppDimens.pagePaddingH),
          itemCount: activeReservations.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final reservation = activeReservations[index];
            return ReservationCard(
              reservation: reservation,
              onViewQR: () => _showReservationQR(context, reservation),
              onCancel: () => _cancelReservation(context, reservation),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return Consumer<ReservationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final historyReservations = provider.reservations
            .where((r) => r.status == ReservationStatus.collected || r.isExpired)
            .toList();

        if (historyReservations.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.history,
            title: 'No History',
            message: 'Completed reservations will appear here',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppDimens.pagePaddingH),
          itemCount: historyReservations.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final reservation = historyReservations[index];
            return ReservationCard(
              reservation: reservation,
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

  Future<void> _cancelReservation(BuildContext context, Reservation reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Reservation'),
        content: const Text('Are you sure you want to cancel this reservation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await context.read<ReservationProvider>().expireReservation(reservation.id);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reservation cancelled'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Widget _buildMyReservationsTab() {
    // Keep for backward compatibility, redirect to active
    return _buildActiveReservationsTab();
  }

  void _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    if (_isSearching) return; // Prevent multiple simultaneous searches
    if (_selectedLibraryId == null) return; // No library selected

    setState(() {
      _isSearching = true;
    });

    try {
      final booksProvider = context.read<BookProvider>();
      final results = await booksProvider.searchBooks(query.trim());
      
      if (mounted) {
        setState(() {
          // Filter results to only show books from selected library with available copies
          _searchResults = results
              .where((book) => 
                  book.libraryId == _selectedLibraryId && 
                  book.availableCopies > 0)
              .toList();
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults.clear();
          _isSearching = false;
        });
      }
    }
  }

  void _createReservation() async {
    final user = context.read<AuthProvider>().userModel;
    if (user == null) return;

    // Ensure library is selected
    if (_selectedLibraryId == null || _selectedLibraryName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a library first'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final libraryId = _selectedLibraryId!;
    final libraryName = _selectedLibraryName!;
    
    // Get library's Razorpay key
    final library = context.read<LibraryProvider>().getLibraryById(libraryId);
    final razorpayKey = library?.razorpayKeyId;

    if (razorpayKey == null || razorpayKey.isEmpty) {
      // Fallback: Show dialog explaining fee can be paid at library
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Reservation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You are reserving ${_selectedBooks.values.fold(0, (sum, qty) => sum + qty)} book(s)'),
              const SizedBox(height: AppDimens.md),
              Container(
                padding: const EdgeInsets.all(AppDimens.sm),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reservation Fee: ₹10',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppDimens.xs),
                    const Text(
                      '• Fee can be paid at the library when collecting books',
                      style: TextStyle(fontSize: 12),
                    ),
                    const Text(
                      '• Full refund if collected within 3 days',
                      style: TextStyle(fontSize: 12),
                    ),
                    const Text(
                      '• Fee forfeited if reservation expires',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    } else {
      // Razorpay is configured - collect payment online
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pay Reservation Fee'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You are reserving ${_selectedBooks.values.fold(0, (sum, qty) => sum + qty)} book(s)'),
              const SizedBox(height: AppDimens.md),
              Container(
                padding: const EdgeInsets.all(AppDimens.sm),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reservation Fee: ₹10',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: AppDimens.xs),
                    const Text(
                      '• Refundable if collected within 3 days',
                      style: TextStyle(fontSize: 12),
                    ),
                    const Text(
                      '• Forfeited if reservation expires',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Pay ₹10'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Collect payment via Razorpay
      final paymentService = PaymentService();
      final paymentResult = await paymentService.collectPayment(
        razorpayKeyId: razorpayKey,
        amountInr: 10.0,
        libraryName: libraryName,
        userEmail: user.email,
        userName: user.name,
      );

      if (!paymentResult.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(paymentResult.errorMessage ?? 'Payment failed'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Payment successful - show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment successful! ID: ${paymentResult.paymentId}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }

    // Get all books (from search results or from provider)
    final bookProvider = context.read<BookProvider>();
    final allBooks = _searchResults.isEmpty && _searchController.text.isEmpty
        ? bookProvider.books
        : _searchResults;

    final items = _selectedBooks.entries.map((entry) {
      final book = allBooks.firstWhere((b) => b.id == entry.key);
      return ReservationItem(
        bookId: book.id,
        bookTitle: book.title,
        bookThumbnail: book.thumbnail,
        quantity: entry.value,
      );
    }).toList();

    final success = await context.read<ReservationProvider>().createReservation(
      userId: user.uid,
      userName: user.name,
      userEmail: user.email,
      libraryId: libraryId,
      libraryName: libraryName,
      items: items,
    );

    if (success && mounted) {
      setState(() {
        _selectedBooks.clear();
        _searchResults.clear();
        _searchController.clear();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reservation created successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      final error = context.read<ReservationProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to create reservation'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _BookSelectionCard extends StatelessWidget {
  final BookModel book;
  final int selectedQuantity;
  final int totalSelected;
  final int maxAllowed;
  final Function(int) onQuantityChanged;

  const _BookSelectionCard({
    super.key,
    required this.book,
    required this.selectedQuantity,
    required this.totalSelected,
    required this.maxAllowed,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final maxSelectable = (maxAllowed - totalSelected + selectedQuantity).clamp(0, book.availableCopies);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.md),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              child: book.thumbnail != null
                  ? Image.network(
                      book.thumbnail!,
                      width: 50,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 50,
                        height: 70,
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.menu_book, size: 24),
                      ),
                    )
                  : Container(
                      width: 50,
                      height: 70,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.menu_book, size: 24),
                    ),
            ),
            const SizedBox(width: AppDimens.md),

            // Book info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.authorsFormatted,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Available: ${book.availableCopies}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: book.availableCopies > 0 
                              ? AppColors.success 
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),

            // Quantity selector
            Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: selectedQuantity > 0 
                          ? () => onQuantityChanged(selectedQuantity - 1)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      iconSize: 20,
                    ),
                    Container(
                      width: 30,
                      alignment: Alignment.center,
                      child: Text(
                        selectedQuantity.toString(),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    IconButton(
                      onPressed: selectedQuantity < maxSelectable
                          ? () => onQuantityChanged(selectedQuantity + 1)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                      iconSize: 20,
                    ),
                  ],
                ),
                if (maxSelectable == 0 && totalSelected >= maxAllowed)
                  Text(
                    'Limit reached',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.error,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}