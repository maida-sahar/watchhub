import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_typography.dart';
import '../../config/clay_widgets.dart';
import '../../providers/review_provider.dart';
import 'widgets/rating_distribution_chart.dart';
import 'widgets/review_status_chart.dart';
import 'widgets/review_statistics_card.dart';
import 'widgets/review_analytics_card.dart';

class ReviewAnalyticsScreen extends StatelessWidget {
  const ReviewAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Reviews Analytics',
          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Consumer<ReviewProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.reviews.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI statistics card
                  ReviewStatisticsCard(
                    totalCount: provider.totalReviewsCount,
                    approvedCount: provider.approvedCount,
                    pendingCount: provider.pendingCount,
                    reportedCount: provider.reportedCount,
                    averageRating: provider.averageRating,
                  ),
                  const SizedBox(height: 24),

                  // Rating distribution bar meters
                  RatingDistributionChart(distribution: provider.ratingDistribution),
                  const SizedBox(height: 24),

                  // Status Segment Chart
                  ReviewStatusChart(
                    approved: provider.approvedCount,
                    pending: provider.pendingCount,
                    hidden: provider.hiddenCount,
                    rejected: provider.rejectedCount,
                  ),
                  const SizedBox(height: 24),

                  // Products and active customers rankings
                  ReviewAnalyticsCard(
                    topProducts: provider.mostReviewedProducts,
                    topCustomers: provider.mostActiveCustomers,
                  ),
                  const SizedBox(height: 24),

                  // Recent Reviews
                  _buildRecentReviews(provider),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecentReviews(ReviewProvider provider) {
    final recent = provider.recentReviews;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return ClayCard(
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Reviews',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: Text(
                  'No reviews submitted yet.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ...recent.map((review) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: review.productImageUrl.isNotEmpty
                          ? Image.network(review.productImageUrl, fit: BoxFit.cover)
                          : const Icon(Icons.watch_rounded, size: 18, color: AppColors.textTertiary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review.productName,
                            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'By ${review.customerName} • ${dateFormat.format(review.createdAt)}',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          review.rating.toStringAsFixed(0),
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}