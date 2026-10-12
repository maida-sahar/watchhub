import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_typography.dart';
import '../../providers/order_provider.dart';
import 'widgets/order_card.dart';
import 'widgets/order_filter_bar.dart';
import 'widgets/order_search_bar.dart';
import 'order_details_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  OrderStatusFilter _selectedFilter = OrderStatusFilter.all;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().watchAllOrders();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    // Safely unsubscribe when leaving the screen
    context.read<OrderProvider>().stopWatchingAllOrders();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Orders Manager',
          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Consumer<OrderProvider>(
          builder: (context, provider, _) {
            if (provider.isLoadingAllOrders && provider.allOrders.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.allOrdersError != null && provider.allOrders.isEmpty) {
              return _buildErrorState(provider.allOrdersError!);
            }

            // Local search & filter logic
            final filteredOrders = provider.allOrders.where((order) {
              // 1. Status Filter
              if (_selectedFilter != OrderStatusFilter.all) {
                final filterVal = _selectedFilter.statusValue;
                if (filterVal != null && order.orderStatus.toLowerCase() != filterVal) {
                  return false;
                }
              }
              // 2. Search Query
              if (_searchQuery.isNotEmpty) {
                if (!order.orderId.toLowerCase().contains(_searchQuery.toLowerCase())) {
                  return false;
                }
              }
              return true;
            }).toList();

            return Column(
              children: [
                // Search Bar input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: OrderSearchBar(
                    controller: _searchController,
                    onClear: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  ),
                ),

                // Horizontal scrollable Filter chips
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
                  child: OrderFilterBar(
                    selected: _selectedFilter,
                    onChanged: (newFilter) {
                      setState(() {
                        _selectedFilter = newFilter;
                      });
                    },
                  ),
                ),

                // Scrollable list of orders
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      provider.watchAllOrders();
                    },
                    color: AppColors.primary,
                    child: filteredOrders.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            itemCount: filteredOrders.length,
                            itemBuilder: (context, index) {
                              final order = filteredOrders[index];
                              return OrderCard(
                                order: order,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AdminOrderDetailsScreen(
                                        orderId: order.orderId,
                                        initialOrder: order,
                                      ),
                                    ),
                                  );
                                },
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

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
        const Icon(Icons.receipt_long_rounded, size: 64, color: AppColors.textTertiary),
        const SizedBox(height: 16),
        Text(
          'No orders found',
          style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _searchQuery.isNotEmpty || _selectedFilter != OrderStatusFilter.all
              ? 'Try resetting the filters or modifying your search query.'
              : 'Incoming customer orders will appear here.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
          textAlign: TextAlign.center,
        ),
      ],
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
            Text(
              'Failed to load orders',
              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}