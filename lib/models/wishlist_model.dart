import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an item saved in a user's wishlist within the WatchHub application.
///
/// Implements immutability, defensive parsing for Firestore data types,
/// full field-level validation, and JSON serialization.
class WishlistModel {
  /// Unique identifier for the wishlist document.
  final String id;

  /// ID of the user who owns this wishlist item.
  final String userId;

  /// ID of the saved product.
  final String productId;

  /// Name of the product at the time of saving or sync.
  final String productName;

  /// URL string pointing to the primary product image/thumbnail.
  final String productImage;

  /// ID of the brand associated with the product.
  final String brandId;

  /// Name of the brand associated with the product.
  final String brandName;

  /// ID of the category associated with the product.
  final String categoryId;

  /// Name of the category associated with the product.
  final String categoryName;

  /// Regular price of the product. Must be >= 0.
  final double price;

  /// Discounted price of the product if applicable. Must be >= 0.
  final double discountPrice;

  /// Average rating of the product.
  final double averageRating;

  /// Flag indicating if the product is currently in stock.
  final bool isInStock;

  /// Flag indicating if the product document is active in the store.
  final bool isActive;

  /// Timestamp when the item was added to the wishlist.
  final DateTime createdAt;

  /// Timestamp when the wishlist entry was last updated.
  final DateTime updatedAt;

  /// Creates a [WishlistModel] instance with strict invariant assertions.
  const WishlistModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.brandId,
    required this.brandName,
    required this.categoryId,
    required this.categoryName,
    required this.price,
    required this.discountPrice,
    required this.averageRating,
    required this.isInStock,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  })  : assert(userId != '', 'userId cannot be empty'),
        assert(productId != '', 'productId cannot be empty'),
        assert(price >= 0, 'price cannot be negative'),
        assert(discountPrice >= 0, 'discountPrice cannot be negative');

  /// Creates a copy of [WishlistModel] with updated fields.
  WishlistModel copyWith({
    String? id,
    String? userId,
    String? productId,
    String? productName,
    String? productImage,
    String? brandId,
    String? brandName,
    String? categoryId,
    String? categoryName,
    double? price,
    double? discountPrice,
    double? averageRating,
    bool? isInStock,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WishlistModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      averageRating: averageRating ?? this.averageRating,
      isInStock: isInStock ?? this.isInStock,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converts this [WishlistModel] to a Map compatible with Firestore serialization.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'brandId': brandId,
      'brandName': brandName,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'price': price,
      'discountPrice': discountPrice,
      'averageRating': averageRating,
      'isInStock': isInStock,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Constructs a [WishlistModel] from a Firestore Map / Document snapshot.
  ///
  /// Safely converts numeric types, handles fallback defaults, and parses both
  /// Firestore [Timestamp] objects and ISO string formats.
  factory WishlistModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    final parsedUserId = map['userId'] as String? ?? '';
    final parsedProductId = map['productId'] as String? ?? '';

    if (parsedUserId.trim().isEmpty) {
      throw ArgumentError('WishlistModel validation failed: userId is required.');
    }
    if (parsedProductId.trim().isEmpty) {
      throw ArgumentError('WishlistModel validation failed: productId is required.');
    }

    final parsedPrice = (map['price'] as num?)?.toDouble() ?? 0.0;
    final parsedDiscountPrice = (map['discountPrice'] as num?)?.toDouble() ?? 0.0;

    if (parsedPrice < 0) {
      throw ArgumentError('WishlistModel validation failed: price cannot be negative.');
    }
    if (parsedDiscountPrice < 0) {
      throw ArgumentError('WishlistModel validation failed: discountPrice cannot be negative.');
    }

    return WishlistModel(
      id: documentId ?? (map['id'] as String? ?? ''),
      userId: parsedUserId,
      productId: parsedProductId,
      productName: map['productName'] as String? ?? '',
      productImage: map['productImage'] as String? ?? '',
      brandId: map['brandId'] as String? ?? '',
      brandName: map['brandName'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? '',
      categoryName: map['categoryName'] as String? ?? '',
      price: parsedPrice,
      discountPrice: parsedDiscountPrice,
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
      isInStock: map['isInStock'] as bool? ?? true,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  /// Helper parser to handle [Timestamp], ISO String, or int time values safely.
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }

  /// Converts this [WishlistModel] into a standard JSON string.
  String toJson() => json.encode(toMapForJson());

  /// Helper method for JSON output converting [DateTime] to ISO 8601 strings.
  Map<String, dynamic> toMapForJson() {
    final map = toMap();
    map['createdAt'] = createdAt.toIso8601String();
    map['updatedAt'] = updatedAt.toIso8601String();
    return map;
  }

  /// Constructs a [WishlistModel] from a JSON string.
  factory WishlistModel.fromJson(String source) =>
      WishlistModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'WishlistModel(id: $id, userId: $userId, productId: $productId, '
        'productName: $productName, productImage: $productImage, brandId: $brandId, '
        'brandName: $brandName, categoryId: $categoryId, categoryName: $categoryName, '
        'price: $price, discountPrice: $discountPrice, averageRating: $averageRating, '
        'isInStock: $isInStock, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WishlistModel &&
        other.id == id &&
        other.userId == userId &&
        other.productId == productId &&
        other.productName == productName &&
        other.productImage == productImage &&
        other.brandId == brandId &&
        other.brandName == brandName &&
        other.categoryId == categoryId &&
        other.categoryName == categoryName &&
        other.price == price &&
        other.discountPrice == discountPrice &&
        other.averageRating == averageRating &&
        other.isInStock == isInStock &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      userId,
      productId,
      productName,
      productImage,
      brandId,
      brandName,
      categoryId,
      categoryName,
      price,
      discountPrice,
      averageRating,
      isInStock,
      isActive,
      createdAt,
      updatedAt,
    ]);
  }
}