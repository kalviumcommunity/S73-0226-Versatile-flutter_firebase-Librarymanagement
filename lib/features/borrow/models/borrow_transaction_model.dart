import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionStatus { active, returned, overdue }

/// Represents a single book item in a borrow transaction
class BorrowItem {
  final String bookId;
  final String bookTitle;
  final String? bookThumbnail;
  final int quantity;

  const BorrowItem({
    required this.bookId,
    required this.bookTitle,
    this.bookThumbnail,
    required this.quantity,
  });

  factory BorrowItem.fromJson(Map<String, dynamic> json) {
    return BorrowItem(
      bookId: json['bookId'] as String? ?? '',
      bookTitle: json['bookTitle'] as String? ?? '',
      bookThumbnail: json['bookThumbnail'] as String?,
      quantity: json['quantity'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'bookTitle': bookTitle,
      if (bookThumbnail != null) 'bookThumbnail': bookThumbnail,
      'quantity': quantity,
    };
  }
}

/// Represents a borrow transaction containing multiple books
class BorrowTransaction {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String libraryId;
  final String libraryName;
  final String issuedBy; // librarian UID
  final List<BorrowItem> items;
  final DateTime issueDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final TransactionStatus status;
  final double fineAmount;
  static const double finePerDay = 2.0; // ₹2 per day overdue

  const BorrowTransaction({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.libraryId,
    required this.libraryName,
    required this.issuedBy,
    required this.items,
    required this.issueDate,
    required this.dueDate,
    this.returnDate,
    this.status = TransactionStatus.active,
    this.fineAmount = 0,
  });

  /// Calculate fine for overdue transaction
  double get calculatedFine {
    if (status == TransactionStatus.returned && returnDate != null) {
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
      status == TransactionStatus.active && DateTime.now().isAfter(dueDate);

  int get daysRemaining => dueDate.difference(DateTime.now()).inDays;

  int get totalBooks => items.fold(0, (sum, item) => sum + item.quantity);

  factory BorrowTransaction.fromJson(Map<String, dynamic> json, String id) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    return BorrowTransaction(
      id: id,
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userEmail: json['userEmail'] as String? ?? '',
      libraryId: json['libraryId'] as String? ?? '',
      libraryName: json['libraryName'] as String? ?? 'Unknown Library',
      issuedBy: json['issuedBy'] as String? ?? '',
      items: itemsList
          .map((item) => BorrowItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      issueDate:
          (json['issueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (json['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      returnDate: (json['returnDate'] as Timestamp?)?.toDate(),
      status: _statusFromString(json['status'] as String? ?? 'active'),
      fineAmount: (json['fineAmount'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'libraryId': libraryId,
      'libraryName': libraryName,
      'issuedBy': issuedBy,
      'items': items.map((item) => item.toJson()).toList(),
      'issueDate': Timestamp.fromDate(issueDate),
      'dueDate': Timestamp.fromDate(dueDate),
      if (returnDate != null) 'returnDate': Timestamp.fromDate(returnDate!),
      'status': status.name,
      'fineAmount': fineAmount,
    };
  }

  static TransactionStatus _statusFromString(String s) {
    switch (s) {
      case 'returned':
        return TransactionStatus.returned;
      case 'overdue':
        return TransactionStatus.overdue;
      default:
        return TransactionStatus.active;
    }
  }

  BorrowTransaction copyWith({
    String? id,
    DateTime? returnDate,
    TransactionStatus? status,
    double? fineAmount,
  }) {
    return BorrowTransaction(
      id: id ?? this.id,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      libraryId: libraryId,
      libraryName: libraryName,
      issuedBy: issuedBy,
      items: items,
      issueDate: issueDate,
      dueDate: dueDate,
      returnDate: returnDate ?? this.returnDate,
      status: status ?? this.status,
      fineAmount: fineAmount ?? this.fineAmount,
    );
  }
}
