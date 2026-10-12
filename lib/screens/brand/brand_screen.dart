import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watch_hub/models/brand_model.dart';
import 'package:watch_hub/providers/brand_provider.dart';
import 'package:watch_hub/screens/brand/brand_shimmer.dart';
import 'package:watch_hub/screens/brand/widgets/brand_grid.dart';
import 'package:watch_hub/screens/brand/widgets/empty_brand_widget.dart';

class BrandScreen extends StatefulWidget {
  const BrandScreen({super.key});

  @override
  State<BrandScreen> createState() => _BrandScreenState();
}

class _BrandScreenState extends State<BrandScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

  void _onBrandTap(BrandModel brand) {
    Navigator.of(context).pushNamed('/brand-details', arguments: brand);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Our Brands'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Consumer<BrandProvider>(
          builder: (context, provider, child) {
            // Initial loading state
            if (provider.isLoading && provider.brands.isEmpty) {
              return const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: BrandShimmer(),
              );
            }

            // Error state
            if (provider.errorMessage != null && provider.brands.isEmpty) {
              return SingleChildScrollView(
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
              );
            }

            // Filter active brands only and sort by displayOrder
            var activeBrands =
                provider.brands.where((b) => b.isActive).toList();
            activeBrands
                .sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

            // Apply search filtering
            if (_searchQuery.isNotEmpty) {
              activeBrands = activeBrands
                  .where((b) =>
                      b.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                  .toList();
            }

            final featuredBrands =
                activeBrands.where((b) => b.isFeatured).toList();

            // Empty state when database has no brands
            if (activeBrands.isEmpty && _searchQuery.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: EmptyBrandWidget(onRefresh: _loadData),
                ),
              );
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for brands...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                  ),

                  // Featured Section
                  if (featuredBrands.isNotEmpty && _searchQuery.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        'Featured Brands',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    BrandGrid(
                      brands: featuredBrands,
                      onBrandTap: _onBrandTap,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Divider(),
                    ),
                  ],

                  // All Brands Section / Search Results Section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      _searchQuery.isNotEmpty
                          ? 'Search Results'
                          : 'All Brands',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),

                  if (activeBrands.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text('No matching brands found.'),
                      ),
                    )
                  else
                    BrandGrid(
                      brands: activeBrands,
                      onBrandTap: _onBrandTap,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}