import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/widgets/cards/transaction_card.dart';
import '../../../core/widgets/empty_states/empty_state_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/borrow_transaction_model.dart';
import '../providers/borrow_transaction_provider.dart';

/// Reader screen to view their borrow transactions and QR codes
class ReaderTransactionsScreen extends StatefulWidget {
  const ReaderTransactionsScreen({super.key});

  @override
  State<ReaderTransactionsScreen> createState() =>
      _ReaderTransactionsScreenState();
}

class _ReaderTransactionsScreenState extends State<ReaderTransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().userModel?.uid;
      if (uid != null) {
        context.read<BorrowTransactionProvider>().listenToUserTransactions(uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showTransactionQR(BorrowTransaction transaction) {
    final qrData = 'TRANSACTION:${transaction.id}:${transaction.userId}:${transaction.libraryId}';
    final dateFormat = DateFormat('dd MMM yyyy');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        title: Row(
          children: [
            Icon(Icons.qr_code_rounded, color: AppColors.accent, size: 22),
            const SizedBox(width: 8),
            const Expanded(child: Text('Transaction QR')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimens.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E3A8A),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.md),
              Text(
                '${transaction.totalBooks} ${transaction.totalBooks == 1 ? "Book" : "Books"}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Due: ${dateFormat.format(transaction.dueDate)}',
                style: TextStyle(
                  color: transaction.isOverdue
                      ? AppColors.darkError
                      : AppColors.darkTextSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDimens.sm),
              ...transaction.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.book,
                            size: 14, color: AppColors.darkTextTertiary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.bookTitle,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '×${item.quantity}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: AppDimens.sm),
              Text(
                'Show this QR code to the librarian\nwhen returning books.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.darkTextTertiary,
                  fontSize: 12,
                  height: 1.4,
                ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('My Borrows'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Overdue'),
            Tab(text: 'Returned'),
          ],
        ),
      ),
      body: Consumer<BorrowTransactionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildActiveTab(provider),
              _buildOverdueTab(provider),
              _buildReturnedTab(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActiveTab(BorrowTransactionProvider provider) {
    final activeTransactions = provider.activeTransactions
        .where((t) => !t.isOverdue)
        .toList();

    if (activeTransactions.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.library_books_outlined,
        title: 'No Active Borrows',
        message: 'You don\'t have any active borrowed books.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: AppDimens.md,
      ),
      itemCount: activeTransactions.length,
      itemBuilder: (context, index) {
        final transaction = activeTransactions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TransactionCard(
            transaction: transaction,
            onTap: () => _showTransactionQR(transaction),
          ),
        );
      },
    );
  }

  Widget _buildOverdueTab(BorrowTransactionProvider provider) {
    final overdueTransactions = provider.activeTransactions
        .where((t) => t.isOverdue)
        .toList();

    if (overdueTransactions.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.check_circle_outline,
        title: 'No Overdue Books',
        message: 'Great! You don\'t have any overdue books.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: AppDimens.md,
      ),
      itemCount: overdueTransactions.length,
      itemBuilder: (context, index) {
        final transaction = overdueTransactions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TransactionCard(
            transaction: transaction,
            onTap: () => _showTransactionQR(transaction),
          ),
        );
      },
    );
  }

  Widget _buildReturnedTab(BorrowTransactionProvider provider) {
    final returnedTransactions = provider.returnedTransactions;

    if (returnedTransactions.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.history,
        title: 'No History',
        message: 'You haven\'t returned any books yet.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: AppDimens.md,
      ),
      itemCount: returnedTransactions.length,
      itemBuilder: (context, index) {
        final transaction = returnedTransactions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TransactionCard(
            transaction: transaction,
          ),
        );
      },
    );
  }
}
