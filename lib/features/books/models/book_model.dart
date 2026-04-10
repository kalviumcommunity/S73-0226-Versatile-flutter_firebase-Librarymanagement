import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a book in the library stock.
/// Populated from Google Books API + local stock data.
class BookModel {
  final String id; // Firestore doc id (Google Books volumeId)
  final String title;
  final List<String> authors;
  final String? description;
  final String? thumbnail; // Cover image URL
  final String? isbn;
  final String? publisher;
  final String? publishedDate;
  final int pageCount;
  final List<String> categories;
  final int totalCopies; // Total stock added by admin/librarian
  final int borrowedStock; // Currently borrowed
  final int reservedStock; // Currently reserved
  final DateTime addedAt;
  final String addedBy; // UID of admin/librarian who added
  final String? libraryId; // ID of the library this book belongs to

  BookModel({
    required this.id,
    required this.title,
    required this.authors,
    this.description,
    this.thumbnail,
    this.isbn,
    this.publisher,
    this.publishedDate,
    this.pageCount = 0,
    this.categories = const [],
    this.totalCopies = 1,
    this.borrowedStock = 0,
    this.reservedStock = 0,
    required this.addedAt,
    required this.addedBy,
    this.libraryId,
  });

  /// Calculate available stock: total - borrowed - reserved
  int get availableCopies => totalCopies - borrowedStock - reservedStock;

  BookModel copyWith({
    String? id,
    String? title,
    List<String>? authors,
    String? description,
    String? thumbnail,
    String? isbn,
    String? publisher,
    String? publishedDate,
    int? pageCount,
    List<String>? categories,
    int? totalCopies,
    int? borrowedStock,
    int? reservedStock,
    DateTime? addedAt,
    String? addedBy,
    String? libraryId,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      description: description ?? this.description,
      thumbnail: thumbnail ?? this.thumbnail,
      isbn: isbn ?? this.isbn,
      publisher: publisher ?? this.publisher,
      publishedDate: publishedDate ?? this.publishedDate,
      pageCount: pageCount ?? this.pageCount,
      categories: categories ?? this.categories,
      totalCopies: totalCopies ?? this.totalCopies,
      borrowedStock: borrowedStock ?? this.borrowedStock,
      reservedStock: reservedStock ?? this.reservedStock,
      addedAt: addedAt ?? this.addedAt,
      addedBy: addedBy ?? this.addedBy,
      libraryId: libraryId ?? this.libraryId,
    );
  }

  /// Create from Firestore document.
  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      authors: List<String>.from(json['authors'] ?? []),
      description: json['description'] as String?,
      thumbnail: json['thumbnail'] as String?,
      isbn: json['isbn'] as String?,
      publisher: json['publisher'] as String?,
      publishedDate: json['publishedDate'] as String?,
      pageCount: json['pageCount'] as int? ?? 0,
      categories: List<String>.from(json['categories'] ?? []),
      totalCopies: json['totalCopies'] as int? ?? 1,
      borrowedStock: json['borrowedStock'] as int? ?? 0,
      reservedStock: json['reservedStock'] as int? ?? 0,
      addedAt: (json['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      addedBy: json['addedBy'] as String? ?? '',
      libraryId: json['libraryId'] as String?,
    );
  }

  /// Serialize for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'authors': authors,
      'description': description,
      'thumbnail': thumbnail,
      'isbn': isbn,
      'publisher': publisher,
      'publishedDate': publishedDate,
      'pageCount': pageCount,
      'categories': categories,
      'totalCopies': totalCopies,
      'borrowedStock': borrowedStock,
      'reservedStock': reservedStock,
      'addedAt': Timestamp.fromDate(addedAt),
      'addedBy': addedBy,
      'libraryId': libraryId,
    };
  }

  /// Create from Google Books API volume JSON.
  factory BookModel.fromGoogleBooks(Map<String, dynamic> volumeJson,
      {required String addedBy, int copies = 1, String? libraryId}) {
    final info = volumeJson['volumeInfo'] as Map<String, dynamic>? ?? {};
    final imageLinks = info['imageLinks'] as Map<String, dynamic>?;

    // Try to get ISBN-13, fallback to ISBN-10
    String? isbn;
    final identifiers = info['industryIdentifiers'] as List?;
    if (identifiers != null) {
      for (final id in identifiers) {
        if (id['type'] == 'ISBN_13') {
          isbn = id['identifier'] as String?;
          break;
        }
      }
      isbn ??= identifiers.isNotEmpty
          ? identifiers.first['identifier'] as String?
          : null;
    }

    // Use HTTPS thumbnail
    String? thumb = imageLinks?['thumbnail'] as String? ??
        imageLinks?['smallThumbnail'] as String?;
    if (thumb != null && thumb.startsWith('http:')) {
      thumb = thumb.replaceFirst('http:', 'https:');
    }

    // Use composite ID (libraryId_volumeId) so each library has its own copy
    final volumeId = volumeJson['id'] as String? ?? '';
    final compositeId = (libraryId != null && libraryId.isNotEmpty)
        ? '${libraryId}_$volumeId'
        : volumeId;

    return BookModel(
      id: compositeId,
      title: info['title'] as String? ?? 'Untitled',
      authors: List<String>.from(info['authors'] ?? ['Unknown']),
      description: info['description'] as String?,
      thumbnail: thumb,
      isbn: isbn,
      publisher: info['publisher'] as String?,
      publishedDate: info['publishedDate'] as String?,
      pageCount: info['pageCount'] as int? ?? 0,
      categories: List<String>.from(info['categories'] ?? []),
      totalCopies: copies,
      borrowedStock: 0,
      reservedStock: 0,
      addedAt: DateTime.now(),
      addedBy: addedBy,
      libraryId: libraryId,
    );
  }

  String get authorsFormatted => authors.join(', ');
}
