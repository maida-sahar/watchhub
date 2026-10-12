import 'package:cloud_firestore/cloud_firestore.dart';

/// ProductModel
///
/// Represents a single document inside the `products` Firestore collection.
/// A Product is a watch sold inside WatchHub, and this model is designed
/// to be the single source of truth consumed by every downstream module:
/// Cart, Wishlist, Orders, Checkout, Reviews, Search, Filters, Inventory,
/// and Reports.
///
/// This model is immutable — every field is `final`. To change any
/// value, use [copyWith] to produce a new instance instead of mutating
/// this one.
class ProductModel {
  // =========================================================
  // PRODUCT INFORMATION
  // =========================================================

  /// Firestore auto-generated document id.
  final String id;

  /// Product name (e.g. "Rolex Submariner Date"). Required, cannot be empty.
  final String name;

  /// Full, long-form product description shown on the Product Details screen.
  final String description;

  /// Short one-line description used in compact contexts (lists, cards,
  /// search results).
  final String shortDescription;
  

  // =========================================================
  // CATEGORY
  // =========================================================

  /// Firestore document id of the category this product belongs to.
  /// Required, cannot be empty.
  final String categoryId;

  /// Denormalized category name, kept in sync with [categoryId] so
  /// UI layers can display it without an extra lookup.
  final String categoryName;

  // =========================================================
  // BRAND
  // =========================================================

  /// Firestore document id of the brand this product belongs to.
  /// Required, cannot be empty.
  final String brandId;

  /// Denormalized brand name, kept in sync with [brandId] so UI layers
  /// can display it without an extra lookup.
  final String brandName;

  // =========================================================
  // PRICING
  // =========================================================

  /// Base selling price. Must be `>= 0`.
  final double price;

  /// Discounted price, if any. Must be `>= 0`. When there is no active
  /// discount, this is typically equal to [price].
  final double discountPrice;

  /// Discount expressed as a percentage (e.g. `15.0` for 15% off).
  /// Derived/display value — not independently validated against
  /// [price]/[discountPrice] since either side may be set first.
  final double discountPercentage;

  /// ISO 4217 currency code (e.g. "USD", "PKR", "INR").
  final String currency;

  // =========================================================
  // IMAGES
  // =========================================================

  /// Gallery of full-size product image URLs. Optional — a product's
  /// only required image is [thumbnail]; gallery images are additional
  /// pictures the Admin Panel lets the admin attach on top of it.
  final List<String> galleryImages;

  /// URL of the small thumbnail image used in grids and list rows.
  final String thumbnail;

  // =========================================================
  // INVENTORY
  // =========================================================

  /// Stock keeping unit. Required, cannot be empty.
  final String sku;

  /// Units currently available to sell. Must be `>= 0`.
  final int stock;

  /// Running total of units sold. Used for "Best Seller" logic and
  /// reporting. Must be `>= 0`.
  final int soldCount;

  /// Threshold below which the Admin Panel should surface a low-stock
  /// warning. Must be `>= 0`.
  final int minimumStock;

  // =========================================================
  // PRODUCT STATUS
  // =========================================================

  /// Whether this product is visible in the User App. Only active
  /// products should be shown to end users; the Admin Panel may still
  /// see and manage inactive products.
  final bool isActive;

  /// Whether this product should be highlighted in a "Featured
  /// Products" section of the app.
  final bool isFeatured;

  /// Whether this product should be tagged/surfaced as a best seller
  /// (typically driven by [soldCount], but stored explicitly so the
  /// Admin Panel can override it).
  final bool isBestSeller;

  /// Whether this product should be tagged/surfaced as a new arrival.
  final bool isNewArrival;

  // =========================================================
  // SPECIFICATIONS
  // =========================================================

  /// Free-form technical specifications, e.g. Case Material, Strap
  /// Material, Movement, Glass Type, Water Resistance, Dial Color,
  /// Case Size, Weight, Warranty. Kept as `Map<String, dynamic>` since
  /// the exact set of spec keys varies by product/category and is
  /// expected to evolve without requiring a model migration.
  final Map<String, dynamic> specifications;

