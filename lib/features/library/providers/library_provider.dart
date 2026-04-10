import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/providers/base_provider.dart';
import '../models/library_model.dart';
import '../repository/library_repository.dart';

/// Provider for library discovery and membership.
class LibraryProvider extends BaseProvider {
  final LibraryRepository _repo = LibraryRepository();

  // ── All libraries (discovery) ──
  List<LibraryModel> _libraries = [];
  List<LibraryModel> get libraries => _libraries;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ── User's joined libraries ──
  List<LibraryMembership> _memberships = [];
  List<LibraryMembership> get memberships => _memberships;

  // ── Current library context (for librarian/admin) ──
  LibraryModel? _currentLibrary;
  LibraryModel? get currentLibrary => _currentLibrary;

  String? _error;
  String? get error => _error;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize the provider
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    debugPrint('📚 LibraryProvider: Initializing...');
    _isInitialized = true;
    _listenToLibraries();
  }

  /// Listen to all libraries for discovery.
  void _listenToLibraries() {
    if (isDisposed) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    final subscription = _repo.librariesStream().listen(
      (list) {
        if (isDisposed) return;
        debugPrint('📚 Libraries stream received ${list.length} libraries');
        _libraries = list;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        if (isDisposed) return;
        debugPrint('📚 Libraries stream error: $e');
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
    
    addSubscription('libraries', subscription);
  }

  /// Refresh the libraries stream (retry on error).
  void refreshLibraries() {
    cancelSubscription('libraries');
    _listenToLibraries();
  }

  /// Listen to user's memberships.
  void listenToUserMemberships(String userId) {
    if (isDisposed) return;
    
    final subscription = _repo.userMembershipsStream(userId).listen(
      (list) {
        if (isDisposed) return;
        _memberships = list;
        notifyListeners();
      },
      onError: (e) {
        if (isDisposed) return;
        debugPrint('📚 Memberships stream error: $e');
      },
    );
    
    addSubscription('memberships', subscription);
  }

  /// Join a library.
  Future<bool> joinLibrary({
    required String libraryId,
    required String libraryName,
    required String userId,
    required String userName,
    double? amountPaid,
    String? paymentId,
    String? planName,
  }) async {
    try {
      _error = null;
      await _repo.joinLibrary(
        libraryId: libraryId,
        libraryName: libraryName,
        userId: userId,
        userName: userName,
        amountPaid: amountPaid,
        paymentId: paymentId,
        planName: planName,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Leave a library.
  Future<bool> leaveLibrary(String libraryId, String userId) async {
    try {
      _error = null;
      await _repo.leaveLibrary(libraryId, userId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Check if user is member of a library.
  bool isMember(String libraryId) {
    return _memberships.any((m) => m.libraryId == libraryId);
  }

  /// Load the library owned by an admin. Creates the doc if it doesn't exist.
  Future<void> loadAdminLibrary(String adminUid, {String? adminName, String? libraryName}) async {
    _currentLibrary = await _repo.getLibraryByAdmin(adminUid);
    if (_currentLibrary == null && adminName != null && libraryName != null) {
      // Library doc missing — recreate it
      debugPrint('📚 Library doc missing for admin $adminUid, creating...');
      _currentLibrary = await _repo.ensureLibraryExists(
        adminUid: adminUid,
        adminName: adminName,
        libraryName: libraryName,
      );
    }
    notifyListeners();
  }

  /// Load a specific library.
  Future<void> loadLibrary(String libraryId) async {
    _currentLibrary = await _repo.getLibrary(libraryId);
    notifyListeners();
  }

  /// Search libraries by name.
  List<LibraryModel> searchLibraries(String query) {
    if (query.trim().isEmpty) return _libraries;
    final q = query.toLowerCase();
    return _libraries
        .where((lib) => lib.name.toLowerCase().contains(q))
        .toList();
  }

  /// Update library details.
  Future<bool> updateLibrary(String libraryId, Map<String, dynamic> data) async {
    try {
      _error = null;
      await _repo.updateLibrary(libraryId, data);
      // Reload current library if it was updated
      if (_currentLibrary?.id == libraryId) {
        _currentLibrary = await _repo.getLibrary(libraryId);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get a library by ID from the already-loaded list.
  LibraryModel? getLibraryById(String libraryId) {
    try {
      return _libraries.firstWhere((lib) => lib.id == libraryId);
    } catch (_) {
      return null;
    }
  }
}
