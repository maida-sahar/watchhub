import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_typography.dart';
import '../../providers/user_provider.dart';
import 'customer_statistics_screen.dart';
import 'widgets/customer_card.dart';
import 'widgets/customer_filter_dialog.dart';
import 'widgets/customer_search_bar.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().watchCustomers();
    });
  }

  void _openFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CustomerFilterDialog(),
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
          'Customers',
          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: AppColors.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomerStatisticsScreen(),
                ),
              );
            },
            tooltip: 'Statistics & Reports',
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<UserProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.customers.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage != null && provider.customers.isEmpty) {
              return _buildErrorState(context, provider.errorMessage!, () {
                provider.watchCustomers();
              });
            }

            final filteredList = provider.filteredCustomers;

            return Column(
              children: [
                // Search Bar + Filter Trigger
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: CustomerSearchBar(),
                      ),
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
                              color: provider.filterType != 'all' || provider.dateRange != null
                                  ? AppColors.primary.withOpacity(0.4)
                                  : AppColors.border.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.filter_list_rounded,
                            color: provider.filterType != 'all' || provider.dateRange != null
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Active Filter Chips Indicator Row
                if (provider.filterType != 'all' || provider.dateRange != null)
                  _buildFilterChipsRow(provider),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      provider.stopWatching();
                      provider.watchCustomers();
                    },
                    color: AppColors.primary,
                    child: filteredList.isEmpty
                        ? _buildEmptyState(provider)
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final customer = filteredList[index];
                              final totalOrders = provider.getTotalOrders(customer.uid);
                              final totalSpending = provider.getTotalSpending(customer.uid);

                              return CustomerCard(
                                customer: customer,
                                totalOrders: totalOrders,
                                totalSpending: totalSpending,
                              );
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

  Widget _buildFilterChipsRow(UserProvider provider) {
    final Map<String, String> filterTypeLabels = {
      'active': 'Active Only',
      'inactive': 'Inactive Only',
      'new': 'New Customers',
      'with_orders': 'With Orders',
      'without_orders': 'Without Orders',
      'top_spending': 'Top Spenders',
    };

    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (provider.filterType != 'all')
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: InputChip(
                label: Text(filterTypeLabels[provider.filterType] ?? provider.filterType),
                onDeleted: () => provider.setFilterType('all'),
                deleteIconColor: AppColors.primary,
                backgroundColor: AppColors.primary.withOpacity(0.08),
                side: BorderSide(color: AppColors.primary.withOpacity(0.12)),
                labelStyle: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (provider.dateRange != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: InputChip(
                label: Text(
                  'Joined: ${DateFormat('MMM dd').format(provider.dateRange!.start)} - ${DateFormat('MMM dd').format(provider.dateRange!.end)}',
                ),
                onDeleted: () => provider.setDateRange(null),
                deleteIconColor: AppColors.primary,
                backgroundColor: AppColors.primary.withOpacity(0.08),
                side: BorderSide(color: AppColors.primary.withOpacity(0.12)),
                labelStyle: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ActionChip(
            label: const Text('Clear All'),
            onPressed: provider.resetFilters,
            backgroundColor: AppColors.background,
            side: const BorderSide(color: AppColors.border),
            labelStyle: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(UserProvider provider) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Icon(
          Icons.people_outline_rounded,
          size: 64,
          color: AppColors.textTertiary,
        ),
        const SizedBox(height: 16),
        Text(
          'No customers found',
          style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          provider.searchQuery.isNotEmpty || provider.filterType != 'all' || provider.dateRange != null
              ? 'Try widening your search keywords or resetting your active filters'
              : 'Signups from customers will appear here automatically',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String message, VoidCallback onRetry) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'An Error Occurred',
              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Retry Connection',
                style: AppTypography.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
