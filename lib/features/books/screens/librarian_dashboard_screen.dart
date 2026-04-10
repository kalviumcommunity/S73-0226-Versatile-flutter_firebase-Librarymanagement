import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/cards/stat_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../library/providers/library_provider.dart';
import '../../books/providers/book_provider.dart';
import '../../reservations/providers/reservation_provider.dart';
import '../../reservations/models/reservation_model.dart';
import '../../borrow/providers/borrow_transaction_provider.dart';
import '../../borrow/models/borrow_transaction_model.dart';
import '../../borrow/screens/librarian_borrow_return_screen.dart';
import '../../reservations/screens/librarian_combined_reservation_screen.dart';
import 'stock_management_screen.dart';

class LibrarianDashboardScreen extends StatelessWidget {
  const LibrarianDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final libraryProvider = context.watch<LibraryProvider>();
    final bookProvider = context.watch<BookProvider>();
    final reservationProvider = context.watch<ReservationProvider>();
    final transactionProvider = context.watch<BorrowTransactionProvider>();
    final currentLibrary = libraryProvider.currentLibrary;
    
    // Calculate metrics for current library
    final libraryBooks = bookProvider.books
        .where((b) => b.libraryId == user?.libraryId)
        .length;
    final pendingReservations = reservationProvider.reservations
        .where((r) => r.status == ReservationStatus.pending && r.libraryId == user?.libraryId)
        .length;
    final activeBorrows = transactionProvider.transactions
        .where((t) => t.status == TransactionStatus.active && t.libraryId == user?.libraryId)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.pagePaddingH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimens.sm),

              // Greeting
              Text(
                'Hello, ${user?.name ?? 'Librarian'} 👋',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppDimens.xs),
              Text(
                'Manage books, reservations, and borrowing.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppDimens.md),

              // Library info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimens.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                      ),
                      child: const Icon(
                        Icons.local_library_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppDimens.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentLibrary?.name ?? user?.libraryName ?? 'Loading...',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${currentLibrary?.bookCount ?? 0} books · ${currentLibrary?.memberCount ?? 0} members',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.md),

              // Role badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.md,
                  vertical: AppDimens.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                ),
                child: const Text(
                  'LIBRARIAN',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: AppDimens.xl),

              // Stats section
              Text(
                'Library Metrics',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppDimens.md),
              
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.menu_book_rounded,
                      value: '$libraryBooks',
                      label: 'Book Inventory',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StockManagementScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      icon: Icons.book_rounded,
                      value: '$activeBorrows',
                      label: 'Active Borrows',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LibrarianBorrowReturnScreen(
                            libraryId: user?.libraryId ?? '',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.bookmark_rounded,
                      value: '$pendingReservations',
                      label: 'Pending',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LibrarianCombinedReservationScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      icon: Icons.people_rounded,
                      value: '${currentLibrary?.memberCount ?? 0}',
                      label: 'Members',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimens.xl),

              // Quick actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppDimens.md),
              _buildDashboardGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardGrid(BuildContext context) {
    final items = [
      _DashItem(Icons.library_add_rounded, 'Add Books', AppColors.primary, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const StockManagementScreen()));
      }),
      _DashItem(Icons.qr_code_scanner_rounded, 'Reservations', AppColors.accent, () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const LibrarianCombinedReservationScreen(),
          ),
        );
      }),
      _DashItem(Icons.swap_horiz_rounded, 'Borrow/Return', AppColors.success, () {
        final user = context.read<AuthProvider>().userModel;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LibrarianBorrowReturnScreen(
              libraryId: user?.libraryId ?? '',
            ),
          ),
        );
      }),
      _DashItem(Icons.analytics_rounded, 'Library Stats', AppColors.warning, () {
        // Placeholder for future feature
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Library statistics coming soon!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: items.map((item) {
        return Card(
          child: InkWell(
            onTap: item.onTap ?? () {},
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    ),
                    child: Icon(item.icon, color: item.color, size: 26),
                  ),
                  const SizedBox(height: AppDimens.sm),
                  Text(
                    item.label,
                    style: Theme.of(context).textTheme.titleSmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DashItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _DashItem(this.icon, this.label, this.color, this.onTap);
}
