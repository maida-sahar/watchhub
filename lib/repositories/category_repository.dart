import 'package:image_picker/image_picker.dart';

import '../models/category_model.dart';
import '../services/category_service.dart';

/// Custom exception type thrown by [CategoryRepository].
///
/// This is the single exception type Provider layers should catch when
/// calling into this repository. It wraps both business-rule violations
/// (e.g. duplicate name) and re-wrapped lower-level failures bubbled up
/// from [CategoryService], so callers never need to know about
/// [CategoryServiceException] directly.
class CategoryRepositoryException implements Exception {
  final String message;
  final Object? cause;

  const CategoryRepositoryException(this.message, [this.cause]);

  @override
  String toString() => 'CategoryRepositoryException: $message';
}

/// CategoryRepository
///
/// Acts as the single bridge between the Provider layer and
/// [CategoryService]:
///
///   Provider → CategoryRepository → CategoryService → Firebase
///
/// Providers must never call [CategoryService] directly — this class is
/// where business rules (validation, uniqueness, sorting guarantees) are
/// enforced, on top of the raw data access that [CategoryService] provides.
class CategoryRepository {
  /// [service] is injected rather than instantiated internally, so tests
  /// can supply a fake/mock [CategoryService].
  CategoryRepository({required CategoryService service}) : _service = service;

  final CategoryService _service;

  // =========================================================
  // PUBLIC API
  // =========================================================

  /// Creates a new category after validating business rules.
  ///
  /// Rules enforced:
  /// • [name] must not be empty.
  /// • [name] must be unique (case-insensitive) among existing categories.
  /// • [displayOrder] cannot be negative.
  /// • Image, icon, and banner files must be provided (imageUrl can never
  ///   end up empty for a category the User App might display).
  Future<CategoryModel> createCategory({
    required String name,
    String description = '',
    required XFile imageFile,
    required XFile iconFile,
    required XFile bannerFile,
    bool isActive = true,
    int displayOrder = 0,
  }) async {
    try {
      final trimmedName = _validateName(name);
      _validateDisplayOrder(displayOrder);
      await _validateFilesProvided(
        imageFile: imageFile,
        iconFile: iconFile,
        bannerFile: bannerFile,
      );

      await _ensureNameIsUnique(trimmedName);

      return await _service.addCategory(
        name: trimmedName,
        description: description.trim(),
        imageFile: imageFile,
        iconFile: iconFile,
        bannerFile: bannerFile,
        isActive: isActive,
        displayOrder: displayOrder,
      );
    } on CategoryRepositoryException {
      rethrow;
    } catch (e) {
      throw _mapError(e, context: 'creating category');
    }
  }

  /// Fetches all categories (active and inactive), sorted by
  /// [CategoryModel.displayOrder] ascending. Intended for the Admin Panel.
  ///
  /// Sorting is re-applied here defensively, so the guarantee holds even
  /// if the underlying service's ordering ever changes.
  Future<List<CategoryModel>> fetchAllCategories() async {
    try {
      final categories = await _service.getAllCategories();
      return _sortByDisplayOrder(categories);
    } catch (e) {
      throw _mapError(e, context: 'fetching all categories');
    }
  }

  /// Fetches only categories where `isActive == true`, sorted by
  /// [CategoryModel.displayOrder] ascending. Intended for the User App.
  Future<List<CategoryModel>> fetchActiveCategories() async {
    try {
      final categories = await _service.getActiveCategories();
      // Defensive filter: guarantees the User App never sees an inactive
      // category even if the underlying query is ever loosened.
      final activeOnly = categories.where((c) => c.isActive).toList();
      return _sortByDisplayOrder(activeOnly);
    } catch (e) {
      throw _mapError(e, context: 'fetching active categories');
    }
  }

  /// Fetches a single category by id.
  ///
  /// Throws [CategoryRepositoryException] if no category with that id
  /// exists — unlike the service layer, the repository treats a missing
  /// category as an error condition since callers ask for one by id
  /// expecting it to exist.
  Future<CategoryModel> fetchCategoryById(String categoryId) async {
    try {
      _validateNonEmpty(categoryId, fieldName: 'categoryId');
      final category = await _service.getCategoryById(categoryId);
      if (category == null) {
        throw CategoryRepositoryException(
          'Category with id "$categoryId" was not found.',
        );
      }
      return category;
    } on CategoryRepositoryException {
      rethrow;
    } catch (e) {
      throw _mapError(e, context: 'fetching category by id');
    }
  }

  /// Updates an existing category after validating business rules.
  ///
  /// [category] should be the desired new state of the category (with
  /// text fields already edited by the caller). If the name has changed,
  /// uniqueness is re-checked against every *other* category. Optional
  /// new image/icon/banner files replace the existing ones in Storage.
  Future<CategoryModel> updateCategory(
    CategoryModel category, {
    XFile? newImageFile,
    XFile? newIconFile,
    XFile? newBannerFile,
  }) async {
    try {
      _validateNonEmpty(category.id, fieldName: 'category.id');
      final trimmedName = _validateName(category.name);
      _validateDisplayOrder(category.displayOrder);

      await _ensureNameIsUnique(trimmedName, excludingId: category.id);

      final sanitized = category.copyWith(
        name: trimmedName,
        description: category.description.trim(),
      );

      return await _service.updateCategory(
        sanitized,
        newImageFile: newImageFile,
        newIconFile: newIconFile,
        newBannerFile: newBannerFile,
      );
    } on CategoryRepositoryException {
      rethrow;
    } catch (e) {
      throw _mapError(e, context: 'updating category');
    }
  }

