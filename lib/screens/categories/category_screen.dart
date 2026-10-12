import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category_model.dart';
import '../../providers/category_provider.dart';
import '../../widgets/category_grid.dart';
import '../../widgets/category_shimmer.dart';
import '../../widgets/empty_category_widget.dart';
import 'category_details_screen.dart';

/// User App screen showing all active categories (e.g. Luxury, Analog,
/// Smart Watch, Sports, Casual) for the customer to browse.
///
/// This screen talks ONLY to `CategoryProvider` — it never imports or
/// calls Firebase, `CategoryService`, or `CategoryRepository` directly,
/// and it never reads/writes `CategoryProvider.categories` (the
/// admin-facing full list) — only `activeCategories`.
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadActiveCategories();
    });
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    return context.read<CategoryProvider>().loadActiveCategories();
  }

  void _openCategoryDetails(CategoryModel category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryDetailsScreen(category: category),
      ),
    );
  }

  /// Categories to display: search-filtered (if a query is active) and
  /// always sorted by `displayOrder` ascending, per spec.
  List<CategoryModel> _visibleCategories(CategoryProvider provider) {
    final source = _searchQuery.trim().isEmpty
        ? provider.activeCategories
        : provider.searchCategories(_searchQuery, includeInactive: false);

    final sorted = List<CategoryModel>.from(source);
    sorted.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Consumer<CategoryProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                _buildSearchBar(),
                Expanded(child: _buildContent(provider)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search categories',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          filled: true,
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(CategoryProvider provider) {
    // LOADING: only show the full skeleton on the initial load — once
    // categories are already on screen, a pull-to-refresh spinner is
    // enough and swapping to shimmer would feel jarring.
    if (provider.isLoading && provider.activeCategories.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final columns = CategoryGrid.columnsForWidth(constraints.maxWidth);
          return CategoryShimmer(crossAxisCount: columns);
        },
      );
    }

    // ERROR: only shown when there's nothing usable already on screen.
    if (provider.hasError && provider.activeCategories.isEmpty) {
      return _buildErrorState(provider.errorMessage!);
    }

    final categories = _visibleCategories(provider);

    // EMPTY: genuinely no active categories (or no search matches).
    if (categories.isEmpty) {
      if (_searchQuery.trim().isNotEmpty) {
        return _buildNoSearchResults();
      }
      return EmptyCategoryWidget(onRefresh: _refresh);
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CategoryGrid(
        categories: categories,
        onCategoryTap: _openCategoryDetails,
      ),
    );
  }

  Widget _buildNoSearchResults() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No categories match "$_searchQuery".',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}