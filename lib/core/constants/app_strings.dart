class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'LibraryOne';
  static const String appTagline = 'Your digital library, reimagined.';

  // Auth
  static const String login = 'Log In';
  static const String signup = 'Create Account';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String fullName = 'Full Name';
  static const String forgotPassword = 'Forgot Password?';
  static const String noAccount = "Don't have an account?";
  static const String haveAccount = 'Already have an account?';
  static const String loginSubtitle = 'Welcome back! Sign in to continue.';
  static const String signupSubtitle = 'Join LibraryOne to get started.';
  static const String loggingIn = 'Signing in...';
  static const String signingUp = 'Creating account...';

  // Roles
  static const String reader = 'reader';
  static const String librarian = 'librarian';
  static const String admin = 'admin';

  // Errors
  static const String genericError = 'Something went wrong. Please try again.';
  static const String invalidEmail = 'Please enter a valid email address.';
  static const String weakPassword = 'Password must be at least 6 characters.';
  static const String emailInUse = 'An account already exists with this email.';
  static const String userNotFound = 'No account found with this email.';
  static const String wrongPassword = 'Incorrect password. Please try again.';
  static const String fieldRequired = 'This field is required.';
}
