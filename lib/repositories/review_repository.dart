import 'package:image_picker/image_picker.dart';

import '../services/review_service.dart';

/// Exception wrapper for ReviewRepository failures.
class ReviewRepositoryException implements Exception {
  final String message;
  const ReviewRepositoryException(this.message);

  @override
  String toString() => message;
}

/// Repository abstracting Firestore access for product reviews.
class ReviewRepository {
  final ReviewService _service;

  ReviewRepository({required ReviewService service}) : _service = service;

  /// Exposes a stream of all reviews.
  Stream<List<ReviewModel>> watchAllReviews() {
    return _service.watchAllReviews();
  }

  /// Exposes a stream of approved reviews for a single product (customer-facing).
  Stream<List<ReviewModel>> watchApprovedReviewsForProduct(String productId) {
    return _service.watchApprovedReviewsForProduct(productId);
  }

  /// Exposes a stream of a customer's own reviews across all products.
  Stream<List<ReviewModel>> watchReviewsByUser(String customerId) {
    return _service.watchReviewsByUser(customerId);
  }

  /// Fetches a customer's existing review for a product, if any.
  Future<ReviewModel?> getReviewByCustomerForProduct({
    required String customerId,
    required String productId,
  }) async {
    try {
      return await _service.getReviewByCustomerForProduct(
        customerId: customerId,
        productId: productId,
      );
    } catch (e) {
      throw ReviewRepositoryException(e.toString());
    }
  }

  /// Creates a new review (enters moderation as 'pending').
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
      return await _service.createReview(
        productId: productId,
        productName: productName,
        productImageUrl: productImageUrl,
        customerId: customerId,
        customerName: customerName,
        customerImageUrl: customerImageUrl,
        rating: rating,
        reviewText: reviewText,
        imageUrls: imageUrls,
      );
    } catch (e) {
      throw ReviewRepositoryException(e.toString());
    }
  }

  /// Attaches uploaded image URLs to an existing review.
  Future<void> attachReviewImages(String reviewId, List<String> imageUrls) async {
    try {
      await _service.attachReviewImages(reviewId, imageUrls);
    } catch (e) {
      throw ReviewRepositoryException(e.toString());
    }
  }

  /// Updates a customer's own review (returns it to 'pending' moderation).
  Future<void> updateOwnReview({
    required String reviewId,
    required double rating,
    required String reviewText,
  }) async {
    try {
      await _service.updateOwnReview(reviewId: reviewId, rating: rating, reviewText: reviewText);
    } catch (e) {
      throw ReviewRepositoryException(e.toString());
    }
  }

  /// Approves a review.
  Future<void> approveReview(String reviewId) async {
    try {
      await _service.approveReview(reviewId);
    } catch (e) {
      throw ReviewRepositoryException(e.toString());
    }
  }

  /// Rejects a review.
  Future<void> rejectReview(String reviewId) async {
    try {
      await _service.rejectReview(reviewId);
    } catch (e) {
      throw ReviewRepositoryException(e.toString());
    }
  }

  /// Hides a review.
  Future<void> hideReview(String reviewId) async {
    try {
      await _service.hideReview(reviewId);
    } catch (e) {
      throw ReviewRepositoryException(e.toString());
    }
  }

  /// Unhides a review.
  Future<void> unhideReview(String reviewId) async {
    try {
      await _service.unhideReview(reviewId);
    } catch (e) {
      throw ReviewRepositoryException(e.toString());
    }
  }

  /// Deletes a review permanently.
  Future<void> deleteReview(String reviewId) async {
    try {
      await _service.deleteReview(reviewId);
    } catch (e) {
      throw ReviewRepositoryException(e.toString());
    }
  }

  /// Resolves a reported review.
  Future<void> resolveReport(String reviewId) async {
    try {
      await _service.resolveReport(reviewId);
    } catch (e) {
      throw ReviewRepositoryException(e.toString());
    }
  }

  /// Dismisses a report.
  Future<void> dismissReport(String reviewId) async {
    try {
      await _service.dismissReport(reviewId);
    } catch (e) {
      throw ReviewRepositoryException(e.toString());
    }
  }

  /// Uploads a review image and returns public URL.
  Future<String> uploadReviewImage({
    required String reviewId,
    required XFile imageFile,
  }) async {
    try {
      return await _service.uploadReviewImage(
        reviewId: reviewId,
        imageFile: imageFile,
      );
    } catch (e) {
      throw ReviewRepositoryException(e.toString());
    }
  }
}