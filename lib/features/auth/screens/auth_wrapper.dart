import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/admin_main_screen.dart';
import '../../../shared/widgets/librarian_main_screen.dart';
import '../../../shared/widgets/reader_main_screen.dart';
import '../providers/auth_provider.dart';
import 'access_code_prompt_screen.dart';
import 'login_screen.dart';
import 'set_password_screen.dart';

/// Root widget that listens to auth state and routes
/// the user to the correct screen based on their role.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.initial:
      case AuthStatus.loading:
        return Scaffold(
          backgroundColor: AppColors.darkBackground,
          body: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkPrimary),
              ),
            ),
          ),
        );

      case AuthStatus.authenticated:
        // New Google user → ask for access code first
        if (auth.needsAccessCodePrompt) {
          return const AccessCodePromptScreen();
        }
        if (auth.needsPasswordSetup) {
          return const SetPasswordScreen();
        }
        return _buildHomeForRole(auth.userModel?.role);

      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        return const LoginScreen();
    }
  }

  Widget _buildHomeForRole(String? role) {
    switch (role) {
      case AppStrings.admin:
        return const AdminMainScreen();
      case AppStrings.librarian:
        return const LibrarianMainScreen();
      case AppStrings.reader:
      default:
        return const ReaderMainScreen();
    }
  }
}
