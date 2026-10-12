import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../services/review_service.dart';
import '../repositories/review_repository.dart';

/// Provider managing reviews query configurations, statistics, and moderation state.
class ReviewProvider extends ChangeNotifier {
  final ReviewRepository repository;

  List<ReviewModel> _reviews = [];
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<ReviewModel>>? _subscription;
  bool _isWatching = false;

  // --- Moderation Status ---
  bool _isModerating = false;
  String? _moderationError;

  // --- Search & Filter Query States ---
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'approved', 'pending', 'hidden', 'rejected', 'reported'
  int? _ratingFilter; // 1 to 5, null means all
  String _dateFilter = 'all'; // 'all', 'today', 'week', 'month', 'custom'
  DateTimeRange? _customDateRange;

  ReviewProvider({required this.repository});

  List<ReviewModel> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isModerating => _isModerating;
  String? get moderationError => _moderationError;

  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  int? get ratingFilter => _ratingFilter;
  String get dateFilter => _dateFilter;
  DateTimeRange? get customDateRange => _customDateRange;

  /// Starts listening to real-time reviews stream.
  void watchReviews() {
    if (_isWatching) return;
    _isWatching = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription?.cancel();
    _subscription = repository.watchAllReviews().listen(
      (data) {
        _reviews = data;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = 'Failed to load reviews: $error';
        _isWatching = false;
        notifyListeners();
      },
    );
  }

  /// Stops streaming reviews.
  void stopWatching() {
    _isWatching = false;
    _subscription?.cancel();
    _subscription = null;
  }

  // =========================================================
  // SEARCH & FILTER SETTERS
  // =========================================================

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setRatingFilter(int? rating) {
    _ratingFilter = rating;
    notifyListeners();
  }

  void setDateFilter(String filter) {
    _dateFilter = filter;
    notifyListeners();
  }

  void setCustomDateRange(DateTimeRange? range) {
    _customDateRange = range;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _statusFilter = 'all';
    _ratingFilter = null;
    _dateFilter = 'all';
    _customDateRange = null;
    notifyListeners();
  }

  // =========================================================
  // REACTIVE GETTERS (FILTERED LISTS)
  // =========================================================

  List<ReviewModel> get filteredReviews {
    List<ReviewModel> list = List.from(_reviews);

    // 1. Search Query
    if (_searchQuery.isNotEmpty) {
      list = list.where((r) {
        final idMatches = r.reviewId.toLowerCase().contains(_searchQuery);
        final productMatches = r.productName.toLowerCase().contains(_searchQuery);
        final customerMatches = r.customerName.toLowerCase().contains(_searchQuery);
        final textMatches = r.reviewText.toLowerCase().contains(_searchQuery);
        return idMatches || productMatches || customerMatches || textMatches;
      }).toList();
    }

    // 2. Status Filter
    if (_statusFilter != 'all') {
      if (_statusFilter == 'reported') {
        list = list.where((r) => r.isReported).toList();
      } else {
        list = list.where((r) => r.status == _statusFilter).toList();
      }
    }

    // 3. Rating Filter
    if (_ratingFilter != null) {
      // Allow +/- 0.5 ratings to group inside stars if stored as double
      list = list.where((r) => r.rating.round() == _ratingFilter).toList();
    }

    // 4. Date Filter
    if (_dateFilter != 'all') {
      final now = DateTime.now();
      switch (_dateFilter) {
        case 'today':
          final todayStart = DateTime(now.year, now.month, now.day);
          list = list.where((r) => r.createdAt.isAfter(todayStart)).toList();
          break;
        case 'week':
          final weekStart = now.subtract(const Duration(days: 7));
          list = list.where((r) => r.createdAt.isAfter(weekStart)).toList();
          break;
        case 'month':
          final monthStart = now.subtract(const Duration(days: 30));
          list = list.where((r) => r.createdAt.isAfter(monthStart)).toList();
          break;
        case 'custom':
          if (_customDateRange != null) {
            final start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day, 0, 0, 0);
            final end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
            list = list.where((r) => r.createdAt.isAfter(start) && r.createdAt.isBefore(end)).toList();
          }
          break;
      }
    }

