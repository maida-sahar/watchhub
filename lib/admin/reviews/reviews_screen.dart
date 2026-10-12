import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_typography.dart';
import '../../config/clay_widgets.dart';
import '../../providers/review_provider.dart';
import '../../services/review_service.dart';
import 'review_analytics_screen.dart';
import 'reported_reviews_screen.dart';
import 'review_details_screen.dart';
import 'widgets/review_filter_dialog.dart';
import 'widgets/review_search_bar.dart';
import 'widgets/moderation_action_dialog.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewProvider>().watchReviews();
    });
  }

  void _openFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ReviewFilterDialog(),
    );
  }

  Future<void> _handleApprove(BuildContext context, ReviewProvider provider, ReviewModel review) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => const ModerationActionDialog(
        title: 'Approve Review',
        content: 'Are you sure you want to approve this review? It will be publicly visible under the product.',
        confirmLabel: 'Approve',
        confirmColor: AppColors.success,
      ),
    );
    if (confirm == true) {
      final success = await provider.approveReview(review.reviewId);
      if (context.mounted) _showSnackBar(context, success, 'Review approved successfully.', provider.moderationError);
    }
  }

  Future<void> _handleReject(BuildContext context, ReviewProvider provider, ReviewModel review) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => const ModerationActionDialog(
        title: 'Reject Review',
        content: 'Are you sure you want to reject this review? It will be marked as rejected and hidden.',
        confirmLabel: 'Reject',
        confirmColor: AppColors.error,
      ),
    );
    if (confirm == true) {
      final success = await provider.rejectReview(review.reviewId);
      if (context.mounted) _showSnackBar(context, success, 'Review rejected successfully.', provider.moderationError);
    }
  }

  Future<void> _handleHide(BuildContext context, ReviewProvider provider, ReviewModel review) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => const ModerationActionDialog(
        title: 'Hide Review',
        content: 'Are you sure you want to hide this review from public visibility?',
        confirmLabel: 'Hide',
        confirmColor: Colors.blueGrey,
      ),
    );
    if (confirm == true) {
      final success = await provider.hideReview(review.reviewId);
      if (context.mounted) _showSnackBar(context, success, 'Review hidden successfully.', provider.moderationError);
    }
  }

  Future<void> _handleDelete(BuildContext context, ReviewProvider provider, ReviewModel review) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => const ModerationActionDialog(
        title: 'Delete Review',
        content: 'Are you sure you want to permanently delete this review? This action cannot be undone.',
        confirmLabel: 'Delete',
        confirmColor: AppColors.error,
      ),
    );
    if (confirm == true) {
      final success = await provider.deleteReview(review.reviewId);
      if (context.mounted) _showSnackBar(context, success, 'Review deleted permanently.', provider.moderationError);
    }
  }

  void _showSnackBar(BuildContext context, bool success, String message, String? error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? message : (error ?? 'Action failed.')),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Reviews Management',
          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.report_problem_rounded, color: AppColors.error),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportedReviewsScreen()),
              );
            },
            tooltip: 'Reported Reviews',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: AppColors.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReviewAnalyticsScreen()),
              );
            },
            tooltip: 'Reviews Reports',
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<ReviewProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.reviews.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage != null && provider.reviews.isEmpty) {
              return _buildErrorState(provider.errorMessage!);
            }

            final list = provider.filteredReviews;

            return Column(
              children: [
                // Search & Filter header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      const Expanded(child: ReviewSearchBar()),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _openFilterDialog,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadow.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: provider.statusFilter != 'all' ||
                                      provider.ratingFilter != null ||
                                      provider.dateFilter != 'all'
                                  ? AppColors.primary.withOpacity(0.4)
                                  : AppColors.border.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.filter_list_rounded,
                            color: provider.statusFilter != 'all' ||
                                    provider.ratingFilter != null ||
                                    provider.dateFilter != 'all'
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Active Filter Chips
                if (provider.statusFilter != 'all' ||
                    provider.ratingFilter != null ||
                    provider.dateFilter != 'all')
                  _buildFilterChipsRow(provider),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      provider.stopWatching();
                      provider.watchReviews();
                    },
                    color: AppColors.primary,
                    child: list.isEmpty
                        ? _buildEmptyState(provider)
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              final review = list[index];
                              return _reviewItemCard(context, provider, review);
                            },
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChipsRow(ReviewProvider provider) {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (provider.statusFilter != 'all')
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: InputChip(
                label: Text('Status: ${provider.statusFilter.toUpperCase()}'),
                onDeleted: () => provider.setStatusFilter('all'),
                deleteIconColor: AppColors.primary,
                backgroundColor: AppColors.primary.withOpacity(0.08),
                side: BorderSide(color: AppColors.primary.withOpacity(0.12)),
                labelStyle: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          if (provider.ratingFilter != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: InputChip(
                label: Text('Rating: ${provider.ratingFilter} Star'),
                onDeleted: () => provider.setRatingFilter(null),
                deleteIconColor: AppColors.primary,
                backgroundColor: AppColors.primary.withOpacity(0.08),
                side: BorderSide(color: AppColors.primary.withOpacity(0.12)),
                labelStyle: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          if (provider.dateFilter != 'all')
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: InputChip(
                label: Text('Date: ${provider.dateFilter.toUpperCase()}'),
                onDeleted: () => provider.setDateFilter('all'),
                deleteIconColor: AppColors.primary,
                backgroundColor: AppColors.primary.withOpacity(0.08),
                side: BorderSide(color: AppColors.primary.withOpacity(0.12)),
                labelStyle: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ActionChip(
            label: const Text('Clear All'),
            onPressed: provider.resetFilters,
            backgroundColor: AppColors.background,
            side: const BorderSide(color: AppColors.border),
            labelStyle: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _reviewItemCard(BuildContext context, ReviewProvider provider, ReviewModel review) {
    final dateStr = DateFormat('MMM dd, yyyy').format(review.createdAt);
    final statusColor = _getStatusColor(review.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ClayCard(
        borderRadius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    review.productName,
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.2), width: 0.5),
                  ),
                  child: Text(
                    review.status.toUpperCase(),
                    style: AppTypography.bodySmall.copyWith(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'By: ${review.customerName} on $dateStr',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                      color: Colors.amber,
                      size: 14,
                    );
                  }),
                ),
              ],
            ),
            const Divider(height: 20, color: AppColors.divider),
            Text(
              '"${review.reviewText}"',
              style: AppTypography.bodyMedium.copyWith(fontStyle: FontStyle.italic),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (review.isReported) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.report_problem_rounded, color: AppColors.error, size: 12),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Reported: ${review.reportReason}',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReviewDetailsScreen(review: review),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: Row(
                    children: [
                      Text(
                        'Moderation Details',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 14),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (review.status != 'approved')
                      IconButton(
                        icon: const Icon(Icons.check_rounded, color: AppColors.success, size: 20),
                        tooltip: 'Approve',
                        onPressed: () => _handleApprove(context, provider, review),
                      ),
                    if (review.status != 'rejected')
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.error, size: 20),
                        tooltip: 'Reject',
                        onPressed: () => _handleReject(context, provider, review),
                      ),
                    if (review.status != 'hidden' && review.status == 'approved')
                      IconButton(
                        icon: const Icon(Icons.visibility_off_rounded, color: Colors.blueGrey, size: 20),
                        tooltip: 'Hide',
                        onPressed: () => _handleHide(context, provider, review),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                      tooltip: 'Delete Permanently',
                      onPressed: () => _handleDelete(context, provider, review),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'pending':
        return Colors.amber[800] ?? Colors.amber;
      case 'hidden':
        return Colors.blueGrey;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildEmptyState(ReviewProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.rate_review_outlined, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'No reviews found',
            style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            provider.searchQuery.isNotEmpty || provider.statusFilter != 'all'
                ? 'Try resetting the filters or widening search keywords.'
                : 'Customer feedback submitted for products will show here.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Failed to load reviews', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
