import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/app_input_widgets.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    final success = await authProvider.sendPasswordResetEmail(
      email: _emailController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _emailSent = success;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

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
                const SizedBox(height: AppDimens.md),

                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.darkSurfaceVariant,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusMd),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppDimens.xl),

                // Icon
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _emailSent ? Icons.mark_email_read_rounded : Icons.lock_reset_rounded,
                      color: AppColors.accent,
                      size: 36,
                    ),
                  ),
                ),

                const SizedBox(height: AppDimens.lg),

                // Title
                Text(
                  _emailSent ? 'Check your email' : AppStrings.forgotPassword,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),

                const SizedBox(height: AppDimens.sm),

                // Subtitle
                Text(
                  _emailSent
                      ? 'We\'ve sent a password reset link to\n${_emailController.text.trim()}'
                      : 'Enter your email address and we\'ll send you a link to reset your password.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                ),

                const SizedBox(height: AppDimens.xl),

                if (_emailSent) ...[
                  // Success state — show return button
                  AppButton(
                    label: 'Back to Login',
                    onPressed: () => Navigator.pop(context),
                  ),

                  const SizedBox(height: AppDimens.md),

                  // Resend option
                  Center(
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() => _emailSent = false);
                            },
                      child: Text(
                        'Didn\'t receive the email? Try again',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Error message
                  if (auth.errorMessage != null) ...[
                    _buildErrorBanner(auth.errorMessage!),
                    const SizedBox(height: AppDimens.md),
                  ],

                  // Email form
                  Form(
                    key: _formKey,
                    child: AppTextField(
                      controller: _emailController,
                      hintText: AppStrings.email,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      enabled: !_isLoading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppStrings.fieldRequired;
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value.trim())) {
                          return AppStrings.invalidEmail;
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: AppDimens.lg),

                  // Send link button
                  AppButton(
                    label: 'Send Reset Link',
                    isLoading: _isLoading,
                    onPressed: _handleResetPassword,
                  ),
                ],

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
