import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watch_hub/admin/categories/widgets/category_form.dart';

import '../../models/category_model.dart';
import '../../providers/category_provider.dart';


/// Admin screen for editing an existing category.
///
/// Flow: load category by id → prefill form → validate →
/// `CategoryProvider.updateCategory()` → success snackbar → pop back to
/// `CategoryListScreen`.
///
/// This screen never touches Firebase, `CategoryService`, or
/// `CategoryRepository` directly — all state changes go through
/// `CategoryProvider`.
class EditCategoryScreen extends StatefulWidget {
  const EditCategoryScreen({super.key, required this.categoryId});

  /// The Firestore document id of the category to edit.
  final String categoryId;

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  final _formStateKey = GlobalKey<CategoryFormState>();
  bool _isSubmitting = false;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    // Defer to after first frame so `context.read` is safe inside initState.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategory());
  }

  Future<void> _loadCategory() async {
    final provider = context.read<CategoryProvider>();
    await provider.loadCategoryById(widget.categoryId);
    if (!mounted) return;
    setState(() => _isInitialLoad = false);
  }

  Future<void> _handleSubmit(CategoryModel original) async {
    final formData = _formStateKey.currentState?.validateAndGetData();
    if (formData == null) return; // Form already showing validation errors.

    setState(() => _isSubmitting = true);

    final provider = context.read<CategoryProvider>();
    final updatedCategory = original.copyWith(
      name: formData.name,
      description: formData.description,
      isActive: formData.isActive,
      displayOrder: formData.displayOrder,
    );

    final success = await provider.updateCategory(
      updatedCategory,
      newImageFile: formData.imageFile,
      newIconFile: formData.iconFile,
      newBannerFile: formData.bannerFile,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      _showSnack('Category updated successfully.');
      Navigator.of(context).pop(true);
    } else {
      final message = provider.errorMessage ?? 'Failed to update category.';
      _showSnack(message, isError: true);
    }
  }

  Future<void> _retry() async {
    setState(() => _isInitialLoad = true);
    await _loadCategory();
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? theme.colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Category')),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    return Consumer<CategoryProvider>(
      builder: (context, provider, _) {
        final category = provider.selectedCategory;

        if (category == null || category.id != widget.categoryId) {
          return _buildErrorState(
            provider.errorMessage ?? 'Category not found.',
          );
        }

        // Client-side duplicate-name hint, excluding this category itself.
        final existingNames = provider.categories
            .where((c) => c.id != category.id)
            .map((c) => c.name.trim().toLowerCase())
            .toSet();

        return Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: CategoryForm(
                      key: _formStateKey,
                      initialName: category.name,
                      initialDescription: category.description,
                      initialIsActive: category.isActive,
                      initialDisplayOrder: category.displayOrder,
                      existingImageUrl: category.imageUrl,
                      existingIconUrl: category.iconUrl,
                      existingBannerUrl: category.bannerUrl,
                      isSubmitting: _isSubmitting,
                      isNameTaken: (name) => existingNames.contains(
                        name.trim().toLowerCase(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : () => _handleSubmit(category),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(_isSubmitting ? 'Saving...' : 'Save Changes'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}