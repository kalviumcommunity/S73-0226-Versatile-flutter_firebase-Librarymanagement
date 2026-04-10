import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final DateTime createdAt;
  final bool hasSetPassword;
  final String? libraryName;
  final String? libraryId; // admin UID of the library this user belongs to
  final String? phone;
  final int? age;
  final String? profilePicUrl;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.hasSetPassword = false,
    this.libraryName,
    this.libraryId,
    this.phone,
    this.age,
    this.profilePicUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String uid) {
    return UserModel(
      uid: uid,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'reader',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hasSetPassword: json['hasSetPassword'] as bool? ?? false,
      libraryName: json['libraryName'] as String?,
      libraryId: json['libraryId'] as String?,
      phone: json['phone'] as String?,
      age: json['age'] as int?,
      profilePicUrl: json['profilePicUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'hasSetPassword': hasSetPassword,
      if (libraryName != null) 'libraryName': libraryName,
      if (libraryId != null) 'libraryId': libraryId,
      if (phone != null) 'phone': phone,
      if (age != null) 'age': age,
      if (profilePicUrl != null) 'profilePicUrl': profilePicUrl,
    };
  }

  bool get isReader => role == 'reader';
  bool get isLibrarian => role == 'librarian';
  bool get isAdmin => role == 'admin';

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
    DateTime? createdAt,
    bool? hasSetPassword,
    String? libraryName,
    String? libraryId,
    String? phone,
    int? age,
    String? profilePicUrl,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      hasSetPassword: hasSetPassword ?? this.hasSetPassword,
      libraryName: libraryName ?? this.libraryName,
      libraryId: libraryId ?? this.libraryId,
      phone: phone ?? this.phone,
      age: age ?? this.age,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
    );
  }

  @override
  String toString() =>
      'UserModel(uid: $uid, name: $name, email: $email, role: $role)';
}
