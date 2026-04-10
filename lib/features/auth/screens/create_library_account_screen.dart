import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/app_input_widgets.dart';
import '../providers/auth_provider.dart';

class CreateLibraryAccountScreen extends StatefulWidget {
  const CreateLibraryAccountScreen({super.key});

  @override
  State<CreateLibraryAccountScreen> createState() =>
      _CreateLibraryAccountScreenState();
}

class _CreateLibraryAccountScreenState
    extends State<CreateLibraryAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _libraryNameController = TextEditingController();
  final _personNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _libraryNameController.dispose();
    _personNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateLibrary() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    final success = await authProvider.signUpLibrary(
      libraryName: _libraryNameController.text,
      personName: _personNameController.text,
      email: _emailController.text,
      password: _passwordController.text,
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

                  // Library Name
                  AppTextField(
                    controller: _libraryNameController,
                    hintText: 'Library Name',
                    prefixIcon: Icons.library_books_rounded,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.text,
                    enabled: !auth.isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppStrings.fieldRequired;
                      }
                      if (value.trim().length < 2) {
                        return 'Library name must be at least 2 characters.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppDimens.md),

                  // Person Name
                  AppTextField(
                    controller: _personNameController,
                    hintText: 'Your Name',
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
                    textInputAction: TextInputAction.done,
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

                  const SizedBox(height: AppDimens.lg),

                  // Create Library button
                  AppButton(
                    label: 'Create Library Account',
                    isLoading: auth.isLoading,
                    onPressed: _handleCreateLibrary,
                  ),

                  const SizedBox(height: AppDimens.lg),

                  // Back to login link
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
                        onPressed: auth.isLoading
                            ? null
                            : () => Navigator.pop(context),
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
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: const Icon(
                Icons.library_books_rounded,
                color: AppColors.accent,
                size: 26,
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Library Account',
                    style:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                            ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Set up your library on ${AppStrings.appName}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.darkTextSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
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
