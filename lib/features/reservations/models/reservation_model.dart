import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a reservation
enum ReservationStatus {
  pending,
  collected,
  expired;

  String get displayName {
    switch (this) {
      case ReservationStatus.pending:
        return 'Pending';
      case ReservationStatus.collected:
        return 'Collected';
      case ReservationStatus.expired:
        return 'Expired';
    }
  }
}

/// Fee status for reservation
enum FeeStatus {
  pending,
  paid,
  refunded,
  forfeited;

  String get displayName {
    switch (this) {
      case FeeStatus.pending:
        return 'Pending';
      case FeeStatus.paid:
        return 'Paid';
      case FeeStatus.refunded:
        return 'Refunded';
      case FeeStatus.forfeited:
        return 'Forfeited';
    }
  }
}

/// Item in a reservation
class ReservationItem {
  final String bookId;
  final String bookTitle;
  final String? bookThumbnail;
  final int quantity;

  ReservationItem({
    required this.bookId,
    required this.bookTitle,
    this.bookThumbnail,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'bookTitle': bookTitle,
      'bookThumbnail': bookThumbnail,
      'quantity': quantity,
    };
  }

  factory ReservationItem.fromJson(Map<String, dynamic> json) {
    return ReservationItem(
      bookId: json['bookId'] as String? ?? '',
      bookTitle: json['bookTitle'] as String? ?? '',
      bookThumbnail: json['bookThumbnail'] as String?,
      quantity: json['quantity'] as int? ?? 1,
    );
  }
}

/// Reservation model
class Reservation {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String libraryId;
  final String libraryName;
  final List<ReservationItem> items;
  final DateTime reservationDate;
  final DateTime expiryDate;
  final ReservationStatus status;
  final DateTime? collectedDate;
  final double reservationFee;
  final FeeStatus feeStatus;
  final DateTime? feeCollectedDate;
  final DateTime? feeRefundedDate;

  Reservation({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.libraryId,
    required this.libraryName,
    required this.items,
    required this.reservationDate,
    required this.expiryDate,
    required this.status,
    this.collectedDate,
    this.reservationFee = 10.0,
    this.feeStatus = FeeStatus.pending,
    this.feeCollectedDate,
    this.feeRefundedDate,
  });

  /// Total number of books reserved
  int get totalBooks => items.fold(0, (sum, item) => sum + item.quantity);

  /// Check if reservation is expired
  bool get isExpired => DateTime.now().isAfter(expiryDate) && status == ReservationStatus.pending;

  /// Days remaining until expiry
  int get daysRemaining {
    if (status != ReservationStatus.pending) return 0;
    final diff = expiryDate.difference(DateTime.now());
    return diff.inDays < 0 ? 0 : diff.inDays;
  }

  /// Hours remaining until expiry
  int get hoursRemaining {
    if (status != ReservationStatus.pending) return 0;
    final diff = expiryDate.difference(DateTime.now());
    return diff.inHours < 0 ? 0 : diff.inHours;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'libraryId': libraryId,
      'libraryName': libraryName,
      'items': items.map((item) => item.toJson()).toList(),
      'reservationDate': Timestamp.fromDate(reservationDate),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'status': status.name,
      'reservationFee': reservationFee,
      'feeStatus': feeStatus.name,
      if (collectedDate != null) 'collectedDate': Timestamp.fromDate(collectedDate!),
      if (feeCollectedDate != null) 'feeCollectedDate': Timestamp.fromDate(feeCollectedDate!),
      if (feeRefundedDate != null) 'feeRefundedDate': Timestamp.fromDate(feeRefundedDate!),
    };
  }

  factory Reservation.fromJson(Map<String, dynamic> json, String id) {
    return Reservation(
      id: id,
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userEmail: json['userEmail'] as String? ?? '',
      libraryId: json['libraryId'] as String? ?? '',
      libraryName: json['libraryName'] as String? ?? 'Unknown Library',
      items: (json['items'] as List? ?? [])
          .map((item) => ReservationItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      reservationDate: (json['reservationDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiryDate: (json['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 3)),
      status: ReservationStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String? ?? 'pending'),
        orElse: () => ReservationStatus.pending,
      ),
      reservationFee: (json['reservationFee'] as num?)?.toDouble() ?? 10.0,
      feeStatus: FeeStatus.values.firstWhere(
        (s) => s.name == (json['feeStatus'] as String? ?? 'pending'),
        orElse: () => FeeStatus.pending,
      ),
      collectedDate: json['collectedDate'] != null
          ? (json['collectedDate'] as Timestamp).toDate()
          : null,
      feeCollectedDate: json['feeCollectedDate'] != null
          ? (json['feeCollectedDate'] as Timestamp).toDate()
          : null,
      feeRefundedDate: json['feeRefundedDate'] != null
          ? (json['feeRefundedDate'] as Timestamp).toDate()
          : null,
    );
  }

  Reservation copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? libraryId,
    String? libraryName,
    List<ReservationItem>? items,
    DateTime? reservationDate,
    DateTime? expiryDate,
    ReservationStatus? status,
    DateTime? collectedDate,
    double? reservationFee,
    FeeStatus? feeStatus,
    DateTime? feeCollectedDate,
    DateTime? feeRefundedDate,
  }) {
    return Reservation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      libraryId: libraryId ?? this.libraryId,
      libraryName: libraryName ?? this.libraryName,
      items: items ?? this.items,
      reservationDate: reservationDate ?? this.reservationDate,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      collectedDate: collectedDate ?? this.collectedDate,
      reservationFee: reservationFee ?? this.reservationFee,
      feeStatus: feeStatus ?? this.feeStatus,
      feeCollectedDate: feeCollectedDate ?? this.feeCollectedDate,
      feeRefundedDate: feeRefundedDate ?? this.feeRefundedDate,
    );
  }
}
