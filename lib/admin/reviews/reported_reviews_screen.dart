import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_typography.dart';
import '../../providers/review_provider.dart';
import '../../services/review_service.dart';
import 'review_details_screen.dart';
import 'widgets/reported_review_card.dart';
import 'widgets/moderation_action_dialog.dart';

class ReportedReviewsScreen extends StatelessWidget {
  const ReportedReviewsScreen({super.key});

  Future<void> _handleApprove(BuildContext context, ReviewProvider provider, ReviewModel review) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => const ModerationActionDialog(
        title: 'Approve & Clear Report',
        content: 'Are you sure you want to approve this review and resolve the abuse report? The review will remain publicly visible.',
        confirmLabel: 'Approve',
        confirmColor: AppColors.success,
      ),
    );
    if (confirm == true) {
      final success = await provider.resolveReport(review.reviewId);
      if (context.mounted) _showSnackBar(context, success, 'Report resolved. Review is now active.', provider.moderationError);
    }
  }

  Future<void> _handleReject(BuildContext context, ReviewProvider provider, ReviewModel review) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => const ModerationActionDialog(
        title: 'Reject & Hide Review',
        content: 'Are you sure you want to reject this review? It will be hidden and marked as rejected.',
        confirmLabel: 'Reject',
        confirmColor: AppColors.error,
      ),
    );
    if (confirm == true) {
      final success = await provider.rejectReview(review.reviewId);
      if (context.mounted) _showSnackBar(context, success, 'Review rejected and hidden.', provider.moderationError);
    }
  }

  Future<void> _handleDismissFlag(BuildContext context, ReviewProvider provider, ReviewModel review) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => const ModerationActionDialog(
        title: 'Dismiss Abuse Report',
        content: 'Are you sure you want to dismiss the report flag? The report fields will be cleared and the review will return to its standard state.',
        confirmLabel: 'Dismiss Flag',
        confirmColor: AppColors.textSecondary,
      ),
    );
    if (confirm == true) {
      final success = await provider.dismissReport(review.reviewId);
      if (context.mounted) _showSnackBar(context, success, 'Abuse report dismissed.', provider.moderationError);
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
          'Flagged Reviews',
          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Consumer<ReviewProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.reviews.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage != null && provider.reviews.isEmpty) {
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
                      Text(
                        provider.errorMessage!,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            final list = provider.reportedReviews;

            if (list.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.outlined_flag_rounded,
                      size: 64,
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No reported reviews found',
                      style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'All flagged items are clean or resolved.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final review = list[index];
                return ReportedReviewCard(
                  review: review,
                  onApprove: () => _handleApprove(context, provider, review),
                  onReject: () => _handleReject(context, provider, review),
                  onDismissReport: () => _handleDismissFlag(context, provider, review),
                  onViewDetails: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReviewDetailsScreen(review: review),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}