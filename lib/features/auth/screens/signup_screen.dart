import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/app_input_widgets.dart';
import '../../../shared/widgets/google_logo.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _accessTokenController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _accessTokenController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    final success = await authProvider.signUp(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      accessToken: _accessTokenController.text.trim().isNotEmpty
          ? _accessTokenController.text.trim()
          : null,
    );

    if (success && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppDimens.md),

                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed:
                          auth.isLoading ? null : () => Navigator.pop(context),
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

                  const SizedBox(height: AppDimens.lg),

                  // Header
                  _buildHeader(),

                  const SizedBox(height: AppDimens.xl),

                  // Error message
                  if (auth.errorMessage != null) ...[
                    _buildErrorBanner(auth.errorMessage!),
                    const SizedBox(height: AppDimens.md),
                  ],

                  // Google sign-up button (top)
                  _buildGoogleButton(auth),

                  const SizedBox(height: AppDimens.lg),

                  // Or divider
                  _buildOrDivider('Or sign up with email'),

                  const SizedBox(height: AppDimens.lg),

                  // Full name
                  AppTextField(
                    controller: _nameController,
                    hintText: AppStrings.fullName,
                    prefixIcon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.name,
                    enabled: !auth.isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppStrings.fieldRequired;
                      }
                      if (value.trim().length < 2) {
                        return 'Name must be at least 2 characters.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppDimens.md),

                  // Email
                  AppTextField(
                    controller: _emailController,
                    hintText: AppStrings.email,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enabled: !auth.isLoading,
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

                  const SizedBox(height: AppDimens.md),

                  // Password
                  AppTextField(
                    controller: _passwordController,
                    hintText: AppStrings.password,
                    prefixIcon: Icons.lock_outlined,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    enabled: !auth.isLoading,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: AppColors.darkTextTertiary,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.fieldRequired;
                      }
                      if (value.length < 6) {
                        return AppStrings.weakPassword;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppDimens.md),

                  // Confirm password
                  AppTextField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirm Password',
                    prefixIcon: Icons.lock_outlined,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.next,
                    enabled: !auth.isLoading,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: AppColors.darkTextTertiary,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.fieldRequired;
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppDimens.md),

                  // Access token (optional)
                  _buildOrDivider('Have a librarian access code?'),
                  const SizedBox(height: AppDimens.md),
                  AppTextField(
                    controller: _accessTokenController,
                    hintText: 'Access Code (optional)',
                    prefixIcon: Icons.vpn_key_outlined,
                    textInputAction: TextInputAction.done,
                    enabled: !auth.isLoading,
                  ),

                  const SizedBox(height: AppDimens.lg),

                  // Sign up button
                  AppButton(
                    label: AppStrings.signup,
                    isLoading: auth.isLoading,
                    onPressed: _handleSignup,
                  ),

                  const SizedBox(height: AppDimens.lg),

                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.haveAccount,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.darkTextSecondary,
                            ),
                      ),
                      TextButton(
                        onPressed:
                            auth.isLoading ? null : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.xs,
                          ),
                        ),
                        child: Text(
                          AppStrings.login,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimens.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Widgets ──

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.signup,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppDimens.xs),
        Text(
          AppStrings.signupSubtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.darkTextSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildOrDivider(String label) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.darkBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.md),
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.darkTextTertiary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.darkBorder)),
      ],
    );
  }

  Widget _buildGoogleButton(AuthProvider auth) {
    return SizedBox(
      height: AppDimens.buttonHeight,
      child: OutlinedButton(
        onPressed: auth.isLoading
            ? null
            : () async {
                final success =
                    await context.read<AuthProvider>().signInWithGoogle();
                if (success && mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
          ),
          side: const BorderSide(color: AppColors.border, width: 1.2),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: const GoogleLogo(size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'Continue with Google',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937), // Dark gray for better contrast on white button
              ),
            ),
          ],
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
