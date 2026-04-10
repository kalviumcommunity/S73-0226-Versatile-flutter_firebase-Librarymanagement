import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../auth/providers/auth_provider.dart';
import '../../books/models/book_model.dart';
import '../../books/providers/book_provider.dart';
import '../../auth/repository/auth_repository.dart';
import '../../auth/models/user_model.dart';
import '../../reservations/providers/reservation_provider.dart';
import '../models/borrow_model.dart';
import '../providers/borrow_provider.dart';

/// Librarian screen to issue and return books via QR codes.
class IssueReturnScreen extends StatefulWidget {
  final String? libraryId;

  const IssueReturnScreen({super.key, this.libraryId});

  @override
  State<IssueReturnScreen> createState() => _IssueReturnScreenState();
}

class _IssueReturnScreenState extends State<IssueReturnScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _libraryId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final user = context.read<AuthProvider>().userModel;
    _libraryId = widget.libraryId ?? user?.libraryId ?? user?.uid ?? '';
    context.read<BorrowProvider>().listenToLibraryBorrows(_libraryId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borrowProvider = context.watch<BorrowProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue / Return'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          tabs: [
            const Tab(text: 'Issue Book'),
            Tab(text: 'Returns (${borrowProvider.activeBorrows.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _IssueTab(libraryId: _libraryId),
          _ReturnsTab(
            borrows: borrowProvider.activeBorrows,
            libraryId: _libraryId,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ISSUE TAB — Scan user QR → Select book → Issue
// ─────────────────────────────────────────────

class _IssueTab extends StatefulWidget {
  final String libraryId;

  const _IssueTab({required this.libraryId});

  @override
  State<_IssueTab> createState() => _IssueTabState();
}

class _IssueTabState extends State<_IssueTab> {
  final _emailController = TextEditingController();
  final _repo = AuthRepository();
  UserModel? _selectedUser;
  BookModel? _selectedBook;
  bool _isSearchingUser = false;
  bool _isIssuing = false;
  int _borrowDays = 14;
  String? _reservationId; // set when scanned from reservation QR
  int _issueCopies = 1;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // ── Scan QR code (handles both user QR and reservation QR) ──
  Future<void> _scanQR() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const _QRScannerScreen(title: 'Scan QR Code'),
      ),
    );
    if (result == null || !mounted) return;

    if (result.startsWith('LIB_RESERVE:')) {
      await _handleReservationQR(result);
    } else if (result.startsWith('LIB_USER:')) {
      await _handleUserQR(result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid QR code.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Handle reservation QR: auto-fill user + book + copies ──
  Future<void> _handleReservationQR(String result) async {
    // Format: LIB_RESERVE:<reservationId>:<bookId>:<userId>:<copies>
    final parts = result.split(':');
    if (parts.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid reservation QR format.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final reservationId = parts[1];
    final bookId = parts[2];
    final userId = parts[3];
    final copies = int.tryParse(parts[4]) ?? 1;

    setState(() => _isSearchingUser = true);

    // Look up user
    final user = await _repo.getUser(userId);

    // Look up book
    final books = context.read<BookProvider>().books;
    BookModel? book;
    try {
      book = books.firstWhere((b) => b.id == bookId);
    } catch (_) {
      book = null;
    }

    setState(() {
      _selectedUser = user;
      _selectedBook = book;
      _reservationId = reservationId;
      _issueCopies = copies;
      _isSearchingUser = false;
      if (user != null) _emailController.text = user.email;
    });

    if (!mounted) return;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not found for this reservation.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (book == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book not found for this reservation.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reservation loaded: ${book.title} × $copies'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Handle user QR code ──
  Future<void> _handleUserQR(String result) async {

    // Parse QR: "LIB_USER:<uid>:<email>"
    if (!result.startsWith('LIB_USER:')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid user QR code.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final parts = result.split(':');
    if (parts.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid QR code format.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final uid = parts[1];
    final email = parts.sublist(2).join(':');

    setState(() => _isSearchingUser = true);
    final user = await _repo.getUser(uid) ?? await _repo.getUserByEmail(email);
    setState(() {
      _selectedUser = user;
      _selectedBook = null;
      _reservationId = null;
      _issueCopies = 1;
      _isSearchingUser = false;
      if (user != null) {
        _emailController.text = user.email;
      }
    });

    if (user == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not found.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Manual email search ──
  Future<void> _searchUser() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isSearchingUser = true);
    final user = await _repo.getUserByEmail(email);
    setState(() {
      _selectedUser = user;
      _isSearchingUser = false;
    });

    if (user == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not found with this email.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _selectBook() {
    final books = context
        .read<BookProvider>()
        .books
        .where((b) => b.libraryId == widget.libraryId && b.availableCopies > 0)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLg)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppDimens.md),
                child: Text('Select Book',
                    style: Theme.of(ctx).textTheme.titleMedium),
              ),
              Expanded(
                child: books.isEmpty
                    ? const Center(child: Text('No available books'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: books.length,
                        itemBuilder: (_, index) {
                          final book = books[index];
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radiusSm),
                              child: book.thumbnail != null
                                  ? Image.network(
                                      book.thumbnail!,
                                      width: 40,
                                      height: 56,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 40,
                                      height: 56,
                                      color: AppColors.surfaceVariant,
                                      child: const Icon(Icons.menu_book),
                                    ),
                            ),
                            title: Text(book.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              '${book.availableCopies} available',
                              style: const TextStyle(
                                  color: AppColors.success, fontSize: 12),
                            ),
                            onTap: () {
                              setState(() => _selectedBook = book);
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _issueBook() async {
    if (_selectedUser == null || _selectedBook == null) return;

    setState(() => _isIssuing = true);

    final librarianUid = context.read<AuthProvider>().userModel?.uid ?? '';
    bool allSuccess = true;

    // Issue one borrow record per copy
    for (int i = 0; i < _issueCopies; i++) {
      final success = await context.read<BorrowProvider>().issueBook(
            bookId: _selectedBook!.id,
            bookTitle: _selectedBook!.title,
            bookThumbnail: _selectedBook!.thumbnail,
            userId: _selectedUser!.uid,
            userName: _selectedUser!.name,
            libraryId: widget.libraryId,
            issuedBy: librarianUid,
            borrowDays: _borrowDays,
          );
      if (!success) {
        allSuccess = false;
        break;
      }
    }

    // Fulfill the reservation if this came from a reservation QR
    if (allSuccess && _reservationId != null) {
      await context.read<ReservationProvider>().fulfillReservation(_reservationId!);
    }

    if (mounted) {
      final copiesIssued = _issueCopies;
      setState(() {
        _isIssuing = false;
        if (allSuccess) {
          _selectedUser = null;
          _selectedBook = null;
          _emailController.clear();
          _reservationId = null;
          _issueCopies = 1;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(allSuccess
              ? 'Book issued successfully! ($copiesIssued ${copiesIssued == 1 ? "copy" : "copies"})'
              : context.read<BorrowProvider>().error ??
                  'Failed to issue book.'),
          backgroundColor: allSuccess ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.pagePaddingH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppDimens.md),

          // ── Step 1: Find Reader ──
          Text('1. Find Reader',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppDimens.sm),

          // Scan QR button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _scanQR,
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
              label: const Text('Scan QR Code'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side:
                    BorderSide(color: AppColors.accent.withValues(alpha: 0.4)),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
              ),
            ),
          ),

          const SizedBox(height: AppDimens.sm),

          // Divider with "or"
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('or',
                    style: TextStyle(
                        color: AppColors.textTertiary, fontSize: 12)),
              ),
              const Expanded(child: Divider()),
            ],
          ),

          const SizedBox(height: AppDimens.sm),

          // Manual email search
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Enter reader email',
                    prefixIcon: Icon(Icons.email_outlined, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.sm),
              ElevatedButton(
                onPressed: _isSearchingUser ? null : _searchUser,
                style:
                    ElevatedButton.styleFrom(minimumSize: const Size(80, 52)),
                child: _isSearchingUser
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Find'),
              ),
            ],
          ),

          // User card
          if (_selectedUser != null) ...[
            const SizedBox(height: AppDimens.md),
            Card(
              color: AppColors.success.withValues(alpha: 0.05),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.success.withValues(alpha: 0.15),
                  child: const Icon(Icons.person, color: AppColors.success),
                ),
                title: Text(_selectedUser!.name),
                subtitle: Text(_selectedUser!.email),
                trailing:
                    const Icon(Icons.check_circle, color: AppColors.success),
              ),
            ),
          ],

          // Reservation banner
          if (_reservationId != null) ...[
            const SizedBox(height: AppDimens.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bookmark_rounded, color: AppColors.accent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'From reservation · $_issueCopies ${_issueCopies == 1 ? "copy" : "copies"}',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppDimens.lg),

          // ── Step 2: Select Book ──
          Text('2. Select Book',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppDimens.sm),
          InkWell(
            onTap: _selectBook,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimens.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: _selectedBook != null
                    ? Border.all(
                        color: AppColors.success.withValues(alpha: 0.5))
                    : null,
              ),
              child: _selectedBook != null
                  ? Row(
                      children: [
                        const Icon(Icons.menu_book, color: AppColors.success),
                        const SizedBox(width: AppDimens.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_selectedBook!.title,
                                  style:
                                      Theme.of(context).textTheme.titleSmall),
                              Text(
                                '${_selectedBook!.availableCopies} copies available',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.success),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.edit,
                            size: 18, color: AppColors.textTertiary),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, color: AppColors.textTertiary),
                        SizedBox(width: AppDimens.sm),
                        Text('Tap to select a book',
                            style: TextStyle(color: AppColors.textTertiary)),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: AppDimens.lg),

          // ── Step 3: Borrow Period ──
          Text('3. Borrow Period',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppDimens.sm),
          Row(
            children: [7, 14, 21, 30].map((days) {
              final selected = _borrowDays == days;
              return Padding(
                padding: const EdgeInsets.only(right: AppDimens.sm),
                child: ChoiceChip(
                  label: Text('$days days'),
                  selected: selected,
                  onSelected: (_) => setState(() => _borrowDays = days),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppDimens.xl),

          // Issue button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  (_selectedUser != null && _selectedBook != null && !_isIssuing)
                      ? _issueBook
                      : null,
              icon: _isIssuing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded, size: 20),
              label: Text(_isIssuing ? 'Issuing...' : 'Issue Book${_issueCopies > 1 ? " (×$_issueCopies)" : ""}'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  RETURNS TAB — Scan borrow QR or manual list
// ─────────────────────────────────────────────

class _ReturnsTab extends StatefulWidget {
  final List<BorrowModel> borrows;
  final String libraryId;

  const _ReturnsTab({required this.borrows, required this.libraryId});

  @override
  State<_ReturnsTab> createState() => _ReturnsTabState();
}

class _ReturnsTabState extends State<_ReturnsTab> {
  // ── Scan borrow QR code for fast return ──
  Future<void> _scanBorrowQR() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const _QRScannerScreen(title: 'Scan Borrow QR Code'),
      ),
    );
    if (result == null || !mounted) return;

    // Parse QR: "LIB_BORROW:<borrowId>:<userId>"
    if (!result.startsWith('LIB_BORROW:')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid borrow QR code.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final parts = result.split(':');
    if (parts.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid QR code format.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final borrowId = parts[1];

    // Find borrow in current list
    BorrowModel? borrow;
    try {
      borrow = widget.borrows.firstWhere((b) => b.id == borrowId);
    } catch (_) {
      borrow = null;
    }

    if (borrow == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Borrow record not found or already returned.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (mounted) {
      _showReturnConfirmation(borrow);
    }
  }

  void _showReturnConfirmation(BorrowModel borrow) {
    final fine = borrow.calculatedFine;
    final dueStr = DateFormat('dd MMM yyyy').format(borrow.dueDate);
    final borrowStr = DateFormat('dd MMM yyyy').format(borrow.borrowDate);

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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReturnDetailRow(label: 'Book', value: borrow.bookTitle),
            _ReturnDetailRow(label: 'Borrower', value: borrow.userName),
            _ReturnDetailRow(label: 'Borrowed', value: borrowStr),
            _ReturnDetailRow(label: 'Due Date', value: dueStr),
            if (borrow.isOverdue) ...[
              const SizedBox(height: 8),
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
                      'Overdue! Fine: \u20b9${fine.toStringAsFixed(0)}',
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _returnBook(borrow.id, borrow.bookId);
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

  Future<void> _returnBook(String borrowId, String bookId) async {
    final success =
        await context.read<BorrowProvider>().returnBook(borrowId, bookId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(success ? 'Book returned!' : 'Failed to return book.'),
          backgroundColor: success ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Scan borrow QR button
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppDimens.pagePaddingH, AppDimens.md, AppDimens.pagePaddingH, 0),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _scanBorrowQR,
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
              label: const Text('Scan Borrow QR to Return'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.success,
                side: BorderSide(
                    color: AppColors.success.withValues(alpha: 0.4)),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
              ),
            ),
          ),
        ),

        const SizedBox(height: AppDimens.sm),

        // Active borrows list
        Expanded(
          child: widget.borrows.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 64,
                          color:
                              AppColors.textTertiary.withValues(alpha: 0.5)),
                      const SizedBox(height: AppDimens.md),
                      Text('No active borrows',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textTertiary)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppDimens.pagePaddingH),
                  itemCount: widget.borrows.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppDimens.sm),
                  itemBuilder: (context, index) {
                    final borrow = widget.borrows[index];
                    final isOverdue = borrow.isOverdue;
                    final fine = borrow.calculatedFine;

                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.md, vertical: AppDimens.xs),
                        leading: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusSm),
                          child: borrow.bookThumbnail != null
                              ? Image.network(
                                  borrow.bookThumbnail!,
                                  width: 40,
                                  height: 56,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 40,
                                  height: 56,
                                  color: AppColors.surfaceVariant,
                                  child: const Icon(Icons.menu_book),
                                ),
                        ),
                        title: Text(borrow.bookTitle,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(borrow.userName,
                                style: const TextStyle(fontSize: 12)),
                            if (isOverdue)
                              Text(
                                'Overdue! Fine: \u20b9${fine.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.error),
                              ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _showReturnConfirmation(borrow),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            minimumSize: const Size(80, 36),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: const Text('Return',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ReturnDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReturnDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  QR SCANNER SCREEN — Reusable scanner page
// ─────────────────────────────────────────────

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

          // Overlay with scanning frame
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

          // Bottom instruction
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
