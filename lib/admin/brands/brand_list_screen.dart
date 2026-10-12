import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watch_hub/admin/brands/edit_brand_screen.dart';
import 'package:watch_hub/admin/brands/widgets/brand_card.dart';
import 'package:watch_hub/models/brand_model.dart';
import 'package:watch_hub/providers/brand_provider.dart';
import '../../admin/brands/add_brand_screen.dart';

class BrandListScreen extends StatefulWidget {
  const BrandListScreen({super.key});

  @override
  State<BrandListScreen> createState() => _BrandListScreenState();
}

class _BrandListScreenState extends State<BrandListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'All'; // All, Featured, Active, Inactive
  String _sortBy = 'Display Order'; // Display Order, Newest, Oldest, Alphabetical

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await Provider.of<BrandProvider>(context, listen: false).loadBrands();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BrandModel> _filterAndSortBrands(List<BrandModel> brands) {
    var result = List<BrandModel>.from(brands);

    // Search
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((b) => b.name.toLowerCase().contains(query)).toList();
    }

    // Filter
    if (_filter == 'Featured') {
      result = result.where((b) => b.isFeatured).toList();
    } else if (_filter == 'Active') {
      result = result.where((b) => b.isActive).toList();
    } else if (_filter == 'Inactive') {
      result = result.where((b) => !b.isActive).toList();
    }

    // Sort
    if (_sortBy == 'Display Order') {
      result.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    } else if (_sortBy == 'Alphabetical') {
      result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_sortBy == 'Newest') {
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortBy == 'Oldest') {
      result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    return result;
  }

  void _confirmDelete(BuildContext context, BrandModel brand) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Brand'),
        content: Text('Are you sure you want to delete "${brand.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final provider = Provider.of<BrandProvider>(context, listen: false);
              try {
                await provider.deleteBrand(brand.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Brand deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting brand: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBrandDetails(BuildContext context, BrandModel brand) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(brand.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Country: ${brand.country ?? 'N/A'}'),
              const SizedBox(height: 4),
              Text('Website: ${brand.website ?? 'N/A'}'),
              const SizedBox(height: 4),
              Text('Display Order: ${brand.displayOrder}'),
              const SizedBox(height: 4),
              Text('Featured: ${brand.isFeatured ? 'Yes' : 'No'}'),
              const SizedBox(height: 4),
              Text('Active: ${brand.isActive ? 'Yes' : 'No'}'),
              const SizedBox(height: 8),
              Text('Description: ${brand.description ?? 'N/A'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Brand Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddBrandScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<BrandProvider>(
        builder: (context, provider, child) {
          // Initial Loading State
          if (provider.isLoading && provider.brands.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error State
          if (provider.errorMessage != null && provider.brands.isEmpty) {
            return RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 60,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Oops! Something went wrong.',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        provider.errorMessage!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final filteredBrands = _filterAndSortBrands(provider.brands);

          return RefreshIndicator(
            onRefresh: _loadData,
            child: Column(
              children: [
                // Search Field
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search brands...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (val) => setState(() {}),
                  ),
                ),

                // Filters and Sorting Toolbar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      DropdownButton<String>(
                        value: _filter,
                        items: ['All', 'Featured', 'Active', 'Inactive']
                            .map((f) => DropdownMenuItem(
                                  value: f,
                                  child: Text('Filter: $f'),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _filter = val);
                        },
                      ),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: _sortBy,
                        items: [
                          'Display Order',
                          'Newest',
                          'Oldest',
                          'Alphabetical'
                        ]
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text('Sort: $s'),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _sortBy = val);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(),

                // List View / Empty State
                Expanded(
                  child: filteredBrands.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.4,
                              child: const Center(
                                child: Text('No brands found.'),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filteredBrands.length,
                          itemBuilder: (context, index) {
                            final brand = filteredBrands[index];
                            return AdminBrandCard(
                              brand: brand,
                              onTap: () => _showBrandDetails(context, brand),
                              onEdit: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => EditBrandScreen(brand: brand),
                                  ),
                                );
                              },
                              onDelete: () => _confirmDelete(context, brand),
                              onFeaturedToggle: (val) async {
                                await provider.toggleFeaturedStatus(
                                    brand.id, val);
                              },
                             onActiveToggle: (val) async {
  final success = await provider.toggleBrandStatus(
    brandId: brand.id,
    isActive: val,
  );
  if (!success && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.errorMessage ?? 'Failed to update status')),
    );
  }
},
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}