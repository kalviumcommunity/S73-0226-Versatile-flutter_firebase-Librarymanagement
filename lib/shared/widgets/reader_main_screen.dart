import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/books/screens/reader_home_screen.dart';
import '../../features/books/providers/book_provider.dart';
import '../../features/library/screens/discover_libraries_screen.dart';
import '../../features/library/providers/library_provider.dart';
import '../../features/borrow/providers/borrow_provider.dart';
import '../../features/borrow/providers/borrow_transaction_provider.dart';
import '../../features/borrow/screens/reader_transactions_screen.dart';
import '../../features/reservations/providers/reservation_provider.dart';
import '../../features/reservations/screens/my_reservations_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

/// Instagram-style bottom navigation shell for readers.
/// Each tab keeps its own state via IndexedStack.
class ReaderMainScreen extends StatefulWidget {
  const ReaderMainScreen({super.key});

  @override
  State<ReaderMainScreen> createState() => _ReaderMainScreenState();
}

class _ReaderMainScreenState extends State<ReaderMainScreen> {
  int _currentIndex = 0;

  final _pages = const [
    ReaderHomeScreen(),
    DiscoverLibrariesScreen(),
    ReaderTransactionsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initUserStreams();
      _setupMembershipListener();
    });
  }

  void _setupMembershipListener() {
    // Listen to membership changes and reload books accordingly
    context.read<LibraryProvider>().addListener(_onMembershipsChanged);
  }

  void _onMembershipsChanged() {
    // When memberships change, reload books from all joined libraries
    final memberships = context.read<LibraryProvider>().memberships;
    if (memberships.isNotEmpty) {
      final libraryIds = memberships.map((m) => m.libraryId).toList();
      print('📚 ReaderMainScreen: Memberships changed, reloading books from ${libraryIds.length} libraries');
      context.read<BookProvider>().listenToMultipleLibraryBooks(libraryIds);
    }
  }

  @override
  void dispose() {
    context.read<LibraryProvider>().removeListener(_onMembershipsChanged);
    super.dispose();
  }

  void _initUserStreams() {
    final user = context.read<AuthProvider>().userModel;
    final uid = user?.uid ?? '';
    if (uid.isEmpty) return;
    
    // Listen to user-specific data
    context.read<LibraryProvider>().listenToUserMemberships(uid);
    context.read<BorrowProvider>().listenToUserBorrows(uid);
    context.read<BorrowTransactionProvider>().listenToUserTransactions(uid);
    context.read<ReservationProvider>().listenToUserReservations(uid);
    
    // Load books from ALL libraries the user is a member of
    // Wait a moment for memberships to load, then get all library IDs
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      final memberships = context.read<LibraryProvider>().memberships;
      if (memberships.isNotEmpty) {
        // Load books from ALL libraries the user is a member of
        final libraryIds = memberships.map((m) => m.libraryId).toList();
        print('📚 ReaderMainScreen: Loading books from ${libraryIds.length} libraries: $libraryIds');
        context.read<BookProvider>().listenToMultipleLibraryBooks(libraryIds);
      } else {
        // Fallback: use user's libraryId or uid (single library mode)
        final libraryId = user?.libraryId ?? uid;
        print('📚 ReaderMainScreen: Fallback to single library: $libraryId');
        context.read<BookProvider>().listenToLibraryBooks(libraryId);
      }
    });
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
                  onTap: () => _onTabTapped(0),
                ),
                // Placeholder slots - to be added later
                _NavItem(
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore_rounded,
                  label: 'Libraries',
                  isActive: _currentIndex == 1,
                  onTap: () => _onTabTapped(1),
                ),
                _NavItem(
                  icon: Icons.library_books_outlined,
                  activeIcon: Icons.library_books_rounded,
                  label: 'Borrows',
                  isActive: _currentIndex == 2,
                  onTap: () => _onTabTapped(2),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  isActive: _currentIndex == 3,
                  onTap: () => _onTabTapped(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTabTapped(int pageIndex) {
    setState(() => _currentIndex = pageIndex);
  }
}

/// A single nav bar item — Instagram-style with animated indicator.
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
            // Active indicator dot
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
