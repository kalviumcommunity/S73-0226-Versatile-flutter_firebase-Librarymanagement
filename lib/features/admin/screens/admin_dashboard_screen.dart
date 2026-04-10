import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/access_token_service.dart';
import '../services/email_service.dart';
import '../../books/screens/stock_management_screen.dart';
import 'manage_librarians_screen.dart';
import 'access_codes_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final adminUid = user?.uid ?? '';

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
                'Hello, ${user?.name ?? 'Admin'} 👋',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppDimens.xs),
              Text(
                'System administration and user management.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppDimens.md),

              // Role badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.md,
                  vertical: AppDimens.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: AppDimens.lg),

              // Stats cards — live from Firestore
              _buildLiveStatRow(context, adminUid),

              const SizedBox(height: AppDimens.lg),

              // Admin actions
              _buildAdminActions(context),

              const SizedBox(height: AppDimens.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveStatRow(BuildContext context, String adminUid) {
    return Row(
      children: [
        // Users count (library members)
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('library_members')
                .where('libraryId', isEqualTo: adminUid)
                .snapshots(),
            builder: (context, snap) {
              final count = snap.hasData ? snap.data!.docs.length : 0;
              return _StatCard(
                label: 'Members',
                value: '$count',
                icon: Icons.people_rounded,
                color: AppColors.primary,
              );
            },
          ),
        ),
        const SizedBox(width: AppDimens.md),
        // Books count
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('books')
                .where('libraryId', isEqualTo: adminUid)
                .snapshots(),
            builder: (context, snap) {
              final count = snap.hasData ? snap.data!.docs.length : 0;
              return _StatCard(
                label: 'Books',
                value: '$count',
                icon: Icons.menu_book_rounded,
                color: AppColors.accent,
              );
            },
          ),
        ),
        const SizedBox(width: AppDimens.md),
        // Active borrows count
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('borrows')
                .where('libraryId', isEqualTo: adminUid)
                .where('status', isEqualTo: 'active')
                .snapshots(),
            builder: (context, snap) {
              final count = snap.hasData ? snap.data!.docs.length : 0;
              return _StatCard(
                label: 'Active',
                value: '$count',
                icon: Icons.swap_horiz_rounded,
                color: AppColors.success,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdminActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppDimens.md),
        _AdminActionTile(
          icon: Icons.vpn_key_rounded,
          title: 'Generate Librarian Token',
          subtitle: 'Create a 15-min access code for librarians',
          onTap: () => _showGenerateTokenDialog(context),
        ),
        const SizedBox(height: AppDimens.sm),
        _AdminActionTile(
          icon: Icons.manage_accounts_rounded,
          title: 'Manage Users',
          subtitle: 'Promote, demote, or remove users',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManageLibrariansScreen()),
          ),
        ),
        const SizedBox(height: AppDimens.sm),
        _AdminActionTile(
          icon: Icons.vpn_key_outlined,
          title: 'Access Codes',
          subtitle: 'View all generated access tokens',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AccessCodesScreen()),
          ),
        ),
        const SizedBox(height: AppDimens.sm),
        _AdminActionTile(
          icon: Icons.library_books_rounded,
          title: 'Library Overview',
          subtitle: 'View all books and manage stock',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StockManagementScreen()),
          ),
        ),
      ],
    );
  }

  void _showGenerateTokenDialog(BuildContext context) {
    final user = context.read<AuthProvider>().userModel;
    showDialog(
      context: context,
      builder: (_) => _GenerateTokenDialog(
        adminUid: user?.uid ?? '',
        adminName: user?.name ?? 'Admin',
        libraryName: user?.libraryName ?? AppStrings.appName,
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
            Icon(icon, color: color, size: 28),
            const SizedBox(height: AppDimens.sm),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                  ),
            ),
            const SizedBox(height: AppDimens.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.md,
          vertical: AppDimens.xs,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleSmall),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

// ── Generate Token Dialog ──

class _GenerateTokenDialog extends StatefulWidget {
  final String adminUid;
  final String adminName;
  final String libraryName;

  const _GenerateTokenDialog({
    required this.adminUid,
    required this.adminName,
    required this.libraryName,
  });

  @override
  State<_GenerateTokenDialog> createState() => _GenerateTokenDialogState();
}

class _GenerateTokenDialogState extends State<_GenerateTokenDialog> {
  final AccessTokenService _tokenService = AccessTokenService();
  final AccessTokenEmailService _emailService = AccessTokenEmailService();
  String? _generatedCode;
  bool _isGenerating = false;
  bool _isSending = false;
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (widget.adminUid.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to identify admin. Please log in again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }
    setState(() => _isGenerating = true);
    try {
      final token = await _tokenService.generateToken(widget.adminUid);
      if (mounted) {
        setState(() {
          _generatedCode = token.token;
          _isGenerating = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Token generation failed: $e');
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate token: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _copyToClipboard() {
    if (_generatedCode == null) return;
    Clipboard.setData(ClipboardData(text: _generatedCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Token copied to clipboard!'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showSendEmailSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLg)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppDimens.pagePaddingH,
          right: AppDimens.pagePaddingH,
          top: AppDimens.lg,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppDimens.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Send Token via Email',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppDimens.sm),
            Text(
              'Token: $_generatedCode',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: AppDimens.md),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Recipient email address',
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.md),
            StatefulBuilder(
              builder: (sCtx, setSendState) {
                return ElevatedButton.icon(
                  onPressed: _isSending
                      ? null
                      : () async {
                          final email = _emailController.text.trim();
                          if (email.isEmpty) return;
                          setSendState(() => _isSending = true);

                          final adminName = widget.adminName;
                          final libraryName = widget.libraryName;

                          try {
                            await _emailService.send(
                              recipientEmail: email,
                              accessCode: _generatedCode!,
                              adminName: adminName,
                              libraryName: libraryName,
                            );

                            if (ctx.mounted) {
                              setSendState(() => _isSending = false);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Access code sent to $email successfully!',
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              setSendState(() => _isSending = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to send email: ${e.toString()}',
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                  icon: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(_isSending ? 'Sending...' : 'Send Token'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      title: Row(
        children: [
          Icon(Icons.vpn_key_rounded, color: AppColors.accent, size: 22),
          const SizedBox(width: AppDimens.sm),
          const Expanded(
            child: Text(
              'Librarian Access Token',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_generatedCode == null) ...[
              Text(
                'Generate a one-time access code that allows someone to sign up as a Librarian. '
                'The code is valid for 15 minutes.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
              ),
            ] else ...[
              const SizedBox(height: AppDimens.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimens.md,
                  horizontal: AppDimens.lg,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _generatedCode!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: AppDimens.xs),
                    Text(
                      'Valid for 15 minutes',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copyToClipboard,
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showSendEmailSheet,
                      icon: const Icon(Icons.email_rounded, size: 16),
                      label: const Text('Send'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: BorderSide(
                          color: AppColors.accent.withValues(alpha: 0.4),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (_generatedCode == null)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        if (_generatedCode == null)
          ElevatedButton.icon(
            onPressed: _isGenerating ? null : _generate,
            icon: _isGenerating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.generating_tokens_rounded, size: 18),
            label: Text(_isGenerating ? 'Generating...' : 'Generate'),
          ),
        if (_generatedCode != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ),
      ],
    );
  }
}
