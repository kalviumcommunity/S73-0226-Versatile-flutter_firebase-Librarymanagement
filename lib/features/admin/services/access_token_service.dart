import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/access_token_model.dart';

/// Handles Firestore CRUD for librarian access tokens.
class AccessTokenService {
  final FirebaseFirestore _firestore;
  static const String _collection = 'access_tokens';

  AccessTokenService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _tokensRef =>
      _firestore.collection(_collection);

  /// Generate and store a new access token (15 min validity).
  Future<AccessToken> generateToken(String adminUid) async {
    final code = AccessToken.generateCode();
    final now = DateTime.now();
    final token = AccessToken(
      token: code,
      createdByUid: adminUid,
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: 15)),
    );
    debugPrint('🔑 Generating token: $code for admin: $adminUid');
    await _tokensRef.doc(code).set(token.toJson());
    debugPrint('🔑 Token $code saved to Firestore');
    return token;
  }

  /// Validate a token: exists, not used, not expired.
  /// Returns the token if valid, null otherwise.
  Future<AccessToken?> validateToken(String code) async {
    final doc = await _tokensRef.doc(code.trim().toUpperCase()).get();
    if (!doc.exists || doc.data() == null) return null;
    final token = AccessToken.fromJson(doc.data()!, doc.id);
    if (!token.isValid) return null;
    return token;
  }

  /// Mark a token as used by a specific user UID.
  Future<void> markTokenUsed(String code, String usedByUid) async {
    await _tokensRef.doc(code.trim().toUpperCase()).update({
      'used': true,
      'usedByUid': usedByUid,
    });
  }
}
