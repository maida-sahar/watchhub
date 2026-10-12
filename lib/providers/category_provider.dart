import 'package:image_picker/image_picker.dart';

import 'package:flutter/foundation.dart';

import '../models/category_model.dart';
import '../repositories/category_repository.dart';

/// CategoryProvider
///
/// Owns all Category-related UI state and is the ONLY layer the
/// Admin Panel and User App widgets should talk to for category data.
///
///   UI → CategoryProvider → CategoryRepository → CategoryService → Firebase
///
/// This class never imports Firebase packages and never talks to
/// [CategoryRepository]'s underlying service directly — it only calls
/// repository methods and translates the result (or failure) into
/// observable state via [ChangeNotifier].
class CategoryProvider extends ChangeNotifier {
  /// [repository] is injected so this provider can be unit-tested with a
  /// fake/mock repository, without touching real Firebase.
  CategoryProvider({required CategoryRepository repository})
      : _repository = repository;

  final CategoryRepository _repository;

  // =========================================================
  // STATE
  // =========================================================

  List<CategoryModel> _categories = [];
  List<CategoryModel> _activeCategories = [];
  CategoryModel? _selectedCategory;
  bool _isLoading = false;
  String? _errorMessage;

  // =========================================================
  // GETTERS
  // =========================================================

  /// All categories (active and inactive) — used by the Admin Panel.
  /// Returned as an unmodifiable view so UI code cannot mutate state
  /// directly and bypass [notifyListeners].
  List<CategoryModel> get categories => List.unmodifiable(_categories);

  /// Only active categories — used by the User App.
  List<CategoryModel> get activeCategories =>
      List.unmodifiable(_activeCategories);

  /// The most recently loaded single category, if any (e.g. for an
  /// Admin "edit category" screen).
  CategoryModel? get selectedCategory => _selectedCategory;

  /// Whether an async operation is currently in progress.
  bool get isLoading => _isLoading;

  /// The last error message, or `null` if there is no active error.
  String? get errorMessage => _errorMessage;

  /// Convenience flag for UI to quickly check for an error state.
  bool get hasError => _errorMessage != null;

  // =========================================================
  // PUBLIC METHODS
  // =========================================================

  /// Loads all categories (active and inactive) for the Admin Panel.
  Future<void> loadCategories() async {
    await _runGuarded(() async {
      _categories = await _repository.fetchAllCategories();
    });
  }

  /// Loads only active categories for the User App.
  Future<void> loadActiveCategories() async {
    await _runGuarded(() async {
      _activeCategories = await _repository.fetchActiveCategories();
    });
  }

  /// Loads a single category by [id] and stores it in [selectedCategory].
  /// Useful for an Admin "edit category" screen.
  Future<void> loadCategoryById(String id) async {
    await _runGuarded(() async {
      _selectedCategory = await _repository.fetchCategoryById(id);
    });
  }

  /// Creates a new category, then refreshes [categories] so the Admin
  /// Panel list reflects the newly added item.
  ///
  /// Returns `true` on success, `false` on failure (with [errorMessage]
  /// populated) — letting the UI decide how to react (e.g. pop a screen
  /// only on success) without needing to catch exceptions itself.
  Future<bool> createCategory({
    required String name,
    String description = '',
    required XFile imageFile,
    required XFile iconFile,
    required XFile bannerFile,
    bool isActive = true,
    int displayOrder = 0,
  }) {
    return _runGuardedBool(() async {
      await _repository.createCategory(
        name: name,
        description: description,
        imageFile: imageFile,
        iconFile: iconFile,
        bannerFile: bannerFile,
        isActive: isActive,
        displayOrder: displayOrder,
      );
      await _refreshAllLists();
    });
  }

  /// Updates an existing category, then refreshes [categories] so the
  /// Admin Panel list reflects the change.
  Future<bool> updateCategory(
    CategoryModel category, {
    XFile? newImageFile,
    XFile? newIconFile,
    XFile? newBannerFile,
  }) {
    return _runGuardedBool(() async {
      final updated = await _repository.updateCategory(
        category,
        newImageFile: newImageFile,
        newIconFile: newIconFile,
        newBannerFile: newBannerFile,
      );
      // Keep selectedCategory in sync if it's the one being edited.
      if (_selectedCategory?.id == updated.id) {
        _selectedCategory = updated;
      }
      await _refreshAllLists();
    });
  }

