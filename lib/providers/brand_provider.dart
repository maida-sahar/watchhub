import 'package:image_picker/image_picker.dart';

import 'package:flutter/foundation.dart';

import '../models/brand_model.dart';
import '../repositories/brand_repository.dart';

/// BrandProvider
///
/// Owns all Brand-related UI state and is the ONLY layer the Admin
/// Panel and User App widgets should talk to for brand data.
class BrandProvider extends ChangeNotifier {
  BrandProvider({required BrandRepository repository})
      : _repository = repository;

  final BrandRepository _repository;

  // =========================================================
  // STATE
  // =========================================================

  List<BrandModel> _brands = [];
  List<BrandModel> _activeBrands = [];
  List<BrandModel> _featuredBrands = [];
  BrandModel? _selectedBrand;
  bool _isLoading = false;
  String? _errorMessage;

  // =========================================================
  // GETTERS
  // =========================================================

  List<BrandModel> get brands => List.unmodifiable(_brands);
  List<BrandModel> get activeBrands => List.unmodifiable(_activeBrands);
  List<BrandModel> get featuredBrands => List.unmodifiable(_featuredBrands);
  BrandModel? get selectedBrand => _selectedBrand;
  bool get isLoading => _isLoading;
  String? get error => _errorMessage;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  bool isBrandNameUnique(String name, {String? excludeId}) {
    return !_brands.any((b) =>
        b.name.trim().toLowerCase() == name.trim().toLowerCase() &&
        b.id != excludeId);
  }

  // =========================================================
  // PUBLIC METHODS — LOADS
  // =========================================================

  /// Loads all brands for the Admin Panel.
  Future<void> loadBrands() async {
    await _runGuarded(() async {
      _brands = await _repository.getAllBrands();
    });
  }

  /// Loads only active brands for the User App.
  Future<void> loadActiveBrands() async {
    await _runGuarded(() async {
      _activeBrands = await _repository.getActiveBrands();
    });
  }

  /// Loads featured brands.
  Future<void> loadFeaturedBrands() async {
    await _runGuarded(() async {
      _featuredBrands = await _repository.getFeaturedBrands();
    });
  }

  /// Loads a single brand by [id].
  Future<void> loadBrandById(String id) async {
    await _runGuarded(() async {
      _selectedBrand = await _repository.getBrandById(id);
    });
  }

  // =========================================================
  // PUBLIC METHODS — MUTATIONS
  // =========================================================

  /// Creates a new brand.
  Future<bool> createBrand({
    required String name,
    String description = '',
    String country = '',
    required XFile logoFile,
    required XFile bannerFile,
    String website = '',
    bool isFeatured = false,
    bool isActive = true,
    int displayOrder = 0,
  }) {
    return _runGuardedBool(() async {
      await _repository.createBrand(
        name: name,
        logoFile: logoFile,
        bannerFile: bannerFile,
        description: description,
        country: country,
        website: website,
        isFeatured: isFeatured,
        isActive: isActive,
        displayOrder: displayOrder,
      );
      await _refreshAllLists();
    });
  }

  /// Updates an existing brand.
  Future<void> updateBrand(
    BrandModel brand, {
    XFile? newLogoFile,
    XFile? newBannerFile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateBrand(
        brand,
        newLogoFile: newLogoFile,
        newBannerFile: newBannerFile,
      );
      await _refreshAllLists();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deletes a brand.
  Future<void> deleteBrand(String brandId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteBrand(brandId);
      await _refreshAllLists();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggles featured status.
  Future<void> toggleFeaturedStatus(String brandId, bool isFeatured) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Find brand, update it
      final index = _brands.indexWhere((b) => b.id == brandId);
      if (index != -1) {
        final current = _brands[index];
        final updated = current.copyWith(isFeatured: isFeatured);
        await _repository.updateBrand(updated);
        await _refreshAllLists();
      }
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggles active/inactive status for a brand.
  Future<bool> toggleBrandStatus({
    required String brandId,
    required bool isActive,
  }) {
    return _runGuardedBool(() async {
      await _repository.toggleBrandStatus(brandId, isActive);
      await _refreshAllLists();
    });
  }

  /// Updates a brand's displayOrder and reloads admin list.
  Future<bool> updateDisplayOrder({
    required String brandId,
    required int displayOrder,
  }) {
    return _runGuardedBool(() async {
      await _repository.updateDisplayOrder(brandId, displayOrder);
      _brands = await _repository.getAllBrands();
    });
  }

  /// Performs search.
  List<BrandModel> searchBrands(
    String query, {
    bool includeInactive = true,
  }) {
    final trimmedQuery = query.trim().toLowerCase();
    final source = includeInactive ? _brands : _activeBrands;

    if (trimmedQuery.isEmpty) return List.unmodifiable(source);

    return source
        .where((brand) => brand.name.toLowerCase().contains(trimmedQuery))
        .toList();
  }

  /// Clears the active error state.
  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  // =========================================================
  // PRIVATE HELPERS
  // =========================================================

  /// Refreshes all cached brand lists.
  Future<void> _refreshAllLists() async {
    final results = await Future.wait([
      _repository.getAllBrands(),
      _repository.getActiveBrands(),
      _repository.getFeaturedBrands(),
    ]);
    _brands = results[0];
    _activeBrands = results[1];
    _featuredBrands = results[2];
  }

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

  String _extractMessage(Object error) {
    if (error is BrandRepositoryException) {
      return error.message;
    }
    return error.toString();
  }
}