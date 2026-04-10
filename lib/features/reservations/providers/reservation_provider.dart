import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/reservation_model.dart';
import '../repository/reservation_repository.dart';
import '../../borrow/models/borrow_transaction_model.dart';

/// Provider for reservation operations.
class ReservationProvider extends ChangeNotifier {
  final ReservationRepository _repo = ReservationRepository();

  List<Reservation> _reservations = [];
  List<Reservation> get reservations => _reservations;

  List<Reservation> get pendingReservations =>
      _reservations.where((r) => r.status == ReservationStatus.pending && !r.isExpired).toList();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  StreamSubscription? _reservationsSub;

  /// Listen to reservations for a specific user.
  void listenToUserReservations(String userId) {
    print('📋 ReservationProvider: Starting to listen to user reservations for userId: $userId');
    _reservationsSub?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    _reservationsSub = _repo.userReservationsStream(userId).listen(
      (list) {
        print('📋 ReservationProvider: Received ${list.length} reservations for user');
        _reservations = list;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('🔖 Reservations stream error: $e');
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Listen to pending reservations for a library (librarian view).
  void listenToPendingReservations(String libraryId) {
    print('📋 ReservationProvider: Starting to listen to pending reservations for libraryId: $libraryId');
    _reservationsSub?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    _reservationsSub = _repo.pendingReservationsStream(libraryId).listen(
      (list) {
        print('📋 ReservationProvider: Received ${list.length} pending reservations for library');
        _reservations = list;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('🔖 Pending reservations stream error: $e');
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Listen to all reservations for a library (history view).
  void listenToLibraryReservations(String libraryId) {
    _reservationsSub?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    _reservationsSub = _repo.libraryReservationsStream(libraryId).listen(
      (list) {
        _reservations = list;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('🔖 Library reservations stream error: $e');
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Create a reservation with multiple books.
  Future<bool> createReservation({
    required String userId,
    required String userName,
    required String userEmail,
    required String libraryId,
    required String libraryName,
    required List<ReservationItem> items,
  }) async {
    try {
      _error = null;
      print('📋 ReservationProvider: Starting createReservation');

      // Check total quantity limit (max 3 books per library)
      final totalQuantity = items.fold(0, (sum, item) => sum + item.quantity);
      print('📋 Total quantity to reserve: $totalQuantity');
      if (totalQuantity > 3) {
        _error = 'Maximum 3 books can be reserved at once.';
        print('❌ Error: $_error');
        notifyListeners();
        return false;
      }

      // Check user's current pending reservations FOR THIS LIBRARY
      print('📋 Checking user pending reservations for library: $libraryName ($libraryId)');
      final currentPendingCount = await _repo.getUserPendingReservationCountForLibrary(userId, libraryId);
      print('📋 Current pending count for this library: $currentPendingCount');
      if (currentPendingCount + totalQuantity > 3) {
        _error = 'You can only have maximum 3 books reserved per library. You currently have $currentPendingCount reserved from $libraryName.';
        print('❌ Error: $_error');
        notifyListeners();
        return false;
      }

      final now = DateTime.now();
      final reservation = Reservation(
        id: '',
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        libraryId: libraryId,
        libraryName: libraryName,
        items: items,
        reservationDate: now,
        expiryDate: now.add(const Duration(days: 3)), // 3 day validity
        status: ReservationStatus.pending,
        reservationFee: 10.0, // ₹10 reservation fee
        feeStatus: FeeStatus.pending,
      );

      print('📋 Calling repository createReservation...');
      await _repo.createReservation(reservation);
      print('✅ Repository createReservation completed successfully');
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      _error = e.toString();
      print('❌ ReservationProvider: createReservation failed');
      print('❌ Error: $_error');
      print('❌ Stack trace: $stackTrace');
      notifyListeners();
      return false;
    }
  }

  /// Get reservation by ID
  Future<Reservation?> getReservation(String reservationId) async {
    try {
      return await _repo.getReservation(reservationId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Convert reservation to borrow transaction (librarian action)
  Future<BorrowTransaction?> convertToBorrowTransaction(
    String reservationId,
    DateTime dueDate,
    String issuedBy,
  ) async {
    try {
      _error = null;
      final transaction = await _repo.convertToBorrowTransaction(
        reservationId,
        dueDate,
        issuedBy,
      );
      notifyListeners();
      return transaction;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Expire a reservation
  Future<bool> expireReservation(String reservationId) async {
    try {
      _error = null;
      await _repo.expireReservation(reservationId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Process expired reservations
  Future<void> processExpiredReservations() async {
    try {
      await _repo.processExpiredReservations();
    } catch (e) {
      debugPrint('Error processing expired reservations: $e');
    }
  }

  /// Legacy method for backward compatibility - fulfill reservation
  Future<bool> fulfillReservation(String reservationId) async {
    try {
      _error = null;
      // For backward compatibility, we'll just expire the reservation
      await _repo.expireReservation(reservationId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Force refresh user reservations
  void refreshUserReservations(String userId) {
    print('📋 ReservationProvider: Force refreshing user reservations for userId: $userId');
    listenToUserReservations(userId);
  }

  /// Force refresh pending reservations
  void refreshPendingReservations(String libraryId) {
    print('📋 ReservationProvider: Force refreshing pending reservations for libraryId: $libraryId');
    listenToPendingReservations(libraryId);
  }

  /// Get user's current pending reservation count
  Future<int> getUserPendingReservationCount(String userId) async {
    try {
      return await _repo.getUserPendingReservationCount(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return 0;
    }
  }

  /// Legacy method for backward compatibility - reserve single book
  Future<bool> reserveBook({
    required String bookId,
    required String bookTitle,
    String? bookThumbnail,
    required String userId,
    required String userName,
    required String libraryId,
    required String libraryName,
    int copies = 1,
  }) async {
    print('📋 ReservationProvider: Legacy reserveBook called for book: $bookTitle');
    
    final item = ReservationItem(
      bookId: bookId,
      bookTitle: bookTitle,
      bookThumbnail: bookThumbnail,
      quantity: copies,
    );

    // Try to get user email from auth provider or use fallback
    String userEmail = '$userName@library.com'; // Fallback
    
    return await createReservation(
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      libraryId: libraryId,
      libraryName: libraryName,
      items: [item],
    );
  }

  @override
  void dispose() {
    _reservationsSub?.cancel();
    super.dispose();
  }
}
