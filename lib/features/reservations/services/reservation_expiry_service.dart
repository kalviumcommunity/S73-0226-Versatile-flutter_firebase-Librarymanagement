import 'dart:async';
import 'package:flutter/foundation.dart';
import '../repository/reservation_repository.dart';

/// Service to handle automatic reservation expiry
class ReservationExpiryService {
  static final ReservationExpiryService _instance = ReservationExpiryService._internal();
  factory ReservationExpiryService() => _instance;
  ReservationExpiryService._internal();

  final ReservationRepository _repository = ReservationRepository();
  Timer? _expiryTimer;
  bool _isRunning = false;

  /// Start the expiry service
  void start() {
    if (_isRunning) return;
    
    _isRunning = true;
    debugPrint('🔄 Starting reservation expiry service');
    
    // Run immediately
    _processExpiredReservations();
    
    // Then run every hour
    _expiryTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _processExpiredReservations();
    });
  }

  /// Stop the expiry service
  void stop() {
    if (!_isRunning) return;
    
    _isRunning = false;
    _expiryTimer?.cancel();
    _expiryTimer = null;
    debugPrint('⏹️ Stopped reservation expiry service');
  }

  /// Process expired reservations
  Future<void> _processExpiredReservations() async {
    try {
      debugPrint('🔄 Processing expired reservations...');
      await _repository.processExpiredReservations();
      debugPrint('✅ Expired reservations processed successfully');
    } catch (e) {
      debugPrint('❌ Error processing expired reservations: $e');
    }
  }

  /// Manually trigger expiry processing
  Future<void> processNow() async {
    await _processExpiredReservations();
  }

  bool get isRunning => _isRunning;
}