import 'package:image_picker/image_picker.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'storage_service.dart';

/// Representation of a product review document.
class ReviewModel {
  final String reviewId;
  final String productId;
  final String productName;
  final String productImageUrl;
  final String customerId;
  final String customerName;
  final String customerImageUrl;
  final double rating;
  final String reviewText;
  final String status; // 'pending', 'approved', 'rejected', 'hidden'
  final List<String> imageUrls;
  final bool isReported;
  final String reportReason;
  final DateTime? reportDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReviewModel({
    required this.reviewId,
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.customerId,
    required this.customerName,
    required this.customerImageUrl,
    required this.rating,
    required this.reviewText,
    required this.status,
    this.imageUrls = const [],
    required this.isReported,
    this.reportReason = '',
    this.reportDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      reviewId: id,
      productId: (map['productId'] as String?) ?? '',
      productName: (map['productName'] as String?) ?? '',
      productImageUrl: (map['productImageUrl'] as String?) ?? '',
      customerId: (map['customerId'] as String?) ?? '',
      customerName: (map['customerName'] as String?) ?? '',
      customerImageUrl: (map['customerImageUrl'] as String?) ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      reviewText: (map['reviewText'] as String?) ?? '',
      status: (map['status'] as String?) ?? 'pending',
      imageUrls: (map['imageUrls'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      isReported: (map['isReported'] as bool?) ?? false,
      reportReason: (map['reportReason'] as String?) ?? '',
      reportDate: map['reportDate'] != null ? _timestampToDate(map['reportDate']) : null,
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
      'productId': productId,
      'productName': productName,
      'productImageUrl': productImageUrl,
      'customerId': customerId,
      'customerName': customerName,
      'customerImageUrl': customerImageUrl,
      'rating': rating,
      'reviewText': reviewText,
      'status': status,
      'imageUrls': imageUrls,
      'isReported': isReported,
      'reportReason': reportReason,
      'reportDate': reportDate != null ? Timestamp.fromDate(reportDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ReviewModel copyWith({
    String? status,
    List<String>? imageUrls,
    bool? isReported,
    String? reportReason,
    DateTime? reportDate,
    DateTime? updatedAt,
  }) {
    return ReviewModel(
      reviewId: reviewId,
      productId: productId,
      productName: productName,
      productImageUrl: productImageUrl,
      customerId: customerId,
      customerName: customerName,
      customerImageUrl: customerImageUrl,
      rating: rating,
      reviewText: reviewText,
      status: status ?? this.status,
      imageUrls: imageUrls ?? this.imageUrls,
      isReported: isReported ?? this.isReported,
      reportReason: reportReason ?? this.reportReason,
      reportDate: reportDate ?? this.reportDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

/// Custom Exception wrapper for ReviewService
class ReviewServiceException implements Exception {
  final String message;
  final String? code;
  const ReviewServiceException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Service handling Firestore access for product reviews.
class ReviewService {
  final FirebaseFirestore _firestore;
  final StorageService _storage;

  static const String _reviewsCollection = 'reviews';

  ReviewService({FirebaseFirestore? firestore, StorageService? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? StorageService();

  CollectionReference<Map<String, dynamic>> get _reviewsRef =>
      _firestore.collection(_reviewsCollection);

  /// Streams all reviews in real-time.
  Stream<List<ReviewModel>> watchAllReviews() {
    return _reviewsRef.snapshots().map((snapshot) {
      final List<ReviewModel> reviews = [];
      for (final doc in snapshot.docs) {
        try {
          reviews.add(ReviewModel.fromMap(doc.data(), doc.id));
        } catch (_) {
          // Skip invalid documents
        }
      }
      return reviews;
    });
  }

  /// Streams only the approved, non-hidden reviews for a single product —
  /// this is what a customer sees on the Product Details screen. Reviews
  /// that are still pending moderation, rejected, or hidden are excluded.
  ///
  /// Sorted client-side (by createdAt, most recent first) instead of via
  /// Firestore `.orderBy()` to avoid requiring a new composite index for
  /// `productId == X` + `status == 'approved'` + `orderBy(createdAt)`.
  Stream<List<ReviewModel>> watchApprovedReviewsForProduct(String productId) {
    return _reviewsRef
        .where('productId', isEqualTo: productId)
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) {
      final List<ReviewModel> reviews = [];
      for (final doc in snapshot.docs) {
        try {
          reviews.add(ReviewModel.fromMap(doc.data(), doc.id));
        } catch (_) {
          // Skip invalid documents
        }
      }
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reviews;
    });
  }

  /// Streams every review a specific customer has written, across all
  /// products — used for "My Reviews" on the customer's profile so they
  /// can see/edit/delete their own submissions regardless of moderation
  /// status.
  Stream<List<ReviewModel>> watchReviewsByUser(String customerId) {
    return _reviewsRef
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
      final List<ReviewModel> reviews = [];
      for (final doc in snapshot.docs) {
        try {
          reviews.add(ReviewModel.fromMap(doc.data(), doc.id));
        } catch (_) {
          // Skip invalid documents
        }
      }
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reviews;
    });
  }

  /// Returns the customer's existing review for [productId], if any — used
  /// to decide whether the UI should show "Write a Review" or "Edit your
  /// review" (one review per product per customer).
  Future<ReviewModel?> getReviewByCustomerForProduct({
    required String customerId,
    required String productId,
  }) async {
    try {
      final snapshot = await _reviewsRef
          .where('productId', isEqualTo: productId)
          .where('customerId', isEqualTo: customerId)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return ReviewModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
    } on FirebaseException catch (e) {
      throw ReviewServiceException(e.message ?? 'Firestore query failed', code: e.code);
    } catch (e) {
      throw ReviewServiceException('An unexpected error occurred: $e');
    }
  }

  /// Creates a new review, defaulting to `status: 'pending'` so it enters
  /// the existing admin moderation queue before becoming publicly visible
  /// (matching the moderation actions — approve/reject/hide — that already
  /// exist on this service).
  Future<String> createReview({
    required String productId,
    required String productName,
    required String productImageUrl,
    required String customerId,
    required String customerName,
    required String customerImageUrl,
    required double rating,
    required String reviewText,
    List<String> imageUrls = const [],
  }) async {
    try {
      final now = DateTime.now();
      final docRef = await _reviewsRef.add({
        'productId': productId,
        'productName': productName,
        'productImageUrl': productImageUrl,
        'customerId': customerId,
        'customerName': customerName,
        'customerImageUrl': customerImageUrl,
        'rating': rating,
        'reviewText': reviewText,
        'status': 'pending',
        'imageUrls': imageUrls,
        'isReported': false,
        'reportReason': '',
        'reportDate': null,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });
      return docRef.id;
    } on FirebaseException catch (e) {
      throw ReviewServiceException(e.message ?? 'Firestore write failed', code: e.code);
    } catch (e) {
      throw ReviewServiceException('An unexpected error occurred: $e');
    }
  }

  /// Attaches uploaded image URLs to an existing review (used right after
  /// [createReview], once we have a reviewId to upload against).
  Future<void> attachReviewImages(String reviewId, List<String> imageUrls) async {
    await _updateReviewFields(reviewId, {'imageUrls': imageUrls});
  }

  /// Lets a customer edit their own review's rating/text. The review
  /// returns to `pending` so the updated content re-enters moderation,
  /// same as a freshly submitted review.
  Future<void> updateOwnReview({
    required String reviewId,
    required double rating,
    required String reviewText,
  }) async {
    await _updateReviewFields(reviewId, {
      'rating': rating,
      'reviewText': reviewText,
      'status': 'pending',
    });
    final productId = await _productIdForReview(reviewId);
    if (productId != null) await _recalculateProductRating(productId);
  }

  Future<String?> _productIdForReview(String reviewId) async {
    try {
      final doc = await _reviewsRef.doc(reviewId).get();
      return doc.data()?['productId'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Recomputes a product's `averageRating`/`totalReviews` fields from its
  /// currently-approved reviews. Only approved reviews count, so a flood of
  /// unmoderated or rejected submissions can never skew the public rating.
  Future<void> _recalculateProductRating(String productId) async {
    try {
      final snapshot = await _reviewsRef
          .where('productId', isEqualTo: productId)
          .where('status', isEqualTo: 'approved')
          .get();
      final ratings = snapshot.docs
          .map((d) => (d.data()['rating'] as num?)?.toDouble() ?? 0.0)
          .toList();
      final total = ratings.length;
      final average = total == 0 ? 0.0 : ratings.reduce((a, b) => a + b) / total;
      await _firestore.collection('products').doc(productId).update({
        'averageRating': double.parse(average.toStringAsFixed(2)),
        'totalReviews': total,
      });
    } catch (_) {
      // Best-effort: if the product doc doesn't exist or the write fails,
      // the review action itself has already succeeded — don't surface a
      // secondary rating-sync failure as if the primary action failed.
    }
  }

  /// Helper to update a review document status / flag fields
  Future<void> _updateReviewFields(String reviewId, Map<String, dynamic> fields) async {
    try {
      await _reviewsRef.doc(reviewId).update({
        ...fields,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on FirebaseException catch (e) {
      throw ReviewServiceException(e.message ?? 'Firestore operation failed', code: e.code);
    } catch (e) {
      throw ReviewServiceException('An unexpected error occurred: $e');
    }
  }

  /// Approves a pending/reported review, confirming its visibility.
  Future<void> approveReview(String reviewId) async {
    await _updateReviewFields(reviewId, {
      'status': 'approved',
      'isReported': false,
      'reportReason': '',
      'reportDate': null,
    });
    final productId = await _productIdForReview(reviewId);
    if (productId != null) await _recalculateProductRating(productId);
  }

  /// Rejects a review.
  Future<void> rejectReview(String reviewId) async {
    final productId = await _productIdForReview(reviewId);
    await _updateReviewFields(reviewId, {
      'status': 'rejected',
    });
    if (productId != null) await _recalculateProductRating(productId);
  }

  /// Hides a review from public visibility.
  Future<void> hideReview(String reviewId) async {
    final productId = await _productIdForReview(reviewId);
    await _updateReviewFields(reviewId, {
      'status': 'hidden',
    });
    if (productId != null) await _recalculateProductRating(productId);
  }

  /// Restores visibility of a hidden review to approved.
  Future<void> unhideReview(String reviewId) async {
    await _updateReviewFields(reviewId, {
      'status': 'approved',
    });
    final productId = await _productIdForReview(reviewId);
    if (productId != null) await _recalculateProductRating(productId);
  }

  /// Deletes a review document permanently.
  Future<void> deleteReview(String reviewId) async {
    final productId = await _productIdForReview(reviewId);
    try {
      await _reviewsRef.doc(reviewId).delete();
    } on FirebaseException catch (e) {
      throw ReviewServiceException(e.message ?? 'Firestore delete failed', code: e.code);
    } catch (e) {
      throw ReviewServiceException('An unexpected error occurred: $e');
    }
    if (productId != null) await _recalculateProductRating(productId);
  }

  /// Resolves a report, marking isReported = false and keeping it approved.
  Future<void> resolveReport(String reviewId) async {
    await _updateReviewFields(reviewId, {
      'isReported': false,
      'status': 'approved',
    });
    final productId = await _productIdForReview(reviewId);
    if (productId != null) await _recalculateProductRating(productId);
  }

  /// Dismisses a report, clearing reasons and flagged state, resetting to pending/approved.
  Future<void> dismissReport(String reviewId) async {
    await _updateReviewFields(reviewId, {
      'isReported': false,
      'reportReason': '',
      'reportDate': null,
    });
  }

  /// Uploads review image to Supabase Storage and returns public URL.
  Future<String> uploadReviewImage({
    required String reviewId,
    required XFile imageFile,
  }) async {
    if (reviewId.trim().isEmpty) {
      throw const ReviewServiceException('Review ID is required to upload review image.');
    }
    try {
      if (await imageFile.length() == 0) {
        throw const ReviewServiceException('Image file is empty.');
      }
    } catch (e) {
      throw const ReviewServiceException('Image file does not exist.');
    }

    try {
      final uniqueName = _storage.generateUniqueFileName(imageFile);
      final path = 'reviews/$uniqueName';
      return await _storage.uploadImage(file: imageFile, path: path);
    } on StorageServiceException catch (e) {
      throw ReviewServiceException('Storage error: ${e.message}');
    } catch (e) {
      throw ReviewServiceException('An unexpected error occurred: $e');
    }
  }
}