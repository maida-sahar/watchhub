import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single item stored in the user's shopping cart within WatchHub.
///
/// Implements immutability, validation asserts, Firestore serialization,
/// and deep value-equality comparison.
class CartModel {
  /// Unique identifier for the cart document.
  final String id;

  /// ID of the user who owns this cart item.
  final String userId;

  /// ID of the product.
  final String productId;

  /// Name of the product at the time of adding or syncing.
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

  /// Quantity of items added. Must be > 0.
  final int quantity;

  /// Maximum allowed purchase quantity for a single user (usually configured per product).
  final int maxQuantity;

  /// Current available inventory stock. Must be >= 0.
  final int stock;

  /// Average rating of the product.
  final double averageRating;

  /// Flag indicating if the product is active in the store.
  final bool isActive;

  /// Flag indicating if the product is currently in stock.
  final bool isInStock;

  /// Timestamp when the item was added to the cart.
  final DateTime createdAt;

  /// Timestamp when the cart item was last updated.
  final DateTime updatedAt;

  /// Creates a [CartModel] instance with strict business rule invariant assertions.
  const CartModel({
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
    required this.quantity,
    required this.maxQuantity,
    required this.stock,
    required this.averageRating,
    required this.isActive,
    required this.isInStock,
    required this.createdAt,
    required this.updatedAt,
  })  : assert(userId != '', 'userId cannot be empty'),
        assert(productId != '', 'productId cannot be empty'),
        assert(price >= 0, 'price cannot be negative'),
        assert(discountPrice >= 0, 'discountPrice cannot be negative'),
        assert(quantity > 0, 'quantity must be greater than zero'),
        assert(stock >= 0, 'stock cannot be negative');

  /// Creates a copy of this [CartModel] with updated fields.
  CartModel copyWith({
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
    int? quantity,
    int? maxQuantity,
    int? stock,
    double? averageRating,
    bool? isActive,
    bool? isInStock,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CartModel(
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
      quantity: quantity ?? this.quantity,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      stock: stock ?? this.stock,
      averageRating: averageRating ?? this.averageRating,
      isActive: isActive ?? this.isActive,
      isInStock: isInStock ?? this.isInStock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converts this [CartModel] to a Map compatible with Firestore serialization.
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
      'quantity': quantity,
      'maxQuantity': maxQuantity,
      'stock': stock,
      'averageRating': averageRating,
      'isActive': isActive,
      'isInStock': isInStock,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Constructs a [CartModel] from a Firestore Map / Document snapshot.
  ///
  /// Safely converts numeric types, handles fallback defaults, and parses both
  /// Firestore [Timestamp] objects and ISO string formats.
  factory CartModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    final parsedUserId = map['userId'] as String? ?? '';
    final parsedProductId = map['productId'] as String? ?? '';

    if (parsedUserId.trim().isEmpty) {
      throw ArgumentError('CartModel validation failed: userId is required.');
    }
    if (parsedProductId.trim().isEmpty) {
      throw ArgumentError('CartModel validation failed: productId is required.');
    }

    final parsedPrice = (map['price'] as num?)?.toDouble() ?? 0.0;
    final parsedDiscountPrice = (map['discountPrice'] as num?)?.toDouble() ?? 0.0;
    final parsedQuantity = (map['quantity'] as num?)?.toInt() ?? 1;
    final parsedStock = (map['stock'] as num?)?.toInt() ?? 0;

    if (parsedPrice < 0) {
      throw ArgumentError('CartModel validation failed: price cannot be negative.');
    }
    if (parsedDiscountPrice < 0) {
      throw ArgumentError('CartModel validation failed: discountPrice cannot be negative.');
    }
    if (parsedQuantity <= 0) {
      throw ArgumentError('CartModel validation failed: quantity must be greater than zero.');
    }
    if (parsedStock < 0) {
      throw ArgumentError('CartModel validation failed: stock cannot be negative.');
    }

    return CartModel(
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
      quantity: parsedQuantity,
      maxQuantity: (map['maxQuantity'] as num?)?.toInt() ?? 5,
      stock: parsedStock,
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
      isActive: map['isActive'] as bool? ?? true,
      isInStock: map['isInStock'] as bool? ?? true,
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

  /// Converts this [CartModel] into a standard JSON string.
  String toJson() => json.encode(toMapForJson());

  /// Helper method for JSON output converting [DateTime] to ISO 8601 strings.
  Map<String, dynamic> toMapForJson() {
    final map = toMap();
    map['createdAt'] = createdAt.toIso8601String();
    map['updatedAt'] = updatedAt.toIso8601String();
    return map;
  }

  /// Constructs a [CartModel] from a JSON string.
  factory CartModel.fromJson(String source) =>
      CartModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CartModel(id: $id, userId: $userId, productId: $productId, '
        'productName: $productName, productImage: $productImage, brandId: $brandId, '
        'brandName: $brandName, categoryId: $categoryId, categoryName: $categoryName, '
        'price: $price, discountPrice: $discountPrice, quantity: $quantity, '
        'maxQuantity: $maxQuantity, stock: $stock, averageRating: $averageRating, '
        'isActive: $isActive, isInStock: $isInStock, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CartModel &&
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
        other.quantity == quantity &&
        other.maxQuantity == maxQuantity &&
        other.stock == stock &&
        other.averageRating == averageRating &&
        other.isActive == isActive &&
        other.isInStock == isInStock &&
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
      quantity,
      maxQuantity,
      stock,
      averageRating,
      isActive,
      isInStock,
      createdAt,
      updatedAt,
    ]);
  }
}
