import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'librarian_borrow_screen.dart';
import 'librarian_return_screen.dart';

/// Combined screen with tabs for Issue and Return
class LibrarianBorrowReturnScreen extends StatefulWidget {
  final String libraryId;

  const LibrarianBorrowReturnScreen({super.key, required this.libraryId});

  @override
  State<LibrarianBorrowReturnScreen> createState() =>
      _LibrarianBorrowReturnScreenState();
}

class _LibrarianBorrowReturnScreenState
    extends State<LibrarianBorrowReturnScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Borrow & Return',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.darkPrimary,
          labelColor: AppColors.darkPrimary,
          unselectedLabelColor: AppColors.darkTextSecondary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.add_circle_outline),
              text: 'Issue Books',
            ),
            Tab(
              icon: Icon(Icons.assignment_return_outlined),
              text: 'Return Books',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          LibrarianBorrowScreen(libraryId: widget.libraryId),
          LibrarianReturnScreen(libraryId: widget.libraryId),
        ],
      ),
    );
  }
}
