import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/review_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../models/product_model.dart';
import '../../../services/review_service.dart' show ReviewModel;

/// Reviews & Ratings section for the Product Details screen.
///
/// Reuses the existing [ReviewProvider] (the same one the Admin Reviews
/// module already moderates through) — no new provider/repository/service.
/// Gates "Write a Review" on the customer having actually purchased the
/// product, using [OrderProvider.hasPurchased], and lets a customer edit or
/// delete their own review afterward.
class ProductReviewsSection extends StatefulWidget {
  final ProductModel product;

  const ProductReviewsSection({super.key, required this.product});

  @override
  State<ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends State<ProductReviewsSection> {
  ReviewModel? _myReview;
  bool _checkedMyReview = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    if (!mounted) return;
    final reviewProvider = context.read<ReviewProvider>();
    reviewProvider.watchProductReviews(widget.product.id);

    final uid = context.read<AuthProvider>().currentUid;
    if (uid != null && uid.isNotEmpty) {
      // hasPurchased() reads from OrderProvider's already-loaded orders —
      // make sure that list is actually populated for this user.
      context.read<OrderProvider>().watchUserOrders(uid);
      final mine = await reviewProvider.getMyReviewForProduct(
        customerId: uid,
        productId: widget.product.id,
      );
      if (mounted) {
        setState(() {
          _myReview = mine;
          _checkedMyReview = true;
        });
      }
    } else {
      setState(() => _checkedMyReview = true);
    }
  }

  void _openReviewForm({ReviewModel? existing}) {
    final uid = context.read<AuthProvider>().currentUid;
    if (uid == null || uid.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewFormSheet(
        product: widget.product,
        existing: existing,
        onSubmitted: (review) {
          setState(() => _myReview = review);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reviewProvider = context.watch<ReviewProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final uid = context.watch<AuthProvider>().currentUid;

    final reviews = reviewProvider.reviewsForProduct(widget.product.id);
    final isLoading = reviewProvider.isLoadingReviewsForProduct(widget.product.id);
    final hasPurchased = uid != null && orderProvider.hasPurchased(widget.product.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reviews & Ratings',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (reviews.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.product.averageRating.toStringAsFixed(1)} (${widget.product.totalReviews})',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),

          // --- Write / Edit / Purchase-gate CTA ---
          if (!_checkedMyReview)
            const SizedBox.shrink()
          else if (uid == null || uid.isEmpty)
            Text(
              'Log in to write a review.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            )
          else if (_myReview != null)
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openReviewForm(existing: _myReview),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit your review'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete review?'),
                        content: const Text('This cannot be undone.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await context.read<ReviewProvider>().deleteMyReview(_myReview!.reviewId);
                      if (mounted) setState(() => _myReview = null);
                    }
                  },
                  child: const Text('Delete'),
                ),
              ],
            )
          else if (hasPurchased)
            ElevatedButton.icon(
              onPressed: () => _openReviewForm(),
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: const Text('Write a Review'),
            )
          else
            Text(
              'Purchase this product to write a review.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),

          const SizedBox(height: 16),

          // --- Review list ---
          if (isLoading && reviews.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(strokeWidth: 2),
            ))
          else if (reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No reviews yet. Be the first to share your thoughts!',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            )
          else
            ...reviews.map((r) => _ReviewTile(review: r)),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ReviewModel review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: review.customerImageUrl.isNotEmpty
                    ? CachedNetworkImageProvider(review.customerImageUrl)
                    : null,
                child: review.customerImageUrl.isEmpty
                    ? Text(review.customerName.isNotEmpty ? review.customerName[0].toUpperCase() : '?')
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < review.rating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                          size: 14,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(review.reviewText, style: theme.textTheme.bodyMedium),
          if (review.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.imageUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: review.imageUrls[i],
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bottom sheet form for writing or editing a review.
class _ReviewFormSheet extends StatefulWidget {
  final ProductModel product;
  final ReviewModel? existing;
  final ValueChanged<ReviewModel> onSubmitted;

  const _ReviewFormSheet({required this.product, this.existing, required this.onSubmitted});

  @override
  State<_ReviewFormSheet> createState() => _ReviewFormSheetState();
}

class _ReviewFormSheetState extends State<_ReviewFormSheet> {
  late double _rating;
  late final TextEditingController _textController;
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.existing?.rating ?? 5.0;
    _textController = TextEditingController(text: widget.existing?.reviewText ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() => _images.addAll(picked.take(3 - _images.length)));
    }
  }

  Future<void> _submit() async {
    if (_textController.text.trim().isEmpty) return;
    setState(() => _submitting = true);

    final reviewProvider = context.read<ReviewProvider>();
    final uid = context.read<AuthProvider>().currentUid ?? '';
    final settings = context.read<SettingsProvider>().settings;
    final customerName = settings?.profile.name.isNotEmpty == true ? settings!.profile.name : 'Customer';
    final customerImageUrl = settings?.profile.photoUrl ?? '';

    bool success;
    if (widget.existing != null) {
      success = await reviewProvider.editMyReview(
        reviewId: widget.existing!.reviewId,
        rating: _rating,
        reviewText: _textController.text.trim(),
      );
    } else {
      success = await reviewProvider.submitReview(
        productId: widget.product.id,
        productName: widget.product.name,
        productImageUrl: widget.product.thumbnail,
        customerId: uid,
        customerName: customerName,
        customerImageUrl: customerImageUrl,
        rating: _rating,
        reviewText: _textController.text.trim(),
        imageFiles: _images,
      );
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted — it will appear once approved.')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(reviewProvider.submitReviewError ?? 'Could not submit review.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing != null ? 'Edit your review' : 'Write a review',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starValue = i + 1;
                return IconButton(
                  onPressed: () => setState(() => _rating = starValue.toDouble()),
                  icon: Icon(
                    starValue <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 32,
                  ),
                );
              }),
            ),
            TextField(
              controller: _textController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Share your experience with this product...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (_images.isNotEmpty)
                  ..._images.map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(Icons.image, color: Colors.grey.shade400),
                      )),
                TextButton.icon(
                  onPressed: _images.length >= 3 ? null : _pickImages,
                  icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                  label: Text(_images.isEmpty ? 'Add photos (optional)' : '${_images.length}/3 added'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(widget.existing != null ? 'Update Review' : 'Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}