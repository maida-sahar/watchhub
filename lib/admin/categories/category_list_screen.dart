import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watch_hub/admin/categories/widgets/category_card.dart';

import '../../models/category_model.dart';
import '../../providers/category_provider.dart';
import 'add_category_screen.dart';
import 'edit_category_screen.dart';


enum _StatusFilter { all, active, inactive }

enum _SortOption { displayOrder, newest, oldest, alphabetical }

extension on _SortOption {
  String get label {
    switch (this) {
      case _SortOption.displayOrder:
        return 'Display Order';
      case _SortOption.newest:
        return 'Newest';
      case _SortOption.oldest:
        return 'Oldest';
      case _SortOption.alphabetical:
        return 'Alphabetical';
    }
  }
}

/// Admin Panel screen listing all categories, with search, status
/// filtering, sorting, and create/edit/delete/toggle actions.
///
/// This screen talks ONLY to `CategoryProvider` — it never imports or
/// calls Firebase, `CategoryService`, or `CategoryRepository` directly.
class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  _StatusFilter _statusFilter = _StatusFilter.all;
  _SortOption _sortOption = _SortOption.displayOrder;

  /// Tracks which category id currently has a status-toggle in flight,
  /// so only that card's switch shows a busy state.
  String? _togglingCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
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
    return context.read<CategoryProvider>().loadCategories();
  }

  Future<void> _openAddScreen() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddCategoryScreen()),
    );
    if (created == true && mounted) {
      await context.read<CategoryProvider>().loadCategories();
    }
  }

  Future<void> _openEditScreen(CategoryModel category) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditCategoryScreen(categoryId: category.id),
      ),
    );
    if (updated == true && mounted) {
      await context.read<CategoryProvider>().loadCategories();
    }
  }

  void _openViewDialog(CategoryModel category) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(category.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (category.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    category.imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              const SizedBox(height: 12),
              Text(category.description.isNotEmpty
                  ? category.description
                  : 'No description provided.'),
              const SizedBox(height: 12),
              Text('Status: ${category.isActive ? "Active" : "Inactive"}'),
              Text('Display Order: ${category.displayOrder}'),
              Text('Created: ${category.createdAt.toLocal()}'.split('.').first),
              Text('Updated: ${category.updatedAt.toLocal()}'.split('.').first),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(CategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          'This will permanently delete "${category.name}" and its images. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<CategoryProvider>();
    final success = await provider.deleteCategory(category.id);

    if (!mounted) return;
    _showSnack(
      success
          ? 'Category deleted.'
          : provider.errorMessage ?? 'Failed to delete category.',
      isError: !success,
    );
  }

  Future<void> _handleToggleStatus(CategoryModel category, bool newValue) async {
    setState(() => _togglingCategoryId = category.id);

    final provider = context.read<CategoryProvider>();
    final success = await provider.toggleCategoryStatus(
      categoryId: category.id,
      isActive: newValue,
    );

    if (!mounted) return;
    setState(() => _togglingCategoryId = null);

    if (!success) {
      _showSnack(
        provider.errorMessage ?? 'Failed to update category status.',
        isError: true,
      );
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? theme.colorScheme.error : null,
      ),
    );
  }

  List<CategoryModel> _applyFilterAndSort(
    CategoryProvider provider,
    List<CategoryModel> source,
  ) {
    var result = source.where((category) {
      switch (_statusFilter) {
        case _StatusFilter.all:
          return true;
        case _StatusFilter.active:
          return category.isActive;
        case _StatusFilter.inactive:
          return !category.isActive;
      }
    }).toList();

    switch (_sortOption) {
      case _SortOption.displayOrder:
        result.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        break;
      case _SortOption.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _SortOption.oldest:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case _SortOption.alphabetical:
        result.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddScreen,
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
      body: SafeArea(
        child: Consumer<CategoryProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                _buildSearchAndFilters(provider),
                Expanded(child: _buildContent(provider)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(CategoryProvider provider) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search categories by name',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', _StatusFilter.all),
                      const SizedBox(width: 8),
                      _buildFilterChip('Active', _StatusFilter.active),
                      const SizedBox(width: 8),
                      _buildFilterChip('Inactive', _StatusFilter.inactive),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<_SortOption>(
                  value: _sortOption,
                  icon: const Icon(Icons.sort),
                  borderRadius: BorderRadius.circular(12),
                  items: _SortOption.values
                      .map(
                        (option) => DropdownMenuItem(
                          value: option,
                          child: Text(option.label, style: theme.textTheme.bodyMedium),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _sortOption = value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, _StatusFilter value) {
    final selected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _statusFilter = value),
    );
  }

  Widget _buildContent(CategoryProvider provider) {
    if (provider.isLoading && provider.categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.hasError && provider.categories.isEmpty) {
      return _buildErrorState(provider.errorMessage!);
    }

    final baseList = _searchQuery.trim().isEmpty
        ? provider.categories
        : provider.searchCategories(_searchQuery);
    final categories = _applyFilterAndSort(provider, baseList);

    if (categories.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = _columnsForWidth(constraints.maxWidth);

          if (crossAxisCount == 1) {
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _buildCard(categories[index]),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisExtent: 220,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) => _buildCard(categories[index]),
          );
        },
      ),
    );
  }

  /// Responsive column count: 1 on mobile, 2 on tablet, 3 on desktop.
  int _columnsForWidth(double width) {
    if (width >= 1100) return 3;
    if (width >= 700) return 2;
    return 1;
  }

  Widget _buildCard(CategoryModel category) {
    return CategoryCard(
      category: category,
      isTogglingStatus: _togglingCategoryId == category.id,
      onView: () => _openViewDialog(category),
      onEdit: () => _openEditScreen(category),
      onDelete: () => _confirmDelete(category),
      onToggleStatus: (value) => _handleToggleStatus(category, value),
    );
  }

  Widget _buildEmptyState() {
    final hasActiveFilters =
        _searchQuery.isNotEmpty || _statusFilter != _StatusFilter.all;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasActiveFilters ? Icons.search_off : Icons.watch_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              hasActiveFilters
                  ? 'No categories match your search or filters.'
                  : 'No categories yet. Tap "Add Category" to create one.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
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