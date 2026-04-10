import 'package:cloud_firestore/cloud_firestore.dart';

/// A membership plan configured by the admin (e.g., Daily, Monthly, Yearly).
class MembershipPlan {
  final String name;       // e.g. "Monthly Plan"
  final String duration;   // "daily", "monthly", "yearly"
  final int durationValue; // e.g. 1 (month), 7 (days), 1 (year)
  final double price;      // price in INR

  const MembershipPlan({
    required this.name,
    required this.duration,
    this.durationValue = 1,
    required this.price,
  });

  factory MembershipPlan.fromJson(Map<String, dynamic> json) {
    return MembershipPlan(
      name: json['name'] as String? ?? '',
      duration: json['duration'] as String? ?? 'monthly',
      durationValue: json['durationValue'] as int? ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'duration': duration,
      'durationValue': durationValue,
      'price': price,
    };
  }
}

/// Represents a library that readers can discover and join.
/// Created automatically when an admin signs up via "Create Library Account".
class LibraryModel {
  final String id; // Same as admin UID
  final String name;
  final String adminUid;
  final String adminName;
  final String? description;
  final String? coverImageUrl;
  final String? address;
  final int memberCount;
  final int bookCount;
  final bool isFree;
  final double membershipFee; // Legacy single fee (used as fallback)
  final List<MembershipPlan> plans; // Multiple plans for paid libraries
  final String? razorpayKeyId; // Admin's Razorpay key for collecting payments
  final DateTime createdAt;
  
  // Location fields for distance-based features
  final double? latitude;
  final double? longitude;
  final String? formattedAddress;
  
  // Runtime field for UI display (not stored in Firestore)
  double? distanceFromUser;

  LibraryModel({
    required this.id,
    required this.name,
    required this.adminUid,
    required this.adminName,
    this.description,
    this.coverImageUrl,
    this.address,
    this.memberCount = 0,
    this.bookCount = 0,
    this.isFree = true,
    this.membershipFee = 0,
    this.plans = const [],
    this.razorpayKeyId,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.formattedAddress,
    this.distanceFromUser,
  });

  factory LibraryModel.fromJson(Map<String, dynamic> json, String id) {
    final rawPlans = json['plans'] as List<dynamic>?;
    return LibraryModel(
      id: id,
      name: json['name'] as String? ?? '',
      adminUid: json['adminUid'] as String? ?? '',
      adminName: json['adminName'] as String? ?? '',
      description: json['description'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      address: json['address'] as String?,
      memberCount: json['memberCount'] as int? ?? 0,
      bookCount: json['bookCount'] as int? ?? 0,
      isFree: json['isFree'] as bool? ?? true,
      membershipFee: (json['membershipFee'] as num?)?.toDouble() ?? 0,
      plans: rawPlans != null
          ? rawPlans
              .map((e) => MembershipPlan.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : [],
      razorpayKeyId: json['razorpayKeyId'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      formattedAddress: json['formattedAddress'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'adminUid': adminUid,
      'adminName': adminName,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'address': address,
      'memberCount': memberCount,
      'bookCount': bookCount,
      'isFree': isFree,
      'membershipFee': membershipFee,
      'plans': plans.map((p) => p.toJson()).toList(),
      if (razorpayKeyId != null) 'razorpayKeyId': razorpayKeyId,
      'createdAt': Timestamp.fromDate(createdAt),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (formattedAddress != null) 'formattedAddress': formattedAddress,
    };
  }

  LibraryModel copyWith({
    String? id,
    String? name,
    String? adminUid,
    String? adminName,
    String? description,
    String? coverImageUrl,
    String? address,
    int? memberCount,
    int? bookCount,
    bool? isFree,
    double? membershipFee,
    List<MembershipPlan>? plans,
    String? razorpayKeyId,
    DateTime? createdAt,
    double? latitude,
    double? longitude,
    String? formattedAddress,
    double? distanceFromUser,
  }) {
    return LibraryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      adminUid: adminUid ?? this.adminUid,
      adminName: adminName ?? this.adminName,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      address: address ?? this.address,
      memberCount: memberCount ?? this.memberCount,
      bookCount: bookCount ?? this.bookCount,
      isFree: isFree ?? this.isFree,
      membershipFee: membershipFee ?? this.membershipFee,
      plans: plans ?? this.plans,
      razorpayKeyId: razorpayKeyId ?? this.razorpayKeyId,
      createdAt: createdAt ?? this.createdAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      distanceFromUser: distanceFromUser ?? this.distanceFromUser,
    );
  }
}

/// Tracks a reader's membership in a library.
class LibraryMembership {
  final String id;
  final String libraryId;
  final String libraryName;
  final String userId;
  final String userName;
  final DateTime joinedAt;
  final double? amountPaid; // null for free memberships
  final String? paymentId; // Razorpay payment ID
  final String? planName;  // Name of the selected plan

  const LibraryMembership({
    required this.id,
    required this.libraryId,
    required this.libraryName,
    required this.userId,
    required this.userName,
    required this.joinedAt,
    this.amountPaid,
    this.paymentId,
    this.planName,
  });

  factory LibraryMembership.fromJson(Map<String, dynamic> json, String id) {
    return LibraryMembership(
      id: id,
      libraryId: json['libraryId'] as String? ?? '',
      libraryName: json['libraryName'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      joinedAt: (json['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      amountPaid: (json['amountPaid'] as num?)?.toDouble(),
      paymentId: json['paymentId'] as String?,
      planName: json['planName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'libraryId': libraryId,
      'libraryName': libraryName,
      'userId': userId,
      'userName': userName,
      'joinedAt': Timestamp.fromDate(joinedAt),
      if (amountPaid != null) 'amountPaid': amountPaid,
      if (paymentId != null) 'paymentId': paymentId,
      if (planName != null) 'planName': planName,
    };
  }
}
