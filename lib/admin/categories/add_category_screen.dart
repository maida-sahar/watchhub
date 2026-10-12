import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watch_hub/admin/categories/widgets/category_form.dart';

import '../../providers/category_provider.dart';


/// Admin screen for creating a new category.
///
/// Flow: fill form → validate → `CategoryProvider.createCategory()` →
/// success snackbar → pop back to `CategoryListScreen`.
///
/// This screen never touches Firebase, `CategoryService`, or
/// `CategoryRepository` directly — all state changes go through
/// `CategoryProvider`.
class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formStateKey = GlobalKey<CategoryFormState>();
  bool _isSubmitting = false;

  Future<void> _handleSubmit() async {
    final formData = _formStateKey.currentState?.validateAndGetData();
    if (formData == null) return; // Form already showing validation errors.

    if (formData.imageFile == null ||
        formData.iconFile == null ||
        formData.bannerFile == null) {
      _showSnack('Please select an image, icon, and banner before saving.');
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = context.read<CategoryProvider>();
    final success = await provider.createCategory(
      name: formData.name,
      description: formData.description,
      imageFile: formData.imageFile!,
      iconFile: formData.iconFile!,
      bannerFile: formData.bannerFile!,
      isActive: formData.isActive,
      displayOrder: formData.displayOrder,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      _showSnack('Category created successfully.');
      Navigator.of(context).pop(true);
    } else {
      final message = provider.errorMessage ?? 'Failed to create category.';
      _showSnack(message, isError: true);
    }
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
    // Client-side duplicate-name hint using already-loaded categories.
    // The repository still performs the authoritative uniqueness check.
    final existingNames = context
        .watch<CategoryProvider>()
        .categories
        .map((c) => c.name.trim().toLowerCase())
        .toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('Add Category')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: CategoryForm(
                key: _formStateKey,
                isSubmitting: _isSubmitting,
                isNameTaken: (name) => existingNames.contains(
                  name.trim().toLowerCase(),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton.icon(
            onPressed: _isSubmitting ? null : _handleSubmit,
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
            label: Text(_isSubmitting ? 'Saving...' : 'Save Category'),
          ),
        ),
      ),
    );
  }
}