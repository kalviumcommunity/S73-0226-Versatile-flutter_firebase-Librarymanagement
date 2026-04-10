import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/widgets/badges/status_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../../books/models/book_model.dart';
import '../../books/providers/book_provider.dart';
import '../../books/screens/book_detail_screen.dart';
import '../models/library_model.dart';
import '../providers/library_provider.dart';
import '../repository/library_repository.dart';
import '../../../shared/services/payment_service.dart';
import '../../../shared/services/maps_service.dart';

/// Detail screen for a library — shows info, books, and join button.
class LibraryDetailScreen extends StatefulWidget {
  final String libraryId;

  const LibraryDetailScreen({super.key, required this.libraryId});

  @override
  State<LibraryDetailScreen> createState() => _LibraryDetailScreenState();
}

class _LibraryDetailScreenState extends State<LibraryDetailScreen> {
  final LibraryRepository _repo = LibraryRepository();
  final PaymentService _paymentService = PaymentService();
  final MapsService _mapsService = MapsService();
  LibraryModel? _library;
  List<BookModel> _libraryBooks = [];
  bool _isLoading = true;
  bool _isLoadingBooks = false;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  Future<void> _loadLibrary() async {
    final lib = await _repo.getLibrary(widget.libraryId);
    if (mounted) {
      setState(() { 
        _library = lib; 
        _isLoading = false; 
      });
      // Load books for this specific library
      _loadLibraryBooks();
    }
  }

  Future<void> _loadLibraryBooks() async {
    setState(() => _isLoadingBooks = true);
    try {
      // Query books directly from Firestore for this library
      final booksSnapshot = await FirebaseFirestore.instance
          .collection('books')
          .where('libraryId', isEqualTo: widget.libraryId)
          .get();
      
      final books = booksSnapshot.docs.map((doc) {
        final data = doc.data();
        return BookModel.fromJson({...data, 'id': doc.id});
      }).toList();
      
      // Sort by addedAt descending
      books.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      
      if (mounted) {
        setState(() {
          _libraryBooks = books;
          _isLoadingBooks = false;
        });
      }
      
      print('📚 LibraryDetailScreen: Loaded ${books.length} books for library ${widget.libraryId}');
    } catch (e) {
      print('📚 LibraryDetailScreen: Error loading books - $e');
      if (mounted) {
        setState(() {
          _libraryBooks = [];
          _isLoadingBooks = false;
        });
      }
    }
  }

  Future<void> _toggleMembership() async {
    final auth = context.read<AuthProvider>();
    final libraryProvider = context.read<LibraryProvider>();
    final user = auth.userModel;
    if (user == null || _library == null) return;

    final isMember = libraryProvider.isMember(widget.libraryId);

    if (isMember) {
      setState(() => _isJoining = true);
      await libraryProvider.leaveLibrary(widget.libraryId, user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Left ${_library!.name}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _loadLibrary();
      // Reload books after leaving
      _loadLibraryBooks();
      if (mounted) setState(() => _isJoining = false);
      return;
    }

    // Joining
    if (_library!.isFree) {
      // Free library — join directly
      setState(() => _isJoining = true);
      await libraryProvider.joinLibrary(
        libraryId: widget.libraryId,
        libraryName: _library!.name,
        userId: user.uid,
        userName: user.name,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Joined ${_library!.name}!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _loadLibrary();
      // Reload books after joining
      _loadLibraryBooks();
      if (mounted) setState(() => _isJoining = false);
      return;
    }

    // Paid library — show plan selection dialog
    if (_library!.plans.isNotEmpty) {
      _showPlanSelectionDialog();
    } else {
      // Legacy: single membershipFee, no plans configured
      await _processPaymentAndJoin(
        amount: _library!.membershipFee,
        planName: 'Membership',
      );
    }
  }

  void _showPlanSelectionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Choose a Plan',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select a membership plan to join ${_library!.name}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ..._library!.plans.map((plan) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _processPaymentAndJoin(
                          amount: plan.price,
                          planName: plan.name,
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.card_membership_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plan.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    '${plan.durationValue} ${plan.duration}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${plan.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPaymentAndJoin({
    required double amount,
    required String planName,
  }) async {
    final auth = context.read<AuthProvider>();
    final libraryProvider = context.read<LibraryProvider>();
    final user = auth.userModel!;

    setState(() => _isJoining = true);

    final razorpayKey = _library!.razorpayKeyId;
    if (razorpayKey == null || razorpayKey.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Payment not configured for this library. Contact the admin.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _isJoining = false);
      return;
    }

    // Collect payment via Razorpay
    final result = await _paymentService.collectPayment(
      razorpayKeyId: razorpayKey,
      amountInr: amount,
      libraryName: _library!.name,
      userEmail: user.email,
      userName: user.name,
      userPhone: user.phone,
    );

    if (!result.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Payment failed'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _isJoining = false);
      return;
    }

