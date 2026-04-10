import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/borrow_model.dart';
import '../providers/borrow_provider.dart';

/// Reader's view of their borrowed books.
class MyBorrowsScreen extends StatefulWidget {
  const MyBorrowsScreen({super.key});

  @override
  State<MyBorrowsScreen> createState() => _MyBorrowsScreenState();
}

class _MyBorrowsScreenState extends State<MyBorrowsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Start listening to user borrows
    final uid = context.read<AuthProvider>().userModel?.uid;
    if (uid != null) {
      context.read<BorrowProvider>().listenToUserBorrows(uid);
    }
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
        title: const Text('My Borrows'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          tabs: [
            Tab(text: 'Active (${borrowProvider.activeBorrows.length})'),
            Tab(text: 'History (${borrowProvider.returnedBorrows.length})'),
          ],
        ),
      ),
      body: borrowProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _BorrowsList(borrows: borrowProvider.activeBorrows, isActive: true),
                _BorrowsList(borrows: borrowProvider.returnedBorrows, isActive: false),
              ],
            ),
    );
  }
}

class _BorrowsList extends StatelessWidget {
  final List<BorrowModel> borrows;
  final bool isActive;

  const _BorrowsList({required this.borrows, required this.isActive});

  @override
  Widget build(BuildContext context) {
    if (borrows.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.menu_book_outlined : Icons.history_rounded,
              size: 64,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppDimens.md),
            Text(
              isActive ? 'No active borrows' : 'No borrow history yet',
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
      itemCount: borrows.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppDimens.sm),
      itemBuilder: (context, index) {
        return _BorrowCard(borrow: borrows[index]);
      },
    );
  }
}

class _BorrowCard extends StatelessWidget {
  final BorrowModel borrow;

  const _BorrowCard({required this.borrow});

  @override
  Widget build(BuildContext context) {
    final isOverdue = borrow.isOverdue;
    final fine = borrow.calculatedFine;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.md),
        child: Row(
          children: [
            // Book thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              child: borrow.bookThumbnail != null
                  ? Image.network(
                      borrow.bookThumbnail!,
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

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    borrow.bookTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Borrowed: ${dateFormat.format(borrow.borrowDate)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  if (borrow.status == BorrowStatus.returned)
                    Text(
                      'Returned: ${dateFormat.format(borrow.returnDate!)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.success),
                    )
                  else
                    Text(
                      'Due: ${dateFormat.format(borrow.dueDate)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isOverdue
                                ? AppColors.error
                                : AppColors.textSecondary,
                            fontWeight:
                                isOverdue ? FontWeight.w600 : FontWeight.w400,
                          ),
                    ),
                  if (fine > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusRound),
                      ),
                      child: Text(
                        'Fine: ₹${fine.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Status badge and QR button
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(borrow).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                  ),
                  child: Text(
                    _statusText(borrow),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(borrow),
                    ),
                  ),
                ),
                if (borrow.status != BorrowStatus.returned) ...[  
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _showBorrowQR(context, borrow),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code_rounded, size: 14, color: AppColors.accent),
                          SizedBox(width: 4),
                          Text('QR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accent)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(BorrowModel b) {
    if (b.status == BorrowStatus.returned) return AppColors.success;
    if (b.isOverdue) return AppColors.error;
    return AppColors.accent;
  }

  String _statusText(BorrowModel b) {
    if (b.status == BorrowStatus.returned) return 'Returned';
    if (b.isOverdue) return 'Overdue';
    return '${b.daysRemaining}d left';
  }

  void _showBorrowQR(BuildContext context, BorrowModel borrow) {
    final qrData = 'LIB_BORROW:${borrow.id}:${borrow.userId}';
    final dateFormat = DateFormat('dd MMM yyyy');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.qr_code_rounded, color: AppColors.accent, size: 22),
            const SizedBox(width: 8),
            const Expanded(child: Text('Borrow QR Code')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: SizedBox(
                  width: 180,
                  height: 180,
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E3A8A),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                borrow.bookTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Due: ${dateFormat.format(borrow.dueDate)}',
                style: TextStyle(
                  color: borrow.isOverdue ? AppColors.error : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: borrow.isOverdue ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Show this QR to the librarian\nfor fast book return.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}
