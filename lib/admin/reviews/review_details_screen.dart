import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_typography.dart';
import '../../config/clay_widgets.dart';
import '../../providers/review_provider.dart';
import '../../services/review_service.dart';
import 'widgets/moderation_action_dialog.dart';

class ReviewDetailsScreen extends StatelessWidget {
  final ReviewModel review;

  const ReviewDetailsScreen({
    super.key,
    required this.review,
  });

  Future<void> _handleAction(
    BuildContext context,
    ReviewProvider provider,
    String title,
    String content,
    String confirmLabel,
    Color confirmColor,
    Future<bool> Function() actionCall,
    String successMsg,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => ModerationActionDialog(
        title: title,
        content: content,
        confirmLabel: confirmLabel,
        confirmColor: confirmColor,
      ),
    );

    if (confirm == true) {
      final success = await actionCall();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? successMsg : (provider.moderationError ?? 'Operation failed.')),
            backgroundColor: success ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (success && title.toLowerCase().contains('delete')) {
          Navigator.pop(context);
        }
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final formatTime = DateFormat('MMMM dd, yyyy - hh:mm a');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Review Moderation',
          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Consumer<ReviewProvider>(
          builder: (context, provider, _) {
            // Find live updated review
            final liveReview = provider.reviews.firstWhere(
              (r) => r.reviewId == review.reviewId,
              orElse: () => review,
            );

            final statusColor = _getStatusColor(liveReview.status);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Detail Card (ID & Status)
                  ClayCard(
                    borderRadius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Review ID',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusColor.withOpacity(0.2), width: 0.5),
                              ),
                              child: Text(
                                liveReview.status.toUpperCase(),
                                style: AppTypography.bodySmall.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          liveReview.reviewId.toUpperCase(),
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 24, color: AppColors.divider),
                        Text(
                          'Submitted Date',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatTime.format(liveReview.createdAt),
                          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Customer details card
                  ClayCard(
                    borderRadius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer Details',
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.primaryLight.withOpacity(0.3),
                              backgroundImage: liveReview.customerImageUrl.isNotEmpty
                                  ? NetworkImage(liveReview.customerImageUrl)
                                  : null,
                              child: liveReview.customerImageUrl.isEmpty
                                  ? Text(
                                      liveReview.customerName.isNotEmpty ? liveReview.customerName[0].toUpperCase() : '?',
                                      style: AppTypography.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    liveReview.customerName,
                                    style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'ID: ${liveReview.customerId}',
                                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Product details card
                  ClayCard(
                    borderRadius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product Details',
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: liveReview.productImageUrl.isNotEmpty
                                  ? Image.network(liveReview.productImageUrl, fit: BoxFit.cover)
                                  : const Icon(Icons.watch_rounded, color: AppColors.textTertiary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    liveReview.productName,
                                    style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Product ID: ${liveReview.productId}',
                                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Review content rating card
                  ClayCard(
                    borderRadius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Review Rating',
                              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < liveReview.rating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                                  color: Colors.amber,
                                  size: 20,
                                );
                              }),
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: AppColors.divider),
                        Text(
                          'Review Text',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '"${liveReview.reviewText}"',
                            style: AppTypography.bodyLarge.copyWith(
                              fontStyle: FontStyle.italic,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Reported Flag Section
                  if (liveReview.isReported) ...[
                    const SizedBox(height: 16),
                    ClayCard(
                      borderRadius: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.report_problem_rounded, color: AppColors.error, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Report Abuse Context',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: AppColors.divider),
                          Text(
                            'Report Reason',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            liveReview.reportReason.isNotEmpty ? liveReview.reportReason : 'Content flagged by user.',
                            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (liveReview.reportDate != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Flagged Date',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatTime.format(liveReview.reportDate!),
                              style: AppTypography.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Controls buttons
                  Text(
                    'Administrative Controls',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  if (liveReview.status != 'approved')
                    _controlButton(
                      label: 'Approve & Publish Review',
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.success,
                      onPressed: () => _handleAction(
                        context,
                        provider,
                        'Approve Review',
                        'Approve review. It will become visible on the product screen.',
                        'Approve',
                        AppColors.success,
                        () => provider.approveReview(liveReview.reviewId),
                        'Review approved successfully.',
                      ),
                    ),

                  if (liveReview.status != 'rejected')
                    _controlButton(
                      label: 'Reject Review',
                      icon: Icons.close_rounded,
                      color: AppColors.error,
                      onPressed: () => _handleAction(
                        context,
                        provider,
                        'Reject Review',
                        'Reject review. It will be hidden and marked as rejected.',
                        'Reject',
                        AppColors.error,
                        () => provider.rejectReview(liveReview.reviewId),
                        'Review rejected successfully.',
                      ),
                    ),

                  if (liveReview.status != 'hidden' && liveReview.status == 'approved')
                    _controlButton(
                      label: 'Hide Review',
                      icon: Icons.visibility_off_rounded,
                      color: Colors.blueGrey,
                      onPressed: () => _handleAction(
                        context,
                        provider,
                        'Hide Review',
                        'Hide review from public watch feeds.',
                        'Hide',
                        Colors.blueGrey,
                        () => provider.hideReview(liveReview.reviewId),
                        'Review hidden successfully.',
                      ),
                    )
                  else if (liveReview.status == 'hidden')
                    _controlButton(
                      label: 'Unhide & Publish Review',
                      icon: Icons.visibility_rounded,
                      color: AppColors.primary,
                      onPressed: () => _handleAction(
                        context,
                        provider,
                        'Unhide Review',
                        'Unhide and publish this review back to active.',
                        'Unhide',
                        AppColors.primary,
                        () => provider.unhideReview(liveReview.reviewId),
                        'Review restored to visibility.',
                      ),
                    ),

                  if (liveReview.isReported) ...[
                    _controlButton(
                      label: 'Resolve Report (Approve)',
                      icon: Icons.done_all_rounded,
                      color: AppColors.success,
                      onPressed: () => _handleAction(
                        context,
                        provider,
                        'Resolve Report',
                        'Clear report flag and approve review.',
                        'Resolve',
                        AppColors.success,
                        () => provider.resolveReport(liveReview.reviewId),
                        'Report resolved successfully.',
                      ),
                    ),
                    _controlButton(
                      label: 'Dismiss Report Flag',
                      icon: Icons.outlined_flag_rounded,
                      color: AppColors.textSecondary,
                      onPressed: () => _handleAction(
                        context,
                        provider,
                        'Dismiss Flag',
                        'Clear reported flag context and restore original state.',
                        'Dismiss',
                        AppColors.textSecondary,
                        () => provider.dismissReport(liveReview.reviewId),
                        'Report flag dismissed.',
                      ),
                    ),
                  ],

                  _controlButton(
                    label: 'Permanently Delete Review',
                    icon: Icons.delete_forever_rounded,
                    color: AppColors.error,
                    onPressed: () => _handleAction(
                      context,
                      provider,
                      'Delete Review',
                      'Permanently remove this review from the system. This action cannot be reversed.',
                      'Delete',
                      AppColors.error,
                      () => provider.deleteReview(liveReview.reviewId),
                      'Review permanently deleted.',
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _controlButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTypography.bodyLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
