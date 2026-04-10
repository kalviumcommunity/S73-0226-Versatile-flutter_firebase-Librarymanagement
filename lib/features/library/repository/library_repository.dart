import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/library_model.dart';

/// Firestore repository for libraries and memberships.
class LibraryRepository {
  final FirebaseFirestore _firestore;

  LibraryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _librariesRef =>
      _firestore.collection('libraries');

  CollectionReference<Map<String, dynamic>> get _membershipsRef =>
      _firestore.collection('library_members');

  // ── Library CRUD ──

  /// Create a library document (called when admin signs up).
  Future<void> createLibrary(LibraryModel library) async {
    await _librariesRef.doc(library.id).set(library.toJson());
  }

  /// Get a single library by ID.
  Future<LibraryModel?> getLibrary(String id) async {
    final doc = await _librariesRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return LibraryModel.fromJson(doc.data()!, doc.id);
  }

  /// Stream all libraries (for discovery).
  Stream<List<LibraryModel>> librariesStream() {
    return _librariesRef
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => LibraryModel.fromJson(doc.data(), doc.id))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  /// Get all libraries (one-shot).
  Future<List<LibraryModel>> getAllLibraries() async {
    final snap = await _librariesRef.get();
    final list = snap.docs
        .map((doc) => LibraryModel.fromJson(doc.data(), doc.id))
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Update library fields (creates doc if it doesn't exist).
  Future<void> updateLibrary(String id, Map<String, dynamic> data) async {
    await _librariesRef.doc(id).set(data, SetOptions(merge: true));
  }

  /// Increment member count.
  Future<void> incrementMemberCount(String libraryId, int delta) async {
    await _librariesRef.doc(libraryId).update({
      'memberCount': FieldValue.increment(delta),
    });
  }

  /// Increment book count.
  Future<void> incrementBookCount(String libraryId, int delta) async {
    await _librariesRef.doc(libraryId).update({
      'bookCount': FieldValue.increment(delta),
    });
  }

  // ── Membership CRUD ──

  /// Join a library.
  Future<LibraryMembership> joinLibrary({
    required String libraryId,
    required String libraryName,
    required String userId,
    required String userName,
    double? amountPaid,
    String? paymentId,
    String? planName,
  }) async {
    // Check if already a member
    final existing = await _membershipsRef
        .where('libraryId', isEqualTo: libraryId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return LibraryMembership.fromJson(
          existing.docs.first.data(), existing.docs.first.id);
    }

    final membership = LibraryMembership(
      id: '',
      libraryId: libraryId,
      libraryName: libraryName,
      userId: userId,
      userName: userName,
      joinedAt: DateTime.now(),
      amountPaid: amountPaid,
      paymentId: paymentId,
      planName: planName,
    );

    final docRef = await _membershipsRef.add(membership.toJson());
    await incrementMemberCount(libraryId, 1);

    return LibraryMembership(
      id: docRef.id,
      libraryId: libraryId,
      libraryName: libraryName,
      userId: userId,
      userName: userName,
      joinedAt: membership.joinedAt,
      amountPaid: amountPaid,
      paymentId: paymentId,
      planName: planName,
    );
  }

  /// Leave a library.
  Future<void> leaveLibrary(String libraryId, String userId) async {
    final snap = await _membershipsRef
        .where('libraryId', isEqualTo: libraryId)
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in snap.docs) {
      await doc.reference.delete();
    }

    if (snap.docs.isNotEmpty) {
      await incrementMemberCount(libraryId, -1);
    }
  }

  /// Check if user is a member of a library.
  Future<bool> isMember(String libraryId, String userId) async {
    final snap = await _membershipsRef
        .where('libraryId', isEqualTo: libraryId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Get all libraries a user has joined.
  Stream<List<LibraryMembership>> userMembershipsStream(String userId) {
    return _membershipsRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => LibraryMembership.fromJson(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.joinedAt.compareTo(a.joinedAt));
      return list;
    });
  }

  /// Get all members of a library.
  Stream<List<LibraryMembership>> libraryMembersStream(String libraryId) {
    return _membershipsRef
        .where('libraryId', isEqualTo: libraryId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => LibraryMembership.fromJson(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.joinedAt.compareTo(a.joinedAt));
      return list;
    });
  }

  /// Get the library that an admin owns.
  Future<LibraryModel?> getLibraryByAdmin(String adminUid) async {
    // Try direct doc lookup first (library ID == admin UID)
    final doc = await _librariesRef.doc(adminUid).get();
    if (doc.exists && doc.data() != null) {
      return LibraryModel.fromJson(doc.data()!, doc.id);
    }
    // Fallback: query by adminUid field
    final snap = await _librariesRef
        .where('adminUid', isEqualTo: adminUid)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return LibraryModel.fromJson(snap.docs.first.data(), snap.docs.first.id);
  }

  /// Ensure a library document exists for an admin. Creates if missing.
  Future<LibraryModel> ensureLibraryExists({
    required String adminUid,
    required String adminName,
    required String libraryName,
  }) async {
    final existing = await getLibraryByAdmin(adminUid);
    if (existing != null) return existing;

    final library = LibraryModel(
      id: adminUid,
      name: libraryName,
      adminUid: adminUid,
      adminName: adminName,
      createdAt: DateTime.now(),
    );
    await createLibrary(library);
    return library;
  }
}
