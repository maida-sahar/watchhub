import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // 'order', 'product', 'wishlist', 'promotion', 'review', 'system'
  final String recipientType; // 'all', 'role', 'users'
  final String? recipientRole; // 'customer', 'admin'
  final List<String> recipientIds; // specific user IDs if recipientType == 'users'
  final List<String> readBy; // user UIDs who marked it as read
  final List<String> deletedBy; // user UIDs who deleted it locally
  final DateTime? scheduledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.recipientType,
    this.recipientRole,
    required this.recipientIds,
    required this.readBy,
    required this.deletedBy,
    this.scheduledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    return NotificationModel(
      id: docId,
      title: (map['title'] as String?) ?? '',
      body: (map['body'] as String?) ?? '',
      type: (map['type'] as String?) ?? 'system',
      recipientType: (map['recipientType'] as String?) ?? 'all',
      recipientRole: map['recipientRole'] as String?,
      recipientIds: List<String>.from(map['recipientIds'] ?? []),
      readBy: List<String>.from(map['readBy'] ?? []),
      deletedBy: List<String>.from(map['deletedBy'] ?? []),
      scheduledAt: map['scheduledAt'] != null ? _timestampToDate(map['scheduledAt']) : null,
      createdAt: _timestampToDate(map['createdAt']),
      updatedAt: _timestampToDate(map['updatedAt']),
    );
  }

  static DateTime _timestampToDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'recipientType': recipientType,
      'recipientRole': recipientRole,
      'recipientIds': recipientIds,
      'readBy': readBy,
      'deletedBy': deletedBy,
      'scheduledAt': scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool isReadBy(String uid) => readBy.contains(uid);
  bool isDeletedBy(String uid) => deletedBy.contains(uid);

  NotificationModel copyWith({
    String? title,
    String? body,
    String? type,
    String? recipientType,
    String? recipientRole,
    List<String>? recipientIds,
    List<String>? readBy,
    List<String>? deletedBy,
    DateTime? scheduledAt,
    DateTime? updatedAt,
  }) {
    return NotificationModel(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      recipientType: recipientType ?? this.recipientType,
      recipientRole: recipientRole ?? this.recipientRole,
      recipientIds: recipientIds ?? this.recipientIds,
      readBy: readBy ?? this.readBy,
      deletedBy: deletedBy ?? this.deletedBy,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

class NotificationSettingsModel {
  final bool pushEnabled;
  final bool orderEnabled;
  final bool promotionEnabled;
  final bool wishlistEnabled;
  final bool reviewEnabled;
  final bool systemEnabled;

  const NotificationSettingsModel({
    this.pushEnabled = true,
    this.orderEnabled = true,
    this.promotionEnabled = true,
    this.wishlistEnabled = true,
    this.reviewEnabled = true,
    this.systemEnabled = true,
  });

  factory NotificationSettingsModel.fromMap(Map<String, dynamic> map) {
    return NotificationSettingsModel(
      pushEnabled: map['pushEnabled'] ?? true,
      orderEnabled: map['orderEnabled'] ?? true,
      promotionEnabled: map['promotionEnabled'] ?? true,
      wishlistEnabled: map['wishlistEnabled'] ?? true,
      reviewEnabled: map['reviewEnabled'] ?? true,
      systemEnabled: map['systemEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pushEnabled': pushEnabled,
      'orderEnabled': orderEnabled,
      'promotionEnabled': promotionEnabled,
      'wishlistEnabled': wishlistEnabled,
      'reviewEnabled': reviewEnabled,
      'systemEnabled': systemEnabled,
    };
  }

  NotificationSettingsModel copyWith({
    bool? pushEnabled,
    bool? orderEnabled,
    bool? promotionEnabled,
    bool? wishlistEnabled,
    bool? reviewEnabled,
    bool? systemEnabled,
  }) {
    return NotificationSettingsModel(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      orderEnabled: orderEnabled ?? this.orderEnabled,
      promotionEnabled: promotionEnabled ?? this.promotionEnabled,
      wishlistEnabled: wishlistEnabled ?? this.wishlistEnabled,
      reviewEnabled: reviewEnabled ?? this.reviewEnabled,
      systemEnabled: systemEnabled ?? this.systemEnabled,
    );
  }
}