  // =========================================================
  // SEARCH & FILTER
  // =========================================================

  /// Free-form tags used for filtering/discovery (e.g. "chronograph",
  /// "diver", "limited-edition").
  final List<String> tags;

  /// Available/represented colors for this product (e.g. "Black",
  /// "Silver", "Rose Gold"), used for color-swatch filters.
  final List<String> colors;

  /// Additional search keywords not necessarily shown in the UI,
  /// used purely to widen search recall (e.g. common misspellings,
  /// alternate model names).
  final List<String> keywords;

  // =========================================================
  // RATING
  // =========================================================

  /// Average review rating, typically on a 0.0–5.0 scale. Must be `>= 0`.
  final double averageRating;

  /// Total number of reviews submitted for this product. Must be `>= 0`.
  final int totalReviews;

  // =========================================================
  // SEO
  // =========================================================

  /// URL-friendly identifier used for SEO-friendly product links
  /// (e.g. "rolex-submariner-date").
  final String slug;

  // =========================================================
  // DATES
  // =========================================================

  /// Timestamp of when this product document was created.
  final DateTime createdAt;

  /// Timestamp of the last time this product document was updated.
  final DateTime updatedAt;

  /// Creates a [ProductModel].
  ///
  /// Validates its own invariants at construction time so an invalid
  /// [ProductModel] can never exist in memory:
  /// - [name] must not be empty (after trimming).
  /// - [sku] must not be empty (after trimming).
  /// - [categoryId] must not be empty.
  /// - [brandId] must not be empty.
  /// - [price], [discountPrice], [stock], [minimumStock], [soldCount],
  ///   [totalReviews], and [averageRating] must all be `>= 0`.
  ///
  /// Throws an [ArgumentError] if any of the above are violated.
  ProductModel({
    required this.id,
    required this.name,
    this.description = '',
    this.shortDescription = '',
    required this.categoryId,
    this.categoryName = '',
    required this.brandId,
    this.brandName = '',
    required this.price,
    double? discountPrice,
    this.discountPercentage = 0.0,
    this.currency = 'USD',
    required this.galleryImages,
    this.thumbnail = '',
    required this.sku,
    this.stock = 0,
    this.soldCount = 0,
    this.minimumStock = 0,
    this.isActive = true,
    this.isFeatured = false,
    this.isBestSeller = false,
    this.isNewArrival = false,
    this.specifications = const {},
    this.tags = const [],
    this.colors = const [],
    this.keywords = const [],
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.slug = '',
    required this.createdAt,
    required this.updatedAt,
  }) : discountPrice = discountPrice ?? price {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'Product name cannot be empty.');
    }
    if (sku.trim().isEmpty) {
      throw ArgumentError.value(sku, 'sku', 'SKU cannot be empty.');
    }
    if (categoryId.trim().isEmpty) {
      throw ArgumentError.value(
        categoryId,
        'categoryId',
        'categoryId cannot be empty.',
      );
    }
    if (brandId.trim().isEmpty) {
      throw ArgumentError.value(
        brandId,
        'brandId',
        'brandId cannot be empty.',
      );
    }
    if (price < 0) {
      throw ArgumentError.value(price, 'price', 'price cannot be negative.');
    }
    if (this.discountPrice < 0) {
      throw ArgumentError.value(
        this.discountPrice,
        'discountPrice',
        'discountPrice cannot be negative.',
      );
    }
    if (stock < 0) {
      throw ArgumentError.value(stock, 'stock', 'stock cannot be negative.');
    }
    if (minimumStock < 0) {
      throw ArgumentError.value(
        minimumStock,
        'minimumStock',
        'minimumStock cannot be negative.',
      );
    }
    if (soldCount < 0) {
      throw ArgumentError.value(
        soldCount,
        'soldCount',
        'soldCount cannot be negative.',
      );
    }
    if (totalReviews < 0) {
      throw ArgumentError.value(
        totalReviews,
        'totalReviews',
        'totalReviews cannot be negative.',
      );
    }
    if (averageRating < 0) {
      throw ArgumentError.value(
        averageRating,
        'averageRating',
        'averageRating cannot be negative.',
      );
    }
  }

  /// Creates an "empty" placeholder product.
  ///
  /// Useful as a default/fallback value (e.g. in UI state) before real
  /// data has loaded, avoiding the need for nullable [ProductModel]s.
  /// Uses placeholder values that still satisfy every invariant
  /// enforced by the main constructor.
  factory ProductModel.empty() {
    final now = DateTime.now();
    return ProductModel(
      id: '',
      name: 'Unknown Product',
      description: '',
      shortDescription: '',
      categoryId: 'unknown',
      categoryName: '',
      brandId: 'unknown',
      brandName: '',
      price: 0,
      discountPrice: 0,
      discountPercentage: 0,
      currency: 'USD',
      galleryImages: const ['https://via.placeholder.com/400'],
      thumbnail: '',
      sku: 'UNKNOWN-SKU',
      stock: 0,
      soldCount: 0,
      minimumStock: 0,
      isActive: false,
      isFeatured: false,
      isBestSeller: false,
      isNewArrival: false,
      specifications: const {},
      tags: const [],
      colors: const [],
      keywords: const [],
      averageRating: 0,
      totalReviews: 0,
      slug: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Creates a [ProductModel] from a Firestore document map.
  ///
  /// [map] is the raw data returned by `DocumentSnapshot.data()`.
  /// [documentId] is passed separately since the id is not stored as a
  /// field inside the document itself, but comes from `DocumentSnapshot.id`.
  ///
  /// Defensive parsing is used throughout so that missing or malformed
  /// fields never cause a crash — sensible defaults are applied instead.
  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ProductModel(
      id: documentId,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      shortDescription: map['shortDescription'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? '',
      categoryName: map['categoryName'] as String? ?? '',
      brandId: map['brandId'] as String? ?? '',
      brandName: map['brandName'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      discountPrice: (map['discountPrice'] as num?)?.toDouble(),
      discountPercentage: (map['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'USD',
      galleryImages: _stringListFrom(map['imageUrls']),
      thumbnail: map['thumbnail'] as String? ?? '',
      sku: map['sku'] as String? ?? '',
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      soldCount: (map['soldCount'] as num?)?.toInt() ?? 0,
      minimumStock: (map['minimumStock'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      isFeatured: map['isFeatured'] as bool? ?? false,
      isBestSeller: map['isBestSeller'] as bool? ?? false,
      isNewArrival: map['isNewArrival'] as bool? ?? false,
      specifications: map['specifications'] is Map
          ? Map<String, dynamic>.from(map['specifications'] as Map)
          : const {},
      tags: _stringListFrom(map['tags']),
      colors: _stringListFrom(map['colors']),
      keywords: _stringListFrom(map['keywords']),
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (map['totalReviews'] as num?)?.toInt() ?? 0,
      slug: map['slug'] as String? ?? '',
      createdAt: _timestampToDateTime(map['createdAt']),
      updatedAt: _timestampToDateTime(map['updatedAt']),
    );
  }

  /// Converts this [ProductModel] into a map suitable for writing to
  /// Firestore via `DocumentReference.set()` or `.update()`.
  ///
  /// Note: [id] is intentionally excluded, since the document id is
  /// managed by Firestore itself (as the document path), not stored
  /// as a field within the document.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'shortDescription': shortDescription,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'brandId': brandId,
      'brandName': brandName,
      'price': price,
      'discountPrice': discountPrice,
      'discountPercentage': discountPercentage,
      'currency': currency,
      'imageUrls': galleryImages,
      'thumbnail': thumbnail,
      'sku': sku,
      'stock': stock,
      'soldCount': soldCount,
      'minimumStock': minimumStock,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'isBestSeller': isBestSeller,
      'isNewArrival': isNewArrival,
      'specifications': specifications,
      'tags': tags,
      'colors': colors,
      'keywords': keywords,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'slug': slug,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Creates a [ProductModel] from a plain JSON-decoded map (e.g. from a
  /// REST API or a local cache file), as opposed to [fromMap] which
  /// expects Firestore-native types like [Timestamp].
  ///
  /// Dates are expected as ISO-8601 strings. [id] is expected to be
  /// present as a field here (unlike [fromMap]), since JSON has no
  /// document-id concept of its own.
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      shortDescription: json['shortDescription'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? '',
      brandId: json['brandId'] as String? ?? '',
      brandName: json['brandName'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      discountPrice: (json['discountPrice'] as num?)?.toDouble(),
      discountPercentage:
          (json['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      galleryImages: _stringListFrom(json['imageUrls']),
      thumbnail: json['thumbnail'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      soldCount: (json['soldCount'] as num?)?.toInt() ?? 0,
      minimumStock: (json['minimumStock'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      isFeatured: json['isFeatured'] as bool? ?? false,
      isBestSeller: json['isBestSeller'] as bool? ?? false,
      isNewArrival: json['isNewArrival'] as bool? ?? false,
      specifications: json['specifications'] is Map
          ? Map<String, dynamic>.from(json['specifications'] as Map)
          : const {},
      tags: _stringListFrom(json['tags']),
      colors: _stringListFrom(json['colors']),
      keywords: _stringListFrom(json['keywords']),
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      slug: json['slug'] as String? ?? '',
      createdAt: _isoStringToDateTime(json['createdAt']),
      updatedAt: _isoStringToDateTime(json['updatedAt']),
    );
  }

  /// Converts this [ProductModel] into a plain JSON-encodable map,
  /// including [id] (unlike [toMap]) and using ISO-8601 strings for
  /// dates instead of Firestore [Timestamp]s.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'shortDescription': shortDescription,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'brandId': brandId,
      'brandName': brandName,
      'price': price,
      'discountPrice': discountPrice,
      'discountPercentage': discountPercentage,
      'currency': currency,
      'imageUrls': galleryImages,
      'thumbnail': thumbnail,
      'sku': sku,
      'stock': stock,
      'soldCount': soldCount,
      'minimumStock': minimumStock,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'isBestSeller': isBestSeller,
      'isNewArrival': isNewArrival,
      'specifications': specifications,
      'tags': tags,
      'colors': colors,
      'keywords': keywords,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'slug': slug,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Returns a new [ProductModel] with the given fields replaced.
  ///
  /// Any field left unspecified keeps its current value, since this
  /// model is immutable and cannot be edited in place. Re-runs the same
  /// validation as the main constructor, so an invalid replacement
  /// value is still rejected here.
  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    String? shortDescription,
    String? categoryId,
    String? categoryName,
    String? brandId,
    String? brandName,
    double? price,
    double? discountPrice,
    double? discountPercentage,
    String? currency,
    List<String>? imageUrls,
    String? thumbnail,
    String? sku,
    int? stock,
    int? soldCount,
    int? minimumStock,
    bool? isActive,
    bool? isFeatured,
    bool? isBestSeller,
    bool? isNewArrival,
    Map<String, dynamic>? specifications,
    List<String>? tags,
    List<String>? colors,
    List<String>? keywords,
    double? averageRating,
    int? totalReviews,
    String? slug,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      shortDescription: shortDescription ?? this.shortDescription,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      currency: currency ?? this.currency,
      galleryImages: imageUrls ?? this.galleryImages,
      thumbnail: thumbnail ?? this.thumbnail,
      sku: sku ?? this.sku,
      stock: stock ?? this.stock,
      soldCount: soldCount ?? this.soldCount,
      minimumStock: minimumStock ?? this.minimumStock,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      isBestSeller: isBestSeller ?? this.isBestSeller,
      isNewArrival: isNewArrival ?? this.isNewArrival,
      specifications: specifications ?? this.specifications,
      tags: tags ?? this.tags,
      colors: colors ?? this.colors,
      keywords: keywords ?? this.keywords,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      slug: slug ?? this.slug,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Safely converts a raw list value (e.g. from Firestore or JSON)
  /// into a `List<String>`. Falls back to an empty list if the value
  /// is missing or of an unexpected type, so parsing never throws.
  static List<String> _stringListFrom(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }

  /// Safely converts a Firestore [Timestamp] (or other possible raw
  /// value) into a [DateTime]. Falls back to the current time if the
  /// value is missing or of an unexpected type, so parsing never throws.
  static DateTime _timestampToDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  /// Safely parses an ISO-8601 date string (as used by [toJson]) into
  /// a [DateTime]. Falls back to the current time if the value is
  /// missing, empty, or malformed.
  static DateTime _isoStringToDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  @override
  String toString() {
    return 'ProductModel(id: $id, name: $name, categoryId: $categoryId, '
        'brandId: $brandId, price: $price, discountPrice: $discountPrice, '
        'currency: $currency, sku: $sku, stock: $stock, '
        'isActive: $isActive, isFeatured: $isFeatured, '
        'isBestSeller: $isBestSeller, isNewArrival: $isNewArrival, '
        'averageRating: $averageRating, totalReviews: $totalReviews, '
        'slug: $slug, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductModel &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.shortDescription == shortDescription &&
        other.categoryId == categoryId &&
        other.categoryName == categoryName &&
        other.brandId == brandId &&
        other.brandName == brandName &&
        other.price == price &&
        other.discountPrice == discountPrice &&
        other.discountPercentage == discountPercentage &&
        other.currency == currency &&
        _listEquals(other.galleryImages, galleryImages) &&
        other.thumbnail == thumbnail &&
        other.sku == sku &&
        other.stock == stock &&
        other.soldCount == soldCount &&
        other.minimumStock == minimumStock &&
        other.isActive == isActive &&
        other.isFeatured == isFeatured &&
        other.isBestSeller == isBestSeller &&
        other.isNewArrival == isNewArrival &&
        _mapEquals(other.specifications, specifications) &&
        _listEquals(other.tags, tags) &&
        _listEquals(other.colors, colors) &&
        _listEquals(other.keywords, keywords) &&
        other.averageRating == averageRating &&
        other.totalReviews == totalReviews &&
        other.slug == slug &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    // Object.hash() only supports up to 20 positional arguments, and
    // this model has more fields than that, so the field values are
    // combined via Object.hashAll over an explicit list instead.
    return Object.hashAll([
      id,
      name,
      description,
      shortDescription,
      categoryId,
      categoryName,
      brandId,
      brandName,
      price,
      discountPrice,
      discountPercentage,
      currency,
      Object.hashAll(galleryImages),
      thumbnail,
      sku,
      stock,
      soldCount,
      minimumStock,
      isActive,
      isFeatured,
      isBestSeller,
      isNewArrival,
      _hashMap(specifications),
      Object.hashAll(tags),
      Object.hashAll(colors),
      Object.hashAll(keywords),
      averageRating,
      totalReviews,
      slug,
      createdAt,
      updatedAt,
    ]);
  }

  /// Combines a map's entries into a single hash code, independent of
  /// the map's iteration order (two maps with the same key/value pairs
  /// in a different order must hash identically). Keys are sorted
  /// first so the result is deterministic, then folded together with
  /// [Object.hashAll] — `dart:core` has no built-in order-independent
  /// hashing helper for maps.
  static int _hashMap(Map<String, dynamic> map) {
    final sortedKeys = map.keys.toList()..sort();
    return Object.hashAll(
      sortedKeys.map((key) => Object.hash(key, map[key])),
    );
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}