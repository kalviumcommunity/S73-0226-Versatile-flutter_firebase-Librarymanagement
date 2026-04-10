import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' show User, FirebaseAuthException;
import '../../admin/services/access_token_service.dart';
import '../../library/models/library_model.dart';
import '../../library/repository/library_repository.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../repository/auth_repository.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final AuthRepository _authRepository;
  final AccessTokenService _accessTokenService;
  final LibraryRepository _libraryRepository;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _userModel;
  String? _errorMessage;
  bool _googleSignInInProgress = false;
  bool _needsPasswordSetup = false;
  bool _needsAccessCodePrompt = false;

  AuthProvider({
    AuthService? authService,
    AuthRepository? authRepository,
    AccessTokenService? accessTokenService,
    LibraryRepository? libraryRepository,
  })  : _authService = authService ?? AuthService(),
        _authRepository = authRepository ?? AuthRepository(),
        _accessTokenService = accessTokenService ?? AccessTokenService(),
        _libraryRepository = libraryRepository ?? LibraryRepository() {
    _init();
  }

  // -- Getters --
  AuthStatus get status => _status;
  UserModel? get userModel => _userModel;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  User? get firebaseUser => _authService.currentUser;
  bool get needsPasswordSetup => _needsPasswordSetup;
  bool get needsAccessCodePrompt => _needsAccessCodePrompt;

  // -- Initialization --
  void _init() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      _status = AuthStatus.unauthenticated;
      _userModel = null;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    // Skip if Google sign-in is in progress — it handles Firestore doc creation itself
    if (_googleSignInInProgress) return;

    try {
      _status = AuthStatus.loading;
      notifyListeners();

      _userModel = await _authRepository.getUser(user.uid);

      if (_userModel == null) {
        // User exists in Auth but not Firestore — edge case
        _status = AuthStatus.unauthenticated;
        await _authService.signOut();
      } else {
        _status = AuthStatus.authenticated;
      }
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Failed to load user profile.';
    }
    notifyListeners();
  }

  // -- Sign In --
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final user = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      _userModel = await _authRepository.getUser(user.uid);

      if (_userModel == null) {
        _errorMessage = 'User profile not found. Contact support.';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = AuthService.mapErrorCode(e.code);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      _errorMessage = AuthService.mapErrorCode(e.code);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = AuthService.mapErrorCode('unknown');
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // -- Sign Up --
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    String? accessToken,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      // If access token provided, validate it first
      String role = 'reader';
      String? libraryId;
      String? libraryName;
      if (accessToken != null && accessToken.trim().isNotEmpty) {
        final token = await _accessTokenService.validateToken(accessToken);
        if (token == null) {
          _errorMessage = 'Invalid or expired access token.';
          _status = AuthStatus.error;
          notifyListeners();
          return false;
        }
        role = 'librarian';
        libraryId = token.createdByUid; // Track which library the librarian belongs to
        // Fetch the library name so the librarian knows which library they belong to
        final library = await _libraryRepository.getLibrary(libraryId);
        libraryName = library?.name;
      }

      final user = await _authService.signUpWithEmail(
        email: email,
        password: password,
      );

      final newUser = UserModel(
        uid: user.uid,
        name: name.trim(),
        email: email.trim(),
        role: role,
        createdAt: DateTime.now(),
        hasSetPassword: true,
        libraryId: libraryId,
        libraryName: libraryName,
      );

      await _authRepository.createUser(newUser);

      // Mark token as used and add librarian to library members
      if (role == 'librarian' && accessToken != null && libraryId != null) {
        await _accessTokenService.markTokenUsed(accessToken, user.uid);
        // Add librarian to the library_members collection
        await _libraryRepository.joinLibrary(
          libraryId: libraryId,
          libraryName: libraryName ?? '',
          userId: user.uid,
          userName: name.trim(),
        );
      }

      _userModel = newUser;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = AuthService.mapErrorCode(e.code);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      _errorMessage = AuthService.mapErrorCode(e.code);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = AuthService.mapErrorCode('unknown');
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // -- Sign Up as Admin (Library Account) --
  Future<bool> signUpLibrary({
    required String libraryName,
    required String personName,
    required String email,
    required String password,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final user = await _authService.signUpWithEmail(
        email: email,
        password: password,
      );

      final newUser = UserModel(
        uid: user.uid,
        name: personName.trim(),
        email: email.trim(),
        role: 'admin',
        createdAt: DateTime.now(),
        hasSetPassword: true,
        libraryName: libraryName.trim(),
        libraryId: user.uid, // Admin's own library
      );

      await _authRepository.createUser(newUser);

      // Also create the library document in 'libraries' collection
      final library = LibraryModel(
        id: user.uid,
        name: libraryName.trim(),
        adminUid: user.uid,
        adminName: personName.trim(),
        createdAt: DateTime.now(),
      );
      await _libraryRepository.createLibrary(library);

      _userModel = newUser;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = AuthService.mapErrorCode(e.code);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      _errorMessage = AuthService.mapErrorCode(e.code);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = AuthService.mapErrorCode('unknown');
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // -- Google Sign In (works as both login & signup) --
  Future<bool> signInWithGoogle() async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      _googleSignInInProgress = true;
      notifyListeners();

      final result = await _authService.signInWithGoogle();
      final user = result.user;

      // Check if user doc already exists in Firestore (by UID first, then email)
      _userModel = await _authRepository.getUser(user.uid);

      if (_userModel == null) {
        // UID not found — check by email (handles case where same email
        // was used for manual signup and Google creates a different UID)
        final existingByEmail = await _authRepository.getUserByEmail(
          user.email ?? '',
        );

        if (existingByEmail != null) {
          // Existing user found by email — migrate Firestore doc to new UID
          _userModel = existingByEmail.copyWith(uid: user.uid);
          await _authRepository.createUser(_userModel!);
          await _authRepository.deleteUser(existingByEmail.uid);
        } else {
          // Truly new Google user — create as reader initially,
          // then prompt for access code before setting password
          final newUser = UserModel(
            uid: user.uid,
            name: user.displayName ?? 'User',
            email: user.email ?? '',
            role: 'reader',
            createdAt: DateTime.now(),
            hasSetPassword: false,
          );
          await _authRepository.createUser(newUser);
          _userModel = newUser;
          _needsAccessCodePrompt = true;
        }
      }

      _googleSignInInProgress = false;

      // Reload Firebase user to get fresh providerData after signInWithCredential
      await user.reload();
      final refreshedUser = _authService.currentUser;
      final hasPasswordOnFirebase = refreshedUser?.providerData
              .any((info) => info.providerId == 'password') ??
          false;

      if (!hasPasswordOnFirebase) {
        // Password provider is missing on Firebase Auth.
        // This happens when: (1) brand new Google user, OR
        // (2) Google sign-in stripped the password provider from an existing account.
        // Either way, user must (re)set their password so manual login works.
        _needsPasswordSetup = true;

        // Keep Firestore in sync
        if (_userModel!.hasSetPassword) {
          await _authRepository.updateHasSetPassword(_userModel!.uid, false);
          _userModel = _userModel!.copyWith(hasSetPassword: false);
        }
      }

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _googleSignInInProgress = false;
      _errorMessage = AuthService.mapErrorCode(e.code);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      _googleSignInInProgress = false;
      // User cancelled — silently go back to unauthenticated
      if (e.code == 'google-sign-in-cancelled') {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
      _errorMessage = AuthService.mapErrorCode(e.code);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _googleSignInInProgress = false;
      _errorMessage = AuthService.mapErrorCode('unknown');
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // -- Apply Access Code (for Google sign-in users) --
  Future<bool> applyAccessCode(String code) async {
    try {
      _errorMessage = null;
      notifyListeners();

      final token = await _accessTokenService.validateToken(code);
      if (token == null) {
        _errorMessage = 'Invalid or expired access code.';
        notifyListeners();
        return false;
      }

      // Promote user to librarian
      if (_userModel != null) {
        // Fetch the library name
        final library = await _libraryRepository.getLibrary(token.createdByUid);
        final libName = library?.name;

        await _authRepository.updateUserRole(_userModel!.uid, 'librarian');
        await _authRepository.updateUserProfile(_userModel!.uid, {
          'libraryId': token.createdByUid,
          if (libName != null) 'libraryName': libName,
        });
        await _accessTokenService.markTokenUsed(code, _userModel!.uid);

        // Add librarian to library_members collection
        await _libraryRepository.joinLibrary(
          libraryId: token.createdByUid,
          libraryName: libName ?? '',
          userId: _userModel!.uid,
          userName: _userModel!.name,
        );

        _userModel = _userModel!.copyWith(
          role: 'librarian',
          libraryId: token.createdByUid,
          libraryName: libName,
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to validate access code.';
      notifyListeners();
      return false;
    }
  }

  // -- Skip Access Code Prompt --
  void skipAccessCodePrompt() {
    _needsAccessCodePrompt = false;
    notifyListeners();
  }

  // -- Sign Out --
  Future<void> signOut() async {
    await _authService.signOut();
    _userModel = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    _needsAccessCodePrompt = false;
    _needsPasswordSetup = false;
    notifyListeners();
  }

  // -- Forgot Password --
  Future<bool> sendPasswordResetEmail({required String email}) async {
    try {
      _errorMessage = null;
      notifyListeners();
      await _authService.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = AuthService.mapErrorCode(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = AuthService.mapErrorCode('unknown');
      notifyListeners();
      return false;
    }
  }

  // -- Link Password to Google Account --
  Future<bool> linkPassword({required String password}) async {
    try {
      _errorMessage = null;
      notifyListeners();

      await _authService.linkPasswordProvider(password: password);

      // Update Firestore so we never ask again
      if (_userModel != null) {
        await _authRepository.updateHasSetPassword(_userModel!.uid, true);
        _userModel = _userModel!.copyWith(hasSetPassword: true);
      }

      _needsPasswordSetup = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = AuthService.mapErrorCode(e.code);
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      _errorMessage = AuthService.mapErrorCode(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = AuthService.mapErrorCode('unknown');
      notifyListeners();
      return false;
    }
  }

  // -- Clear Error --
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // -- Update User Profile --
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_userModel == null) return false;
    try {
      await _authRepository.updateUserProfile(_userModel!.uid, data);

      // If libraryName is updated, also update the library document
      if (data.containsKey('libraryName') && _userModel!.isAdmin) {
        final libraryId = _userModel!.libraryId ?? _userModel!.uid;
        await _libraryRepository.updateLibrary(libraryId, {
          'name': data['libraryName'],
        });
      }

      // Update local model
      _userModel = _userModel!.copyWith(
        name: data['name'] as String? ?? _userModel!.name,
        phone: data.containsKey('phone') ? data['phone'] as String? : _userModel!.phone,
        age: data.containsKey('age') ? data['age'] as int? : _userModel!.age,
        profilePicUrl: data.containsKey('profilePicUrl')
            ? data['profilePicUrl'] as String?
            : _userModel!.profilePicUrl,
        libraryName: data.containsKey('libraryName')
            ? data['libraryName'] as String?
            : _userModel!.libraryName,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile.';
      notifyListeners();
      return false;
    }
  }

  // -- Refresh User from Firestore --
  Future<void> refreshUser() async {
    if (_userModel == null) return;
    final fresh = await _authRepository.getUser(_userModel!.uid);
    if (fresh != null) {
      _userModel = fresh;
      notifyListeners();
    }
  }
}
