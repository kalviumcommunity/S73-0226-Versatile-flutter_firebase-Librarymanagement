import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/repository/auth_repository.dart';
import '../../auth/models/user_model.dart';
import '../../books/models/book_model.dart';
import '../../books/providers/book_provider.dart';
import '../../library/providers/library_provider.dart';
import '../models/borrow_transaction_model.dart';
import '../providers/borrow_transaction_provider.dart';

/// Librarian screen to issue books to readers
class LibrarianBorrowScreen extends StatefulWidget {
  final String libraryId;

  const LibrarianBorrowScreen({
    super.key,
    required this.libraryId,
  });

  @override
  State<LibrarianBorrowScreen> createState() => _LibrarianBorrowScreenState();
}

class _LibrarianBorrowScreenState extends State<LibrarianBorrowScreen> {
  final _emailController = TextEditingController();
  final _repo = AuthRepository();
  
  UserModel? _selectedUser;
  final List<_SelectedBook> _selectedBooks = [];
  bool _isSearchingUser = false;
  bool _isIssuing = false;
  int _borrowDays = 14;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Scan user QR code
  Future<void> _scanUserQR() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const _QRScannerScreen(title: 'Scan Reader QR Code'),
      ),
    );
    if (result == null || !mounted) return;

    if (!result.startsWith('LIB_USER:')) {
      _showError('Invalid QR code. Please scan a reader QR code.');
      return;
    }

    final parts = result.split(':');
    if (parts.length < 3) {
      _showError('Invalid QR code format.');
      return;
    }

    final uid = parts[1];
    final email = parts.sublist(2).join(':');

    setState(() => _isSearchingUser = true);
    final user = await _repo.getUser(uid) ?? await _repo.getUserByEmail(email);
    setState(() {
      _selectedUser = user;
      _isSearchingUser = false;
      if (user != null) {
        _emailController.text = user.email;
      }
    });

    if (user == null && mounted) {
      _showError('Reader not found.');
    } else if (user != null && user.role != 'reader') {
      _showError('This user is not a reader. Only readers can borrow books.');
      setState(() => _selectedUser = null);
    }
  }

  // Manual email search
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
      _showError('Reader not found with this email.');
    } else if (user != null && user.role != 'reader') {
      _showError('This user is not a reader. Only readers can borrow books.');
      setState(() => _selectedUser = null);
    }
  }

  // Show book selection dialog
  void _showBookSelection() {
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
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppDimens.md),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Select Book',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
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
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              '${book.availableCopies} available',
                              style: const TextStyle(
                                  color: AppColors.success, fontSize: 12),
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              _showQuantityDialog(book);
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

  // Show quantity selection dialog
  void _showQuantityDialog(BookModel book) {
    int quantity = 1;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Select Quantity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                book.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: quantity > 1
                        ? () => setDialogState(() => quantity--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    iconSize: 32,
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '$quantity',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: quantity < book.availableCopies
                        ? () => setDialogState(() => quantity++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                    iconSize: 32,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Available: ${book.availableCopies}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _addBook(book, quantity);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // Add book to selection
  void _addBook(BookModel book, int quantity) {
    // Check if book already added
    final existingIndex =
        _selectedBooks.indexWhere((b) => b.book.id == book.id);
    if (existingIndex != -1) {
      setState(() {
        _selectedBooks[existingIndex] =
            _SelectedBook(book, _selectedBooks[existingIndex].quantity + quantity);
      });
    } else {
      setState(() {
        _selectedBooks.add(_SelectedBook(book, quantity));
      });
    }
  }

  // Remove book from selection
  void _removeBook(int index) {
    setState(() {
      _selectedBooks.removeAt(index);
    });
  }

  // Issue books
  Future<void> _issueBooks() async {
    if (_selectedUser == null || _selectedBooks.isEmpty) return;

    setState(() => _isIssuing = true);

    final librarianUid = context.read<AuthProvider>().userModel?.uid ?? '';
    final items = _selectedBooks
        .map((sb) => BorrowItem(
              bookId: sb.book.id,
              bookTitle: sb.book.title,
              bookThumbnail: sb.book.thumbnail,
              quantity: sb.quantity,
            ))
        .toList();

    // Get library name
    final library = context.read<LibraryProvider>().getLibraryById(widget.libraryId);
    final libraryName = library?.name ?? 'Unknown Library';

    final transaction =
        await context.read<BorrowTransactionProvider>().createTransaction(
              userId: _selectedUser!.uid,
              userName: _selectedUser!.name,
              userEmail: _selectedUser!.email,
              libraryId: widget.libraryId,
              libraryName: libraryName,
              issuedBy: librarianUid,
              items: items,
              borrowDays: _borrowDays,
            );

    if (mounted) {
      setState(() => _isIssuing = false);
      
      if (transaction != null) {
        // Force refresh book provider to update stock immediately
        context.read<BookProvider>().forceRefresh();
        
        // Clear form
        setState(() {
          _selectedUser = null;
          _selectedBooks.clear();
          _emailController.clear();
        });
        
        _showSuccess('Books issued successfully!');
      } else {
        final error = context.read<BorrowTransactionProvider>().error;
        _showError(error ?? 'Failed to issue books.');
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
        title: const Text('Issue Books'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.pagePaddingH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppDimens.md),

            // Step 1: Find Reader
            Text('1. Find Reader',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppDimens.sm),

            // Scan QR button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _scanUserQR,
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                label: const Text('Scan Reader QR Code'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: BorderSide(
                      color: AppColors.accent.withValues(alpha: 0.4)),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
                ),
              ),
            ),

            const SizedBox(height: AppDimens.sm),

            // Divider
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
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(80, 52)),
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
                  trailing: const Icon(Icons.check_circle,
                      color: AppColors.success),
                ),
              ),
            ],

            const SizedBox(height: AppDimens.lg),

            // Step 2: Select Books
            Row(
              children: [
                Expanded(
                  child: Text('2. Select Books',
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                if (_selectedUser != null)
                  ElevatedButton.icon(
                    onPressed: _showBookSelection,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Book'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppDimens.sm),

            // Selected books list
            if (_selectedBooks.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimens.lg),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  border: Border.all(
                    color: AppColors.darkBorder,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.library_books_outlined,
                        size: 48,
                        color: AppColors.darkTextTertiary.withValues(alpha: 0.5)),
                    const SizedBox(height: AppDimens.sm),
                    Text(
                      _selectedUser == null
                          ? 'Select a reader first'
                          : 'No books selected',
                      style: TextStyle(color: AppColors.darkTextSecondary),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(_selectedBooks.length, (index) {
                final sb = _selectedBooks[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppDimens.sm),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                      child: sb.book.thumbnail != null
                          ? Image.network(
                              sb.book.thumbnail!,
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
                    title: Text(sb.book.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('Quantity: ${sb.quantity}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.error),
                      onPressed: () => _removeBook(index),
                    ),
                  ),
                );
              }),

            const SizedBox(height: AppDimens.lg),

            // Step 3: Borrow Period
            Text('3. Borrow Period',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppDimens.sm),
            Wrap(
              spacing: AppDimens.sm,
              children: [7, 14, 21, 30].map((days) {
                final selected = _borrowDays == days;
                return ChoiceChip(
                  label: Text('$days days'),
                  selected: selected,
                  onSelected: (_) => setState(() => _borrowDays = days),
                );
              }).toList(),
            ),

            const SizedBox(height: AppDimens.xl),

            // Issue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_selectedUser != null &&
                        _selectedBooks.isNotEmpty &&
                        !_isIssuing)
                    ? _issueBooks
                    : null,
                icon: _isIssuing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_rounded, size: 20),
                label: Text(_isIssuing
                    ? 'Issuing...'
                    : 'Issue Books (${_selectedBooks.fold<int>(0, (sum, sb) => sum + sb.quantity)} ${_selectedBooks.fold<int>(0, (sum, sb) => sum + sb.quantity) == 1 ? "book" : "books"})'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class to track selected books with quantity
class _SelectedBook {
  final BookModel book;
  final int quantity;

  _SelectedBook(this.book, this.quantity);
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
