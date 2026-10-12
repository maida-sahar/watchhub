import 'package:cloud_firestore/cloud_firestore.dart';

/// BrandModel
///
/// Represents a single document inside the `brands` Firestore collection.
/// A Brand is the manufacturer of a watch (e.g. Rolex, Omega, Casio,
/// Apple, Samsung, Titan, Fossil, Seiko) and is used throughout the app
/// wherever products need to be grouped or filtered by manufacturer.
///
/// This model is immutable — every field is `final`. To change any
/// value, use [copyWith] to produce a new instance instead of mutating
/// this one.
class BrandModel {
  /// Firestore auto-generated document id.
  final String id;

  /// Brand name (e.g. "Rolex", "Casio"). Required, cannot be empty.
  final String name;

  /// Short description of the brand's history, style, or positioning.
  final String description;

  /// URL of the brand's logo, used in compact contexts (lists, chips).
  final String logoUrl;

  /// URL of a wide banner image, used at the top of a brand's page.
  final String bannerUrl;

  /// The brand's official website. Optional — may be an empty string.
  /// When non-empty, must be a well-formed absolute URL (see
  /// [_isValidWebsite]).
  final String website;

  /// Country the brand originates from (e.g. "Switzerland", "Japan").
  final String country;

  /// Whether this brand should be highlighted in a "Featured Brands"
  /// section of the app.
  final bool isFeatured;

  /// Whether this brand is visible in the User App. Only active brands
  /// should be shown to end users; the Admin Panel may still see and
  /// manage inactive brands.
  final bool isActive;

  /// Determines sort order when displaying brands. Lower values are
  /// displayed first. Must be `>= 0`.
  final int displayOrder;

  /// Timestamp of when this brand document was created.
  final DateTime createdAt;

  /// Timestamp of the last time this brand document was updated.
  final DateTime updatedAt;

