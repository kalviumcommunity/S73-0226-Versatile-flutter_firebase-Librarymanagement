import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/app_input_widgets.dart';
import '../../../shared/widgets/google_logo.dart';
import '../providers/auth_provider.dart';
import 'create_library_account_screen.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    await authProvider.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  void _navigateToSignup() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignupScreen()),
    );
  }

  void _navigateToForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  void _navigateToCreateLibraryAccount() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateLibraryAccountScreen()),
    );
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
                  const SizedBox(height: AppDimens.xl),

                  // Brand header
                  _buildBrandHeader(),

                  const SizedBox(height: AppDimens.xl),

                  // Error message
                  if (auth.errorMessage != null) ...[
                    _buildErrorBanner(auth.errorMessage!),
                    const SizedBox(height: AppDimens.md),
                  ],

                  // Google sign-in button (top, like reference)
                  _buildGoogleButton(auth),

                  const SizedBox(height: AppDimens.lg),

                  // Or divider
                  _buildOrDivider('Or sign in with email'),

                  const SizedBox(height: AppDimens.lg),

                  // Email field
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

                  // Password field
                  AppTextField(
                    controller: _passwordController,
                    hintText: AppStrings.password,
                    prefixIcon: Icons.lock_outlined,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
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

                  const SizedBox(height: AppDimens.sm),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed:
                          auth.isLoading ? null : _navigateToForgotPassword,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.sm,
                          vertical: AppDimens.xs,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        AppStrings.forgotPassword,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDimens.md),

                  // Login button
                  AppButton(
                    label: AppStrings.login,
                    isLoading: auth.isLoading,
                    onPressed: _handleLogin,
                  ),

                  const SizedBox(height: AppDimens.lg),

                  // Signup link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.noAccount,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.darkTextSecondary,
                            ),
                      ),
                      TextButton(
                        onPressed: auth.isLoading ? null : _navigateToSignup,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.xs,
                          ),
                        ),
                        child: Text(
                          'Sign up',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimens.md),

                  // Create Library Account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Want to create a library account?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.darkTextSecondary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.sm),
                  SizedBox(
                    height: AppDimens.buttonHeight,
                    child: OutlinedButton.icon(
                      onPressed: auth.isLoading
                          ? null
                          : _navigateToCreateLibraryAccount,
                      icon: const Icon(Icons.library_books_rounded, size: 20),
                      label: const Text(
                        'Create Library Account',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: BorderSide(
                          color: AppColors.accent.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.buttonRadius),
                        ),
                        backgroundColor:
                            AppColors.accent.withValues(alpha: 0.04),
                      ),
                    ),
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

  Widget _buildBrandHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.darkPrimary,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          ),
          child: const Icon(
            Icons.local_library_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: AppDimens.md),
        Text(
          AppStrings.appName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppDimens.xs),
        Text(
          AppStrings.loginSubtitle,
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
            : () => context.read<AuthProvider>().signInWithGoogle(),
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
