import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../shared/widgets/app_input_widgets.dart';
import '../providers/auth_provider.dart';

/// Shown after Google sign-in for brand-new users.
/// Asks if they have a librarian access code. If yes → librarian, if skip → reader.
/// After this, proceeds to the SetPasswordScreen.
class AccessCodePromptScreen extends StatefulWidget {
  const AccessCodePromptScreen({super.key});

  @override
  State<AccessCodePromptScreen> createState() => _AccessCodePromptScreenState();
}

class _AccessCodePromptScreenState extends State<AccessCodePromptScreen> {
  final _codeController = TextEditingController();
  bool _isValidating = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleApplyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isValidating = true);

    final auth = context.read<AuthProvider>();
    auth.clearError();

    final success = await auth.applyAccessCode(code);

    if (mounted) {
      setState(() => _isValidating = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access code applied! You are now a Librarian.'),
            backgroundColor: AppColors.darkSuccess,
          ),
        );
        // Move past the access code prompt → password setup
        auth.skipAccessCodePrompt();
      }
    }
  }

  void _handleSkip() {
    final auth = context.read<AuthProvider>();
    auth.clearError();
    auth.skipAccessCodePrompt();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.userModel?.name ?? 'there';

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.pagePaddingH + 4,
              vertical: AppDimens.pagePaddingV,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppDimens.xl),

                // Icon
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.vpn_key_rounded,
                      color: AppColors.accent,
                      size: 40,
                    ),
                  ),
                ),

                const SizedBox(height: AppDimens.lg),

                // Header
                Text(
                  'Welcome, $name!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppDimens.sm),
                Text(
                  'Do you have a librarian access code?\nEnter it below to join as a Librarian.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                ),

                const SizedBox(height: AppDimens.xl),

                // Error
                if (auth.errorMessage != null) ...[
                  _buildErrorBanner(auth.errorMessage!),
                  const SizedBox(height: AppDimens.md),
                ],

                // Access code field
                AppTextField(
                  controller: _codeController,
                  hintText: 'Access Code (e.g. ABC123)',
                  prefixIcon: Icons.vpn_key_outlined,
                  textInputAction: TextInputAction.done,
                  enabled: !_isValidating,
                ),

                const SizedBox(height: AppDimens.lg),

                // Apply button
                AppButton(
                  label: 'Apply Access Code',
                  isLoading: _isValidating,
                  onPressed: _handleApplyCode,
                  icon: Icons.check_rounded,
                ),

                const SizedBox(height: AppDimens.md),

                // Skip button
                Center(
                  child: TextButton(
                    onPressed: _isValidating ? null : _handleSkip,
                    child: Text(
                      'Skip — Continue as Reader',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppDimens.lg),

                // Info box
                Container(
                  padding: const EdgeInsets.all(AppDimens.md),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: AppColors.info.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: AppDimens.sm),
                      Expanded(
                        child: Text(
                          'Access codes are provided by your library admin. '
                          'If you don\'t have one, just skip to continue as a Reader.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.info.withValues(alpha: 0.85),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimens.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.darkError, size: 20),
          const SizedBox(width: AppDimens.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.darkError,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