  /// Creates a [BrandModel].
  ///
  /// Validates its own invariants at construction time so an invalid
  /// [BrandModel] can never exist in memory:
  /// - [name] must not be empty (after trimming).
  /// - [website], if non-empty, must be a valid absolute URL.
  /// - [displayOrder] must be `>= 0`.
  ///
  /// Throws an [ArgumentError] if any of the above are violated.
  BrandModel({
    required this.id,
    required this.name,
    this.description = '',
    this.logoUrl = '',
    this.bannerUrl = '',
    this.website = '',
    this.country = '',
    this.isFeatured = false,
    this.isActive = true,
    this.displayOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  }) {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'Brand name cannot be empty.');
    }
    if (website.trim().isNotEmpty && !_isValidWebsite(website)) {
      throw ArgumentError.value(
        website,
        'website',
        'Website must be a valid URL (e.g. https://www.example.com).',
      );
    }
    if (displayOrder < 0) {
      throw ArgumentError.value(
        displayOrder,
        'displayOrder',
        'displayOrder cannot be negative.',
      );
    }
  }

  /// Creates an "empty" placeholder brand.
  ///
  /// Useful as a default/fallback value (e.g. in UI state) before real
  /// data has loaded, avoiding the need for nullable [BrandModel]s.
  /// Uses a placeholder name so it still satisfies the non-empty-name
  /// invariant enforced by the main constructor.
  factory BrandModel.empty() {
    final now = DateTime.now();
    return BrandModel(
      id: '',
      name: 'Unknown Brand',
      description: '',
      logoUrl: '',
      bannerUrl: '',
      website: '',
      country: '',
      isFeatured: false,
      isActive: false,
      displayOrder: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Returns true if [url] is a well-formed absolute http/https URL.
  ///
  /// Kept as a static helper (rather than only inline in the
  /// constructor) so callers — e.g. a form field validator — can run
  /// the same check before ever attempting to construct a [BrandModel].
  static bool isValidWebsite(String url) => _isValidWebsite(url);

  static bool _isValidWebsite(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return true; // Website is optional.
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return false;
    return uri.isAbsolute &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  /// Creates a [BrandModel] from a Firestore document map.
  ///
  /// [map] is the raw data returned by `DocumentSnapshot.data()`.
  /// [documentId] is passed separately since the id is not stored as a
  /// field inside the document itself, but comes from `DocumentSnapshot.id`.
  ///
  /// Defensive parsing is used throughout so that missing or malformed
  /// fields never cause a crash — sensible defaults are applied instead.
  /// A malformed `website` value (e.g. corrupted by a manual Firestore
  /// edit) is dropped to an empty string rather than throwing, since
  /// reading existing data should be resilient even if writing new data
  /// is strict.
  factory BrandModel.fromMap(Map<String, dynamic> map, String documentId) {
    final rawWebsite = map['website'] as String? ?? '';
    return BrandModel(
      id: documentId,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      logoUrl: map['logoUrl'] as String? ?? '',
      bannerUrl: map['bannerUrl'] as String? ?? '',
      website: _isValidWebsite(rawWebsite) ? rawWebsite : '',
      country: map['country'] as String? ?? '',
      isFeatured: map['isFeatured'] as bool? ?? false,
      isActive: map['isActive'] as bool? ?? true,
      displayOrder: (map['displayOrder'] as num?)?.toInt() ?? 0,
      createdAt: _timestampToDateTime(map['createdAt']),
      updatedAt: _timestampToDateTime(map['updatedAt']),
    );
  }

  /// Converts this [BrandModel] into a map suitable for writing to
  /// Firestore via `DocumentReference.set()` or `.update()`.
  ///
  /// Note: [id] is intentionally excluded, since the document id is
  /// managed by Firestore itself (as the document path), not stored
  /// as a field within the document.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'bannerUrl': bannerUrl,
      'website': website,
      'country': country,
      'isFeatured': isFeatured,
      'isActive': isActive,
      'displayOrder': displayOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Creates a [BrandModel] from a plain JSON-decoded map (e.g. from a
  /// REST API or a local cache file), as opposed to [fromMap] which
  /// expects Firestore-native types like [Timestamp].
  ///
  /// Dates are expected as ISO-8601 strings. [id] is expected to be
  /// present as a field here (unlike [fromMap]), since JSON has no
  /// document-id concept of its own.
  factory BrandModel.fromJson(Map<String, dynamic> json) {
    final rawWebsite = json['website'] as String? ?? '';
    return BrandModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      logoUrl: json['logoUrl'] as String? ?? '',
      bannerUrl: json['bannerUrl'] as String? ?? '',
      website: _isValidWebsite(rawWebsite) ? rawWebsite : '',
      country: json['country'] as String? ?? '',
      isFeatured: json['isFeatured'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      createdAt: _isoStringToDateTime(json['createdAt']),
      updatedAt: _isoStringToDateTime(json['updatedAt']),
    );
  }

  /// Converts this [BrandModel] into a plain JSON-encodable map,
  /// including [id] (unlike [toMap]) and using ISO-8601 strings for
  /// dates instead of Firestore [Timestamp]s.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'bannerUrl': bannerUrl,
      'website': website,
      'country': country,
      'isFeatured': isFeatured,
      'isActive': isActive,
      'displayOrder': displayOrder,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Returns a new [BrandModel] with the given fields replaced.
  ///
  /// Any field left unspecified keeps its current value, since this
  /// model is immutable and cannot be edited in place. Re-runs the same
  /// validation as the main constructor, so an invalid replacement
  /// value (e.g. a malformed website) is still rejected here.
  BrandModel copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    String? bannerUrl,
    String? website,
    String? country,
    bool? isFeatured,
    bool? isActive,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BrandModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      website: website ?? this.website,
      country: country ?? this.country,
      isFeatured: isFeatured ?? this.isFeatured,
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
    return 'BrandModel(id: $id, name: $name, description: $description, '
        'logoUrl: $logoUrl, bannerUrl: $bannerUrl, website: $website, '
        'country: $country, isFeatured: $isFeatured, isActive: $isActive, '
        'displayOrder: $displayOrder, createdAt: $createdAt, '
        'updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BrandModel &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.logoUrl == logoUrl &&
        other.bannerUrl == bannerUrl &&
        other.website == website &&
        other.country == country &&
        other.isFeatured == isFeatured &&
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
      logoUrl,
      bannerUrl,
      website,
      country,
      isFeatured,
      isActive,
      displayOrder,
      createdAt,
      updatedAt,
    );
  }
}