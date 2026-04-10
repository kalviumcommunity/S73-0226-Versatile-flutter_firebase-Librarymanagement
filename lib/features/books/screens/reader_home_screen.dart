import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/cards/stat_card.dart';
import '../../../core/widgets/empty_states/empty_state_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../../library/screens/discover_libraries_screen.dart';
import '../../reservations/screens/reader_reservation_screen.dart';
import '../../reservations/providers/reservation_provider.dart';
import '../../reservations/models/reservation_model.dart';
import '../../borrow/screens/reader_transactions_screen.dart';
import '../../borrow/providers/borrow_transaction_provider.dart';
import '../../borrow/models/borrow_transaction_model.dart';
import '../../library/providers/library_provider.dart';
import 'browse_books_screen.dart';

class ReaderHomeScreen extends StatelessWidget {
  const ReaderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final reservationProvider = context.watch<ReservationProvider>();
    final transactionProvider = context.watch<BorrowTransactionProvider>();
    
    // Calculate metrics
    final activeReservations = reservationProvider.reservations
        .where((r) => r.status == ReservationStatus.pending)
        .length;
    final activeBorrows = transactionProvider.transactions
        .where((t) => t.status == TransactionStatus.active)
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
                'Hello, ${user?.name ?? 'Reader'} 👋',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppDimens.xs),
              Text(
                'Browse and reserve books from the library.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: AppDimens.lg),

              // Stats section
              Text(
                'My Activity',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppDimens.md),
              
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.book_rounded,
                      value: '$activeBorrows',
                      label: 'Active Borrows',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReaderTransactionsScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      icon: Icons.bookmark_rounded,
                      value: '$activeReservations',
                      label: 'Reservations',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReaderReservationScreen(),
                        ),
                      ),
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
              _buildQuickActions(context),

              const SizedBox(height: AppDimens.xl),

              // Joined libraries section
              _buildJoinedLibrariesSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.library_books_rounded,
                label: 'Browse',
                color: AppColors.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BrowseBooksScreen()),
                ),
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.bookmark_add_rounded,
                label: 'Reserve Books',
                color: AppColors.accent,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReaderReservationScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.md),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.history_rounded,
                label: 'My Borrows',
                color: AppColors.success,
                onTap: () {
                  // Find the ReaderMainScreen ancestor and switch to Borrows tab
                  final scaffoldContext = context.findAncestorStateOfType<ScaffoldState>();
                  if (scaffoldContext != null) {
                    // Use a simple approach: just navigate to the transactions screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReaderTransactionsScreen()),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.explore_rounded,
                label: 'Discover Libraries',
                color: AppColors.warning,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DiscoverLibrariesScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJoinedLibrariesSection(BuildContext context) {
    final libraryProvider = context.watch<LibraryProvider>();
    final memberships = libraryProvider.memberships;

    if (memberships.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.explore_rounded,
        title: 'Join a library to get started',
        message: 'Tap the Browse tab to discover libraries',
        actionLabel: 'Discover Libraries',
        onAction: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DiscoverLibrariesScreen()),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Libraries',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppDimens.sm),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: memberships.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final m = memberships[index];
            return Card(
              child: ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  ),
                  child: const Icon(
                    Icons.local_library_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                title: Text(m.libraryName),
                subtitle: Text(
                  'Joined',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BrowseBooksScreen(),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimens.md,
          horizontal: AppDimens.sm,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: AppDimens.iconLg),
            const SizedBox(height: AppDimens.sm),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
