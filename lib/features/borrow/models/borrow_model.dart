import 'package:cloud_firestore/cloud_firestore.dart';

enum BorrowStatus { active, returned, overdue }

/// Represents a book borrow record.
class BorrowModel {
  final String id;
  final String bookId;
  final String bookTitle;
  final String? bookThumbnail;
  final String userId;
  final String userName;
  final String libraryId;
  final String issuedBy; // librarian UID
  final DateTime borrowDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final BorrowStatus status;
  final double fineAmount;
  static const double finePerDay = 2.0; // ₹2 per day overdue

  const BorrowModel({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    this.bookThumbnail,
    required this.userId,
    required this.userName,
    required this.libraryId,
    required this.issuedBy,
    required this.borrowDate,
    required this.dueDate,
    this.returnDate,
    this.status = BorrowStatus.active,
    this.fineAmount = 0,
  });

  /// Calculate fine for overdue books.
  double get calculatedFine {
    if (status == BorrowStatus.returned && returnDate != null) {
      final overdueDays = returnDate!.difference(dueDate).inDays;
      return overdueDays > 0 ? overdueDays * finePerDay : 0;
    }
    if (DateTime.now().isAfter(dueDate)) {
      final overdueDays = DateTime.now().difference(dueDate).inDays;
      return overdueDays > 0 ? overdueDays * finePerDay : 0;
    }
    return 0;
  }

  bool get isOverdue =>
      status == BorrowStatus.active && DateTime.now().isAfter(dueDate);

  int get daysRemaining => dueDate.difference(DateTime.now()).inDays;

  factory BorrowModel.fromJson(Map<String, dynamic> json, String id) {
    return BorrowModel(
      id: id,
      bookId: json['bookId'] as String? ?? '',
      bookTitle: json['bookTitle'] as String? ?? '',
      bookThumbnail: json['bookThumbnail'] as String?,
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      libraryId: json['libraryId'] as String? ?? '',
      issuedBy: json['issuedBy'] as String? ?? '',
      borrowDate:
          (json['borrowDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (json['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      returnDate: (json['returnDate'] as Timestamp?)?.toDate(),
      status: _statusFromString(json['status'] as String? ?? 'active'),
      fineAmount: (json['fineAmount'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'bookTitle': bookTitle,
      'bookThumbnail': bookThumbnail,
      'userId': userId,
      'userName': userName,
      'libraryId': libraryId,
      'issuedBy': issuedBy,
      'borrowDate': Timestamp.fromDate(borrowDate),
      'dueDate': Timestamp.fromDate(dueDate),
      if (returnDate != null) 'returnDate': Timestamp.fromDate(returnDate!),
      'status': status.name,
      'fineAmount': fineAmount,
    };
  }

  static BorrowStatus _statusFromString(String s) {
    switch (s) {
      case 'returned':
        return BorrowStatus.returned;
      case 'overdue':
        return BorrowStatus.overdue;
      default:
        return BorrowStatus.active;
    }
  }

  BorrowModel copyWith({
    String? id,
    DateTime? returnDate,
    BorrowStatus? status,
    double? fineAmount,
  }) {
    return BorrowModel(
      id: id ?? this.id,
      bookId: bookId,
      bookTitle: bookTitle,
      bookThumbnail: bookThumbnail,
      userId: userId,
      userName: userName,
      libraryId: libraryId,
      issuedBy: issuedBy,
      borrowDate: borrowDate,
      dueDate: dueDate,
      returnDate: returnDate ?? this.returnDate,
      status: status ?? this.status,
      fineAmount: fineAmount ?? this.fineAmount,
    );
  }
}
