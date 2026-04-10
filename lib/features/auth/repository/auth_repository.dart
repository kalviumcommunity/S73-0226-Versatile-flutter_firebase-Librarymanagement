import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Handles Firestore operations for the users collection.
class AuthRepository {
  final FirebaseFirestore _firestore;
  static const String _collection = 'users';

  AuthRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(_collection);

  /// Create a new user document in Firestore.
  Future<void> createUser(UserModel user) async {
    await _usersRef.doc(user.uid).set(user.toJson());
  }

  /// Fetch a user by UID. Returns null if not found.
  /// Uses cache-first strategy to avoid slow first network call.
  Future<UserModel?> getUser(String uid) async {
    try {
      // Try cache first for instant response
      final cachedDoc = await _usersRef.doc(uid).get(
        const GetOptions(source: Source.cache),
      );
      if (cachedDoc.exists && cachedDoc.data() != null) {
        // Return cached data immediately, refresh in background
        _usersRef.doc(uid).get(const GetOptions(source: Source.server));
        return UserModel.fromJson(cachedDoc.data()!, uid);
      }
    } catch (_) {
      // Cache miss — fall through to server
    }

    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromJson(doc.data()!, uid);
  }

  /// Update user role.
  Future<void> updateUserRole(String uid, String newRole) async {
    await _usersRef.doc(uid).update({'role': newRole});
  }

  /// Get all users (for admin).
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _usersRef.get();
    return snapshot.docs
        .map((doc) => UserModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  /// Delete a user document.
  Future<void> deleteUser(String uid) async {
    await _usersRef.doc(uid).delete();
  }

  /// Stream a single user document.
  Stream<UserModel?> streamUser(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromJson(doc.data()!, uid);
    });
  }

  /// Find a user by email. Returns null if not found.
  Future<UserModel?> getUserByEmail(String email) async {
    final snapshot = await _usersRef
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return UserModel.fromJson(doc.data(), doc.id);
  }

  /// Update hasSetPassword flag.
  Future<void> updateHasSetPassword(String uid, bool value) async {
    await _usersRef.doc(uid).update({'hasSetPassword': value});
  }

  /// Update user profile fields (name, phone, age, profilePicUrl).
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _usersRef.doc(uid).update(data);
  }
}
