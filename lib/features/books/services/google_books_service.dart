import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service to search the Open Library API (free, no API key needed, no rate limits).
class GoogleBooksService {
  static const _baseUrl = 'https://openlibrary.org/search.json';

  /// Search for books by query string using Open Library API.
  /// Returns normalized data in Google Books-like format for compatibility.
  Future<List<Map<String, dynamic>>> searchBooks(String query,
      {int maxResults = 20}) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'q': query.trim(),
        'limit': maxResults.toString(),
        'fields': 'key,title,author_name,first_publish_year,publisher,number_of_pages_median,isbn,cover_i,subject',
      });

      debugPrint('📚 Open Library search: $uri');

      final response = await http.get(uri);

      debugPrint('📚 Response status: ${response.statusCode}');
      debugPrint('📚 Response body length: ${response.body.length}');

      if (response.statusCode != 200) {
        debugPrint('📚 Search failed: ${response.statusCode}');
        debugPrint('📚 Response body: ${response.body}');
        throw Exception('Open Library API error: ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final numFound = json['numFound'] as int? ?? 0;
      debugPrint('📚 Total items found: $numFound');
      
      if (numFound == 0) return [];

      final docs = json['docs'] as List<dynamic>? ?? [];
      debugPrint('📚 Returning ${docs.length} items');
      
      // Convert Open Library format to Google Books-like format
      return docs.map((doc) => _convertToGoogleBooksFormat(doc as Map<String, dynamic>)).toList();
    } catch (e, stackTrace) {
      debugPrint('📚 ERROR in searchBooks: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Convert Open Library document to Google Books-like format.
  Map<String, dynamic> _convertToGoogleBooksFormat(Map<String, dynamic> doc) {
    final key = doc['key'] as String? ?? '';
    final title = doc['title'] as String? ?? 'Untitled';
    final authors = (doc['author_name'] as List?)?.cast<String>() ?? [];
    final publishYear = doc['first_publish_year']?.toString();
    final publishers = (doc['publisher'] as List?)?.cast<String>() ?? [];
    final pageCount = doc['number_of_pages_median'] as int?;
    final isbns = (doc['isbn'] as List?)?.cast<String>() ?? [];
    final coverId = doc['cover_i'] as int?;
    final subjects = (doc['subject'] as List?)?.take(5).cast<String>().toList() ?? [];

    return {
      'kind': 'books#volume',
      'id': key.replaceAll('/', '_'),
      'volumeInfo': {
        'title': title,
        'authors': authors.isNotEmpty ? authors : null,
        'publisher': publishers.isNotEmpty ? publishers.first : null,
        'publishedDate': publishYear,
        'description': subjects.isNotEmpty ? 'Subjects: ${subjects.join(', ')}' : null,
        'pageCount': pageCount,
        'categories': subjects.isNotEmpty ? subjects : null,
        'imageLinks': coverId != null
            ? {
                'thumbnail': 'https://covers.openlibrary.org/b/id/$coverId-M.jpg',
                'smallThumbnail': 'https://covers.openlibrary.org/b/id/$coverId-S.jpg',
              }
            : null,
        'industryIdentifiers': isbns.isNotEmpty
            ? isbns.map((isbn) => {
                  'type': isbn.length == 13 ? 'ISBN_13' : 'ISBN_10',
                  'identifier': isbn,
                }).toList()
            : null,
      },
    };
  }

  /// Search specifically by ISBN.
  Future<List<Map<String, dynamic>>> searchByIsbn(String isbn) {
    return searchBooks('isbn:$isbn', maxResults: 5);
  }

  /// Get a single volume by its Open Library key.
  Future<Map<String, dynamic>?> getVolumeById(String volumeId) async {
    final key = volumeId.replaceAll('_', '/');
    final uri = Uri.parse('https://openlibrary.org$key.json');
    final response = await http.get(uri);

    if (response.statusCode != 200) return null;
    final doc = jsonDecode(response.body) as Map<String, dynamic>;
    return _convertToGoogleBooksFormat(doc);
  }
}