    // Payment successful — join with payment info
    await libraryProvider.joinLibrary(
      libraryId: widget.libraryId,
      libraryName: _library!.name,
      userId: user.uid,
      userName: user.name,
      amountPaid: amount,
      paymentId: result.paymentId,
      planName: planName,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Joined ${_library!.name} ($planName)!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    await _loadLibrary();
    // Reload books after joining with payment
    _loadLibraryBooks();
    if (mounted) setState(() => _isJoining = false);
  }

  Future<void> _locateLibrary() async {
    if (_library == null || 
        _library!.latitude == null || 
        _library!.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Library location not available'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await _mapsService.openMaps(
      latitude: _library!.latitude!,
      longitude: _library!.longitude!,
      label: _library!.name,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_mapsService.getErrorMessage()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          action: SnackBarAction(
            label: 'Copy Address',
            onPressed: () {
              // Copy formatted address to clipboard as fallback
              if (_library!.formattedAddress != null) {
                // Note: Would need to import services/clipboard for this
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Address: ${_library!.formattedAddress}'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_library == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Library not found')),
      );
    }

    final libraryProvider = context.watch<LibraryProvider>();
    final isMember = libraryProvider.isMember(widget.libraryId);
    final books = _libraryBooks; // Use directly loaded books instead of filtering from BookProvider

    return Scaffold(
      appBar: AppBar(
        title: Text(_library!.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimens.pagePaddingH),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.08),
                    AppColors.accent.withValues(alpha: 0.04),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_library_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: AppDimens.md),
                  Text(
                    _library!.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  if (_library!.description != null) ...[
                    const SizedBox(height: AppDimens.xs),
                    Text(
                      _library!.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: AppDimens.md),
                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatChip(
                        icon: Icons.people_rounded,
                        label: '${_library!.memberCount}',
                        subtitle: 'Members',
                      ),
                      const SizedBox(width: AppDimens.lg),
                      _StatChip(
                        icon: Icons.menu_book_rounded,
                        label: '${_library!.bookCount}',
                        subtitle: 'Books',
                      ),
                      const SizedBox(width: AppDimens.lg),
                      _StatChip(
                        icon: Icons.monetization_on_rounded,
                        label: _library!.isFree
                            ? 'Free'
                            : _library!.plans.isNotEmpty
                                ? '${_library!.plans.length} Plans'
                                : '₹${_library!.membershipFee.toStringAsFixed(0)}',
                        subtitle: 'Access',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.md),
                  // Action buttons
                  Row(
                    children: [
                      // Join/Leave button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _isJoining ? null : _toggleMembership,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isMember ? AppColors.error : AppColors.primary,
                          ),
                          icon: _isJoining
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  isMember
                                      ? Icons.exit_to_app_rounded
                                      : Icons.add_rounded,
                                  size: 20,
                                ),
                          label: Text(
                            _isJoining
                                ? 'Please wait...'
                                : isMember
                                    ? 'Leave Library'
                                    : _library!.isFree
                                        ? 'Join Library — Free'
                                        : _library!.plans.isNotEmpty
                                            ? 'Join Library — Choose Plan'
                                            : 'Join Library — ₹${_library!.membershipFee.toStringAsFixed(0)}',
                          ),
                        ),
                      ),
                      // Locate Library button (only show if library has coordinates)
                      if (_library!.latitude != null && _library!.longitude != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: OutlinedButton.icon(
                            onPressed: _locateLibrary,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.map_rounded, size: 16),
                            label: const Text(
                              'Locate',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.md),

            // Books section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.pagePaddingH,
              ),
              child: Row(
                children: [
                  Text(
                    'Books',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Text(
                    '${books.length} books',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.sm),

            if (_isLoadingBooks)
              const Padding(
                padding: EdgeInsets.all(AppDimens.xl),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (books.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppDimens.xl),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        size: 48,
                        color: AppColors.textTertiary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: AppDimens.sm),
                      Text(
                        'No books added yet',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.pagePaddingH,
                ),
                itemCount: books.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppDimens.sm),
                itemBuilder: (context, index) =>
                    _BookListTile(book: books[index]),
              ),

            const SizedBox(height: AppDimens.xl),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _BookListTile extends StatelessWidget {
  final BookModel book;

  const _BookListTile({required this.book});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.md,
          vertical: AppDimens.xs,
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          child: book.thumbnail != null
              ? Image.network(
                  book.thumbnail!,
                  width: 44,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 44,
                    height: 60,
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.menu_book, size: 24),
                  ),
                )
              : Container(
                  width: 44,
                  height: 60,
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.menu_book, size: 24),
                ),
        ),
        title: Text(
          book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: Text(
          book.authorsFormatted,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: StatusBadge(
          label: book.availableCopies > 0 ? 'Available' : 'Unavailable',
          type: book.availableCopies > 0 ? BadgeType.available : BadgeType.unavailable,
        ),
      ),
    );
  }
}
