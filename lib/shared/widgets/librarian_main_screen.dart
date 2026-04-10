import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/books/screens/librarian_dashboard_screen.dart';
import '../../features/books/screens/stock_management_screen.dart';
import '../../features/borrow/screens/librarian_borrow_return_screen.dart';
import '../../features/books/providers/book_provider.dart';
import '../../features/borrow/providers/borrow_provider.dart';
import '../../features/borrow/providers/borrow_transaction_provider.dart';
import '../../features/reservations/providers/reservation_provider.dart';
import '../../features/library/providers/library_provider.dart';
import '../../features/profile/screens/profile_screen.dart';

/// Bottom navigation shell for librarians.
class LibrarianMainScreen extends StatefulWidget {
  const LibrarianMainScreen({super.key});

  @override
  State<LibrarianMainScreen> createState() => _LibrarianMainScreenState();
}

class _LibrarianMainScreenState extends State<LibrarianMainScreen> {
  int _currentIndex = 0;

  List<Widget> get _pages {
    final user = context.read<AuthProvider>().userModel;
    final libraryId = user?.libraryId ?? user?.uid ?? '';
    return [
      const LibrarianDashboardScreen(),
      const StockManagementScreen(),
      LibrarianBorrowReturnScreen(libraryId: libraryId),
      const ProfileScreen(),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLibrarianStreams();
    });
  }

  void _initLibrarianStreams() {
    final user = context.read<AuthProvider>().userModel;
    if (user == null) return;
    final libraryId = user.libraryId ?? user.uid;
    context.read<LibraryProvider>().loadLibrary(libraryId);
    context.read<BookProvider>().listenToLibraryBooks(libraryId);
    context.read<BorrowProvider>().listenToLibraryBorrows(libraryId);
    context.read<BorrowTransactionProvider>().listenToLibraryTransactions(libraryId);
    context.read<ReservationProvider>().listenToLibraryReservations(libraryId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                  isActive: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.library_books_outlined,
                  activeIcon: Icons.library_books_rounded,
                  label: 'Manage',
                  isActive: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.swap_horiz_outlined,
                  activeIcon: Icons.swap_horiz_rounded,
                  label: 'Borrow',
                  isActive: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  isActive: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool comingSoon;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = comingSoon
        ? AppColors.darkTextTertiary.withOpacity(0.5)
        : isActive
            ? AppColors.darkPrimary
            : AppColors.darkTextSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: comingSoon ? () => _showComingSoon(context) : onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: isActive ? 24 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.darkPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label — coming soon!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
