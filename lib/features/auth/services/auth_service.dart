import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

/// Web client ID for Google Sign-In on web platform.
const String _webClientId =
    '1043576322716-pa48klhmptjjlb26ajlbpi4s8h94oajm.apps.googleusercontent.com';

/// Handles Firebase Authentication operations.
class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              clientId: kIsWeb ? _webClientId : null,
              serverClientId: _webClientId,
            );

  /// Current authenticated user, or null.
  User? get currentUser => _auth.currentUser;

  /// Stream that emits on auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password.
  /// Throws [FirebaseAuthException] on failure.
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw AuthException(
        code: 'null-user',
        message: 'Authentication succeeded but user is null.',
      );
    }
    return user;
  }

  /// Create a new account with email and password.
  Future<User> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw AuthException(
        code: 'null-user',
        message: 'Account creation succeeded but user is null.',
      );
    }
    return user;
  }

  /// Sign in with Google (google_sign_in 6.x API).
  /// Returns the Firebase [User] and whether this is a new user.
  Future<({User user, bool isNewUser})> signInWithGoogle() async {
    // Trigger the Google Sign-In flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // User cancelled the sign-in
      throw AuthException(
        code: 'google-sign-in-cancelled',
        message: 'Google sign-in was cancelled.',
      );
    }

    // Obtain the auth details from the Google sign-in
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a Firebase credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase with the Google credential
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) {
      throw AuthException(
        code: 'null-user',
        message: 'Google sign-in succeeded but user is null.',
      );
    }

    final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
    return (user: user, isNewUser: isNewUser);
  }

  /// Sign out the current user (including Google).
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Send a password-reset email.
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Check whether the current user already has a password (email/password) provider linked.
  bool hasPasswordProvider() {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((info) => info.providerId == 'password');
  }

  /// Link an email/password credential to the currently signed-in user.
  /// This allows a Google-only user to also sign in with email + password.
  Future<void> linkPasswordProvider({required String password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException(
        code: 'no-current-user',
        message: 'No user is currently signed in.',
      );
    }
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw AuthException(
        code: 'no-email',
        message: 'Current user has no email address.',
      );
    }
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.linkWithCredential(credential);
    // Reload user so provider data is fresh for future checks
    await user.reload();
  }

  /// Returns a human-readable error message for Firebase Auth errors.
  static String mapErrorCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'google-sign-in-cancelled':
        return 'Google sign-in was cancelled.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

class AuthException implements Exception {
  final String code;
  final String message;

  AuthException({required this.code, required this.message});

  @override
  String toString() => 'AuthException($code): $message';
}