    // Sort: Newest first
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  /// Get specifically flagged/reported reviews
  List<ReviewModel> get reportedReviews {
    return List.unmodifiable(_reviews.where((r) => r.isReported));
  }

  // =========================================================
  // ANALYTICS CALCULATIONS
  // =========================================================

  int get totalReviewsCount => _reviews.length;
  int get approvedCount => _reviews.where((r) => r.status == 'approved').length;
  int get pendingCount => _reviews.where((r) => r.status == 'pending').length;
  int get hiddenCount => _reviews.where((r) => r.status == 'hidden').length;
  int get rejectedCount => _reviews.where((r) => r.status == 'rejected').length;
  int get reportedCount => _reviews.where((r) => r.isReported).length;

  double get averageRating {
    final validReviews = _reviews.where((r) => r.status != 'rejected');
    if (validReviews.isEmpty) return 0.0;
    final totalStars = validReviews.fold<double>(0.0, (sum, r) => sum + r.rating);
    return totalStars / validReviews.length;
  }

  Map<int, int> get ratingDistribution {
    final Map<int, int> dist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in _reviews) {
      if (r.status != 'rejected') {
        final rounded = r.rating.round();
        if (dist.containsKey(rounded)) {
          dist[rounded] = dist[rounded]! + 1;
        }
      }
    }
    return dist;
  }

  List<MapEntry<String, int>> get mostReviewedProducts {
    final Map<String, int> counts = {};
    for (final r in _reviews) {
      counts[r.productName] = (counts[r.productName] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList();
  }

  List<MapEntry<String, int>> get mostActiveCustomers {
    final Map<String, int> counts = {};
    for (final r in _reviews) {
      counts[r.customerName] = (counts[r.customerName] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList();
  }

  List<ReviewModel> get recentReviews {
    final list = List<ReviewModel>.from(_reviews)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.take(5).toList();
  }

  // =========================================================
  // MODERATION ACTIONS (ASYNC OPERATION)
  // =========================================================

  Future<bool> _executeAction(Future<void> action) async {
    _isModerating = true;
    _moderationError = null;
    notifyListeners();

    try {
      await action;
      _isModerating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isModerating = false;
      _moderationError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> approveReview(String reviewId) {
    return _executeAction(repository.approveReview(reviewId));
  }

  Future<bool> rejectReview(String reviewId) {
    return _executeAction(repository.rejectReview(reviewId));
  }

  Future<bool> hideReview(String reviewId) {
    return _executeAction(repository.hideReview(reviewId));
  }

  Future<bool> unhideReview(String reviewId) {
    return _executeAction(repository.unhideReview(reviewId));
  }

  Future<bool> deleteReview(String reviewId) {
    return _executeAction(repository.deleteReview(reviewId));
  }

  Future<bool> resolveReport(String reviewId) {
    return _executeAction(repository.resolveReport(reviewId));
  }

  Future<bool> dismissReport(String reviewId) {
    return _executeAction(repository.dismissReport(reviewId));
  }

  // =========================================================
  // REVIEW IMAGE ACTIONS
  // =========================================================

  bool _isUploadingReviewImage = false;
  String? _reviewImageError;

  bool get isUploadingReviewImage => _isUploadingReviewImage;
  String? get reviewImageError => _reviewImageError;

  Future<String?> uploadReviewImage({
    required String reviewId,
    required XFile imageFile,
  }) async {
    _isUploadingReviewImage = true;
    _reviewImageError = null;
    notifyListeners();

    try {
      final url = await repository.uploadReviewImage(
        reviewId: reviewId,
        imageFile: imageFile,
      );
      _isUploadingReviewImage = false;
      notifyListeners();
      return url;
    } catch (e) {
      _isUploadingReviewImage = false;
      _reviewImageError = e.toString();
      notifyListeners();
      return null;
    }
  }

  // =========================================================
  // CUSTOMER-FACING REVIEW ACTIONS (Phase 12 — write path)
  // =========================================================

  final Map<String, List<ReviewModel>> _productReviews = {};
  final Map<String, StreamSubscription<List<ReviewModel>>> _productSubscriptions = {};
  final Map<String, bool> _productReviewsLoading = {};

  bool _isSubmittingReview = false;
  String? _submitReviewError;

  bool get isSubmittingReview => _isSubmittingReview;
  String? get submitReviewError => _submitReviewError;

  /// Approved reviews for [productId], populated once [watchProductReviews]
  /// has been called for that product at least once.
  List<ReviewModel> reviewsForProduct(String productId) =>
      _productReviews[productId] ?? const [];

  bool isLoadingReviewsForProduct(String productId) =>
      _productReviewsLoading[productId] ?? false;

  /// Starts (or reuses) a live subscription to a product's approved reviews
  /// — call this from the Product Details screen's initState.
  void watchProductReviews(String productId) {
    if (_productSubscriptions.containsKey(productId)) return;
    _productReviewsLoading[productId] = true;
    notifyListeners();

    _productSubscriptions[productId] =
        repository.watchApprovedReviewsForProduct(productId).listen(
      (data) {
        _productReviews[productId] = data;
        _productReviewsLoading[productId] = false;
        notifyListeners();
      },
      onError: (_) {
        _productReviewsLoading[productId] = false;
        notifyListeners();
      },
    );
  }

  /// Checks whether the current customer already reviewed this product, so
  /// the UI can offer "Edit your review" instead of "Write a Review".
  Future<ReviewModel?> getMyReviewForProduct({
    required String customerId,
    required String productId,
  }) {
    return repository.getReviewByCustomerForProduct(
      customerId: customerId,
      productId: productId,
    );
  }

  /// Submits a new review, optionally uploading photos first. Returns true
  /// on success. The review starts as 'pending' and enters the existing
  /// admin moderation queue — it will not appear in [reviewsForProduct]
  /// until an admin approves it.
  Future<bool> submitReview({
    required String productId,
    required String productName,
    required String productImageUrl,
    required String customerId,
    required String customerName,
    required String customerImageUrl,
    required double rating,
    required String reviewText,
    List<XFile> imageFiles = const [],
  }) async {
    _isSubmittingReview = true;
    _submitReviewError = null;
    notifyListeners();

    try {
      final reviewId = await repository.createReview(
        productId: productId,
        productName: productName,
        productImageUrl: productImageUrl,
        customerId: customerId,
        customerName: customerName,
        customerImageUrl: customerImageUrl,
        rating: rating,
        reviewText: reviewText,
      );

      if (imageFiles.isNotEmpty) {
        final urls = <String>[];
        for (final file in imageFiles) {
          final url = await repository.uploadReviewImage(reviewId: reviewId, imageFile: file);
          urls.add(url);
        }
        await repository.attachReviewImages(reviewId, urls);
      }

      _isSubmittingReview = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmittingReview = false;
      _submitReviewError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Edits the customer's own existing review. Returns it to 'pending'
  /// moderation, same as a fresh submission.
  Future<bool> editMyReview({
    required String reviewId,
    required double rating,
    required String reviewText,
  }) async {
    _isSubmittingReview = true;
    _submitReviewError = null;
    notifyListeners();

    try {
      await repository.updateOwnReview(reviewId: reviewId, rating: rating, reviewText: reviewText);
      _isSubmittingReview = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmittingReview = false;
      _submitReviewError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Deletes the customer's own review (reuses the same delete path admin
  /// moderation uses — Firestore doesn't distinguish who deletes it).
  Future<bool> deleteMyReview(String reviewId) {
    return _executeAction(repository.deleteReview(reviewId));
  }

  @override
  void dispose() {
    for (final sub in _productSubscriptions.values) {
      sub.cancel();
    }
    stopWatching();
    super.dispose();
  }
}