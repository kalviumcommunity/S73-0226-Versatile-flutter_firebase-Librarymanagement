import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../auth/providers/auth_provider.dart';

/// Admin reports & analytics screen showing library statistics.
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final _firestore = FirebaseFirestore.instance;

  int _totalBooks = 0;
  int _totalCopies = 0;
  int _activeBorrows = 0;
  int _overdueBorrows = 0;
  int _pendingReservations = 0;
  int _totalMembers = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    final adminUid = context.read<AuthProvider>().userModel?.uid ?? '';

    try {
      // Books
      final booksSnap = await _firestore
          .collection('books')
          .where('libraryId', isEqualTo: adminUid)
          .get();
      _totalBooks = booksSnap.docs.length;
      _totalCopies = booksSnap.docs.fold<int>(
        0,
        (sum, doc) => sum + (doc.data()['totalCopies'] as int? ?? 0),
      );

      // Borrows
      final borrowsSnap = await _firestore
          .collection('borrows')
          .where('libraryId', isEqualTo: adminUid)
          .where('status', isEqualTo: 'active')
          .get();
      _activeBorrows = borrowsSnap.docs.length;
      _overdueBorrows = borrowsSnap.docs.where((doc) {
        final dueDate = (doc.data()['dueDate'] as Timestamp?)?.toDate();
        return dueDate != null && DateTime.now().isAfter(dueDate);
      }).length;

      // Reservations
      final reservationsSnap = await _firestore
          .collection('reservations')
          .where('libraryId', isEqualTo: adminUid)
          .where('status', isEqualTo: 'pending')
          .get();
      _pendingReservations = reservationsSnap.docs.length;

      // Members
      final membersSnap = await _firestore
          .collection('library_members')
          .where('libraryId', isEqualTo: adminUid)
          .get();
      _totalMembers = membersSnap.docs.length;
    } catch (e) {
      debugPrint('Reports error: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppDimens.pagePaddingH),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppDimens.sm),
                    Text(
                      'Overview',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppDimens.md),

                    // Library stats
                    _SectionTitle(title: 'Library'),
                    const SizedBox(height: AppDimens.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Members',
                            value: '$_totalMembers',
                            icon: Icons.group_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppDimens.sm),
                        Expanded(
                          child: _StatCard(
                            label: 'Books',
                            value: '$_totalBooks',
                            icon: Icons.menu_book_rounded,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: AppDimens.sm),
                        Expanded(
                          child: _StatCard(
                            label: 'Total Copies',
                            value: '$_totalCopies',
                            icon: Icons.inventory_2_rounded,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimens.lg),

                    // Activity stats
                    _SectionTitle(title: 'Activity'),
                    const SizedBox(height: AppDimens.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Active Borrows',
                            value: '$_activeBorrows',
                            icon: Icons.swap_horiz_rounded,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: AppDimens.sm),
                        Expanded(
                          child: _StatCard(
                            label: 'Overdue',
                            value: '$_overdueBorrows',
                            icon: Icons.warning_rounded,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(width: AppDimens.sm),
                        Expanded(
                          child: _StatCard(
                            label: 'Reservations',
                            value: '$_pendingReservations',
                            icon: Icons.bookmark_rounded,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimens.xl),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.md),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: AppDimens.sm),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppDimens.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
