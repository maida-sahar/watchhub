import 'package:cloud_firestore/cloud_firestore.dart';

/// Roles supported by WatchHub. Only two roles exist by design.
class UserRole {
  UserRole._();
  static const String customer = 'customer';
  static const String admin = 'admin';
}

/// Firestore document model for `users/{uid}`.
///
/// This model is intentionally immutable. Use [copyWith] to derive updated
/// instances instead of mutating fields directly.
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;
  final String role;
  final bool isActive;
  final bool isBlocked;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.photoUrl,
    required this.role,
    required this.isActive,
    this.isBlocked = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Builds a brand-new customer profile at signup time.
  /// [role] always defaults to [UserRole.customer] — role is never
  /// accepted as client input.
  factory UserModel.newCustomer({
    required String uid,
    required String name,
    required String email,
    required String phone,
    String photoUrl = '',
  }) {
    final now = DateTime.now();
    return UserModel(
      uid: uid,
      name: name,
      email: email,
      phone: phone,
      photoUrl: photoUrl,
      role: UserRole.customer,
      isActive: true,
      isBlocked: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Deserializes a Firestore document snapshot's data map.
  /// [uid] is passed separately since it's the document ID, not a field
  /// that's guaranteed to already exist inside the map for legacy docs.
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: (map['name'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      photoUrl: (map['photoUrl'] as String?) ?? '',
      role: (map['role'] as String?) ?? UserRole.customer,
      isActive: (map['isActive'] as bool?) ?? true,
      isBlocked: (map['isBlocked'] as bool?) ?? false,
      createdAt: _timestampToDate(map['createdAt']),
      updatedAt: _timestampToDate(map['updatedAt']),
    );
  }

  static DateTime _timestampToDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  /// Serializes this model for writing to Firestore.
  /// `uid` is included as a field too (in addition to being the doc ID)
  /// per the requested schema, which simplifies collection-group queries.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'role': role,
      'isActive': isActive,
      'isBlocked': isBlocked,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? role,
    bool? isActive,
    bool? isBlocked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isBlocked: isBlocked ?? this.isBlocked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isCustomer => role == UserRole.customer;

  @override
  String toString() => 'UserModel(uid: $uid, email: $email, role: $role, isActive: $isActive, isBlocked: $isBlocked)';

  @override
  bool operator ==(Object other) => other is UserModel && other.uid == uid;

  @override
  int get hashCode => uid.hashCode;

  Map<String, dynamic> toMapForJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'role': role,
      'isActive': isActive,
      'isBlocked': isBlocked,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}