  /// Deletes a category's Firestore document and its associated
  /// Storage images (image, icon, banner).
  Future<void> deleteCategory(String categoryId) async {
    try {
      _validateNonEmpty(categoryId, fieldName: 'categoryId');
      await _service.deleteCategory(categoryId);
    } catch (e) {
      throw _mapError(e, context: 'deleting category');
    }
  }

  /// Enables or disables a category.
  Future<void> toggleCategoryStatus({
    required String categoryId,
    required bool isActive,
  }) async {
    try {
      _validateNonEmpty(categoryId, fieldName: 'categoryId');
      await _service.toggleCategoryStatus(
        categoryId: categoryId,
        isActive: isActive,
      );
    } catch (e) {
      throw _mapError(e, context: 'toggling category status');
    }
  }

  /// Updates a category's displayOrder, used for admin re-sorting.
  ///
  /// Rejects negative values before ever reaching Firestore.
  Future<void> changeDisplayOrder({
    required String categoryId,
    required int displayOrder,
  }) async {
    try {
      _validateNonEmpty(categoryId, fieldName: 'categoryId');
      _validateDisplayOrder(displayOrder);
      await _service.updateDisplayOrder(
        categoryId: categoryId,
        displayOrder: displayOrder,
      );
    } on CategoryRepositoryException {
      rethrow;
    } catch (e) {
      throw _mapError(e, context: 'changing display order');
    }
  }

  // =========================================================
  // PRIVATE HELPERS — VALIDATION
  // =========================================================

  /// Validates that [name] is non-empty and returns its trimmed form.
  String _validateName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const CategoryRepositoryException('Category name cannot be empty.');
    }
    return trimmed;
  }

  /// Validates that [value] (a generic required id/field) is non-empty.
  void _validateNonEmpty(String value, {required String fieldName}) {
    if (value.trim().isEmpty) {
      throw CategoryRepositoryException('$fieldName cannot be empty.');
    }
  }

  /// Validates that [displayOrder] is not negative.
  void _validateDisplayOrder(int displayOrder) {
    if (displayOrder < 0) {
      throw const CategoryRepositoryException(
        'displayOrder cannot be negative.',
      );
    }
  }

  /// Validates that image, icon, and banner files are all provided and
  /// exist on disk. A category's imageUrl should never end up empty, so
  /// this is checked before ever reaching the service/upload layer.
  Future<void> _validateFilesProvided({
    required XFile imageFile,
    required XFile iconFile,
    required XFile bannerFile,
  }) async {
    try {
      if (await imageFile.length() == 0) {
        throw const CategoryRepositoryException('Category image is required and is empty.');
      }
    } catch (e) {
      throw const CategoryRepositoryException(
        'Category image is required and was not found on disk.',
      );
    }
    try {
      if (await iconFile.length() == 0) {
        throw const CategoryRepositoryException('Category icon is required and is empty.');
      }
    } catch (e) {
      throw const CategoryRepositoryException(
        'Category icon is required and was not found on disk.',
      );
    }
    try {
      if (await bannerFile.length() == 0) {
        throw const CategoryRepositoryException('Category banner is required and is empty.');
      }
    } catch (e) {
      throw const CategoryRepositoryException(
        'Category banner is required and was not found on disk.',
      );
    }
  }

  /// Ensures no other category already uses [name] (case-insensitive).
  ///
  /// [excludingId] should be passed during updates so a category doesn't
  /// collide with its own unchanged name.
  Future<void> _ensureNameIsUnique(String name, {String? excludingId}) async {
    final existing = await _service.getAllCategories();
    final normalizedName = name.toLowerCase();

    final isDuplicate = existing.any((category) {
      final sameName = category.name.trim().toLowerCase() == normalizedName;
      final isSelf = excludingId != null && category.id == excludingId;
      return sameName && !isSelf;
    });

    if (isDuplicate) {
      throw CategoryRepositoryException(
        'A category named "$name" already exists. Category names must be unique.',
      );
    }
  }

  /// Returns a new list sorted by [CategoryModel.displayOrder] ascending.
  List<CategoryModel> _sortByDisplayOrder(List<CategoryModel> categories) {
    final sorted = List<CategoryModel>.from(categories);
    sorted.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return sorted;
  }

  // =========================================================
  // PRIVATE HELPERS — ERROR MAPPING
  // =========================================================

  /// Converts any lower-level exception (including
  /// [CategoryServiceException]) into a [CategoryRepositoryException],
  /// so Provider only ever needs to catch one exception type.
  CategoryRepositoryException _mapError(Object error, {required String context}) {
    if (error is CategoryRepositoryException) return error;

    if (error is CategoryServiceException) {
      return CategoryRepositoryException(error.message, error);
    }

    return CategoryRepositoryException('Unexpected error while $context.', error);
  }
}