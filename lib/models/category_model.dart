import 'package:cloud_firestore/cloud_firestore.dart';

/// CategoryModel
///
/// Represents a single document inside the `categories` Firestore collection.
/// Used across both the User App (to display active categories) and the
/// Admin Panel (to manage all categories, including inactive ones).
///
/// Example categories: Luxury, Analog, Digital, Smart Watch, Sports, Casual.
///
/// This model is immutable — every field is `final`. To change any value,
/// use [copyWith] to produce a new instance instead of mutating this one.
class CategoryModel {
  /// Firestore auto-generated document id.
  final String id;

  /// Display name of the category (e.g. "Luxury", "Smart Watch").
  final String name;

  /// Short description shown under the category name.
  final String description;

  /// Main image used for the category (e.g. on category listing screens).
  final String imageUrl;

  /// Small icon used on the Home Screen category row/grid.
  final String iconUrl;

  /// Banner image used at the top of the category's product listing page.
  final String bannerUrl;

  /// Whether this category is visible in the User App.
  /// Only categories with `isActive == true` should be shown to end users.
  /// The Admin Panel may still see and manage inactive categories.
  final bool isActive;

  /// Determines the sort order in which categories are displayed.
  /// Lower values are displayed first.
  final int displayOrder;

  /// Timestamp of when this category document was created.
  final DateTime createdAt;

  /// Timestamp of the last time this category document was updated.
  final DateTime updatedAt;

  /// Creates a [CategoryModel].
  ///
  /// All fields are required except where a sensible default exists,
  /// keeping the model fully non-nullable and predictable to consume.
  const CategoryModel({
    required this.id,
    required this.name,
    this.description = '',
    this.imageUrl = '',
    this.iconUrl = '',
    this.bannerUrl = '',
    this.isActive = true,
    this.displayOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates an "empty" placeholder category.
  ///
  /// Useful as a default/fallback value (e.g. in UI state) before real
  /// data has loaded, avoiding the need for nullable [CategoryModel]s.
  factory CategoryModel.empty() {
    final now = DateTime.now();
    return CategoryModel(
      id: '',
      name: '',
      description: '',
      imageUrl: '',
      iconUrl: '',
      bannerUrl: '',
      isActive: false,
      displayOrder: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Creates a [CategoryModel] from a Firestore document map.
  ///
  /// [map] is the raw data returned by `DocumentSnapshot.data()`.
  /// [documentId] is passed separately since the id is not stored as a
  /// field inside the document itself, but comes from `DocumentSnapshot.id`.
  ///
  /// Defensive parsing is used throughout so that missing or malformed
  /// fields never cause a crash — sensible defaults are applied instead.
  factory CategoryModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CategoryModel(
      id: documentId,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      iconUrl: map['iconUrl'] as String? ?? '',
      bannerUrl: map['bannerUrl'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      displayOrder: (map['displayOrder'] as num?)?.toInt() ?? 0,
      createdAt: _timestampToDateTime(map['createdAt']),
      updatedAt: _timestampToDateTime(map['updatedAt']),
    );
  }

  /// Converts this [CategoryModel] into a map suitable for writing to
  /// Firestore via `DocumentReference.set()` or `.update()`.
  ///
  /// Note: [id] is intentionally excluded, since the document id is
  /// managed by Firestore itself (as the document path), not stored
  /// as a field within the document.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'iconUrl': iconUrl,
      'bannerUrl': bannerUrl,
      'isActive': isActive,
      'displayOrder': displayOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Returns a new [CategoryModel] with the given fields replaced.
  ///
  /// Any field left unspecified keeps its current value, since this
  /// model is immutable and cannot be edited in place.
  CategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? iconUrl,
    String? bannerUrl,
    bool? isActive,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      iconUrl: iconUrl ?? this.iconUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Safely converts a Firestore [Timestamp] (or other possible raw
  /// value) into a [DateTime]. Falls back to the current time if the
  /// value is missing or of an unexpected type, so parsing never throws.
  static DateTime _timestampToDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.now();
  }

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, description: $description, '
        'imageUrl: $imageUrl, iconUrl: $iconUrl, bannerUrl: $bannerUrl, '
        'isActive: $isActive, displayOrder: $displayOrder, '
        'createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.imageUrl == imageUrl &&
        other.iconUrl == iconUrl &&
        other.bannerUrl == bannerUrl &&
        other.isActive == isActive &&
        other.displayOrder == displayOrder &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      imageUrl,
      iconUrl,
      bannerUrl,
      isActive,
      displayOrder,
      createdAt,
      updatedAt,
    );
  }
}