import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../config/clay_widgets.dart';
import '../../../services/review_service.dart';

class ReportedReviewCard extends StatelessWidget {
  final ReviewModel review;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDismissReport;
  final VoidCallback onViewDetails;

  const ReportedReviewCard({
    super.key,
    required this.review,
    required this.onApprove,
    required this.onReject,
    required this.onDismissReport,
    required this.onViewDetails,
  });

  Color _statusColor(String status) {
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

  @override
  Widget build(BuildContext context) {
    final reportDateStr = review.reportDate != null
        ? DateFormat('MMM dd, yyyy').format(review.reportDate!)
        : 'Unknown Date';
    final statusColor = _statusColor(review.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ClayCard(
        borderRadius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Review ID, Status & Report Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${review.reviewId.substring(0, review.reviewId.length > 8 ? 8 : review.reviewId.length).toUpperCase()}',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.2), width: 0.5),
                  ),
                  child: Text(
                    review.status.toUpperCase(),
                    style: AppTypography.bodySmall.copyWith(
                      color: statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Flagged: $reportDateStr',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ),
            const Divider(height: 20, color: AppColors.divider),

            // Product & Customer Info
            Row(
              children: [
                // Product Thumbnail
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: review.productImageUrl.isNotEmpty
                      ? Image.network(review.productImageUrl, fit: BoxFit.cover)
                      : const Icon(Icons.watch_rounded, color: AppColors.textTertiary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.productName,
                        style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'By: ${review.customerName}',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Rating Star
                Row(
                  children: [
                    Text(
                      '${review.rating.toStringAsFixed(0)}',
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Review Content snippet
            Text(
              '"${review.reviewText}"',
              style: AppTypography.bodyMedium.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Report Reason Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.report_problem_rounded, color: AppColors.error, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Report Reason',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    review.reportReason.isNotEmpty ? review.reportReason : 'Inappropriate content.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Moderation Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: onViewDetails,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: Row(
                    children: [
                      Text(
                        'View Details',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 12),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.success),
                      tooltip: 'Approve & Keep',
                      onPressed: onApprove,
                    ),
                    IconButton(
                      icon: const Icon(Icons.block_flipped, color: Colors.orange),
                      tooltip: 'Reject / Hide Review',
                      onPressed: onReject,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                      tooltip: 'Dismiss Flag / Reset',
                      onPressed: onDismissReport,
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
}