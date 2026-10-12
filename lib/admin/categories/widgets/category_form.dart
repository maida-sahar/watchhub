import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'category_image_picker.dart';
import 'category_status_switch.dart';
import 'display_order_field.dart';

/// The validated data collected from a [CategoryForm] submission.
///
/// [imageFile] / [iconFile] / [bannerFile] are only non-null when the
/// admin picked a *new* file in this session — on edit, a null value
/// means "keep the existing image," matching
/// `CategoryProvider.updateCategory(newImageFile: ...)`'s optional
/// parameters.
class CategoryFormData {
  const CategoryFormData({
    required this.name,
    required this.description,
    required this.isActive,
    required this.displayOrder,
    this.imageFile,
    this.iconFile,
    this.bannerFile,
  });

  final String name;
  final String description;
  final bool isActive;
  final int displayOrder;
  final XFile? imageFile;
  final XFile? iconFile;
  final XFile? bannerFile;
}

/// Shared Material 3 form for creating or editing a category.
///
/// Used by both `AddCategoryScreen` and `EditCategoryScreen` so field
/// layout, validation, and image-picking behavior stay in one place.
/// This widget never calls `CategoryProvider` itself — the parent screen
/// reads the validated result via [CategoryFormState.validateAndGetData]
/// and performs the actual create/update call.
class CategoryForm extends StatefulWidget {
  const CategoryForm({
    super.key,
    this.initialName = '',
    this.initialDescription = '',
    this.initialIsActive = true,
    this.initialDisplayOrder = 0,
    this.existingImageUrl,
    this.existingIconUrl,
    this.existingBannerUrl,
    this.isImageRequired = true,
    this.isNameTaken,
    this.isSubmitting = false,
    this.uploadingSlot,
  });

  final String initialName;
  final String initialDescription;
  final bool initialIsActive;
  final int initialDisplayOrder;

  /// Existing remote URLs shown as previews when editing a category.
  final String? existingImageUrl;
  final String? existingIconUrl;
  final String? existingBannerUrl;

  /// Whether a category image is mandatory. True for both add and edit,
  /// since a category's `imageUrl` must never end up empty — kept as a
  /// parameter in case a future relaxed-edit flow needs it optional.
  final bool isImageRequired;

  /// Optional client-side, in-memory uniqueness check against already
  /// loaded categories (e.g. from `CategoryProvider.categories`).
  /// Returns true if [name] is already used by a *different* category.
  /// This is a fast UX hint only — the repository re-validates
  /// authoritatively before writing to Firestore.
  final bool Function(String name)? isNameTaken;

  /// Disables all fields and shows a busy submit button while a create/
  /// update call is in flight.
  final bool isSubmitting;

  /// Which image slot ('image' | 'icon' | 'banner') is currently
  /// uploading, if any — used to show a per-tile progress overlay.
  final String? uploadingSlot;

  @override
  State<CategoryForm> createState() => CategoryFormState();
}

class CategoryFormState extends State<CategoryForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _displayOrderController;

  bool _isActive = true;
  XFile? _imageFile;
  XFile? _iconFile;
  XFile? _bannerFile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descriptionController =
        TextEditingController(text: widget.initialDescription);
    _displayOrderController =
        TextEditingController(text: widget.initialDisplayOrder.toString());
    _isActive = widget.initialIsActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _displayOrderController.dispose();
    super.dispose();
  }

  /// Validates every field and, if the form is valid, returns the
  /// collected [CategoryFormData]. Returns `null` if validation fails
  /// (the form itself will already be showing the relevant error text).
  CategoryFormData? validateAndGetData() {
    final isValid = _formKey.currentState?.validate() ?? false;

    final hasImage = _imageFile != null ||
        (widget.existingImageUrl != null && widget.existingImageUrl!.isNotEmpty);
    if (widget.isImageRequired && !hasImage) {
      // The Form's own validators cover text fields; the image
      // requirement is enforced here since it isn't a TextFormField.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category image is required.')),
      );
      return null;
    }

    if (!isValid) return null;

    return CategoryFormData(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      isActive: _isActive,
      displayOrder: int.parse(_displayOrderController.text.trim()),
      imageFile: _imageFile,
      iconFile: _iconFile,
      bannerFile: _bannerFile,
    );
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return 'Category name is required.';
    }
    if (widget.isNameTaken != null && widget.isNameTaken!(name)) {
      return 'A category with this name already exists.';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    final description = value?.trim() ?? '';
    if (description.isEmpty) {
      return 'Description is required.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.isSubmitting;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            enabled: enabled,
            decoration: const InputDecoration(
              labelText: 'Category Name',
              hintText: 'e.g. Luxury, Smart Watch, Sports',
              prefixIcon: Icon(Icons.label_outline),
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            validator: _validateName,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            enabled: enabled,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Short description shown to customers',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.description_outlined),
              border: OutlineInputBorder(),
            ),
            validator: _validateDescription,
          ),
          const SizedBox(height: 16),
          DisplayOrderField(
            controller: _displayOrderController,
            enabled: enabled,
          ),
          const SizedBox(height: 20),
          CategoryImagePicker(
            label: 'Category Image',
            aspectRatioLabel: 'main listing image',
            selectedFile: _imageFile,
            existingImageUrl: widget.existingImageUrl,
            isUploading: widget.uploadingSlot == 'image',
            onImageSelected: enabled
                ? (file) => setState(() => _imageFile = file)
                : (_) {},
          ),
          const SizedBox(height: 16),
          CategoryImagePicker(
            label: 'Category Icon',
            aspectRatioLabel: 'home screen icon',
            selectedFile: _iconFile,
            existingImageUrl: widget.existingIconUrl,
            isUploading: widget.uploadingSlot == 'icon',
            onImageSelected: enabled
                ? (file) => setState(() => _iconFile = file)
                : (_) {},
          ),
          const SizedBox(height: 16),
          CategoryImagePicker(
            label: 'Category Banner',
            aspectRatioLabel: 'category page banner',
            selectedFile: _bannerFile,
            existingImageUrl: widget.existingBannerUrl,
            isUploading: widget.uploadingSlot == 'banner',
            onImageSelected: enabled
                ? (file) => setState(() => _bannerFile = file)
                : (_) {},
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              CategoryStatusSwitch(
                value: _isActive,
                onChanged: enabled
                    ? (value) => setState(() => _isActive = value)
                    : (_) {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}