  /// Deletes a category, then refreshes [categories] so the Admin Panel
  /// list no longer shows the deleted item.
  Future<bool> deleteCategory(String categoryId) {
    return _runGuardedBool(() async {
      await _repository.deleteCategory(categoryId);
      if (_selectedCategory?.id == categoryId) {
        _selectedCategory = null;
      }
      await _refreshAllLists();
    });
  }

  /// Enables or disables a category, then refreshes both [categories]
  /// and [activeCategories], since a status change affects both lists.
  Future<bool> toggleCategoryStatus({
    required String categoryId,
    required bool isActive,
  }) {
    return _runGuardedBool(() async {
      await _repository.toggleCategoryStatus(
        categoryId: categoryId,
        isActive: isActive,
      );
      await _refreshAllLists();
    });
  }

  /// Updates a category's displayOrder, then reloads categories so the
  /// Admin Panel list reflects the new sort order.
  Future<bool> updateDisplayOrder({
    required String categoryId,
    required int displayOrder,
  }) {
    return _runGuardedBool(() async {
      await _repository.changeDisplayOrder(
        categoryId: categoryId,
        displayOrder: displayOrder,
      );
      await _refreshAllLists();
    });
  }

  /// Searches already-loaded categories by [query] matched against
  /// [CategoryModel.name] (case-insensitive, substring match).
  ///
  /// This runs entirely against in-memory data — no Firestore query is
  /// made — so it is synchronous and safe to call on every keystroke of
  /// a search field.
  ///
  /// [includeInactive] controls whether search is performed over
  /// [categories] (Admin Panel, default) or [activeCategories] (User App).
  List<CategoryModel> searchCategories(
    String query, {
    bool includeInactive = true,
  }) {
    final trimmedQuery = query.trim().toLowerCase();
    final source = includeInactive ? _categories : _activeCategories;

    if (trimmedQuery.isEmpty) return List.unmodifiable(source);

    return source
        .where((category) => category.name.toLowerCase().contains(trimmedQuery))
        .toList();
  }

  /// Clears the current error message, if any.
  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  // =========================================================
  // PRIVATE HELPERS
  // =========================================================

  /// Refreshes both [categories] and [activeCategories] from the
  /// repository. Used after any mutation (create/update/delete/toggle/
  /// reorder) since these operations can affect both lists.
  Future<void> _refreshAllLists() async {
    _categories = await _repository.fetchAllCategories();
    _activeCategories = await _repository.fetchActiveCategories();
  }

  /// Runs [action] with the standard loading/error lifecycle:
  ///
  ///   isLoading = true → notifyListeners()
  ///   ↓
  ///   action() (repository call)
  ///   ↓
  ///   isLoading = false → notifyListeners()
  ///
  /// Any exception is caught and converted into [errorMessage] rather
  /// than being rethrown, so a repository/service failure never crashes
  /// the app — the UI simply observes [errorMessage] instead.
  Future<void> _runGuarded(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
    } catch (e) {
      _errorMessage = _extractMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Same lifecycle as [_runGuarded], but returns whether [action]
  /// completed successfully — convenient for mutation methods where the
  /// UI wants a simple success/failure signal (e.g. to pop a form screen
  /// only on success).
  Future<bool> _runGuardedBool(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    var success = false;
    try {
      await action();
      success = true;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      success = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }

  /// Extracts a human-readable message from any thrown error.
  ///
  /// [CategoryRepositoryException] already carries a readable message;
  /// anything unexpected falls back to a generic, user-safe string
  /// rather than leaking raw exception/stack details to the UI.
  String _extractMessage(Object error) {
    if (error is CategoryRepositoryException) {
      return error.message;
    }
    return 'Something went wrong while processing categories. Please try again.';
  }
}