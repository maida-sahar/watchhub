import 'package:image_picker/image_picker.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';

/// Custom exception type thrown by [ProductRepository].
class ProductRepositoryException implements Exception {
  final String message;
  final Object? cause;

  const ProductRepositoryException(this.message, [this.cause]);

  @override
  String toString() => 'ProductRepositoryException: $message';
}

/// ProductRepository
///
/// Owns every business rule for products and is the ONLY layer
/// [ProductProvider] should talk to:
///
///   Provider → ProductRepository → ProductService → Firebase
///
/// This class communicates ONLY with [ProductService] — it never
/// imports `cloud_firestore` or `firebase_storage` directly, and never
/// talks to UI.
class ProductRepository {
  ProductRepository({required ProductService service}) : _service = service;

  final ProductService _service;

  // =========================================================
  // READS
  // =========================================================

  /// Returns all products (active and inactive). Intended for the
  /// Admin Panel.
  Future<List<ProductModel>> getAllProducts() async {
    try {
      return await _service.getAllProducts();
    } catch (e) {
      throw _mapError(e, context: 'fetching all products');
    }
  }

  /// Exposes a real-time stream of all products.
  Stream<List<ProductModel>> watchAllProducts() {
    return _service.watchAllProducts();
  }

  /// Returns only active products. Intended for the User App.
  Future<List<ProductModel>> getActiveProducts() async {
    try {
      return await _service.getActiveProducts();
    } catch (e) {
      throw _mapError(e, context: 'fetching active products');
    }
  }

  /// Returns active products flagged as featured.
  Future<List<ProductModel>> getFeaturedProducts() async {
    try {
      return await _service.getFeaturedProducts();
    } catch (e) {
      throw _mapError(e, context: 'fetching featured products');
    }
  }

  /// Returns products flagged as best sellers.
  Future<List<ProductModel>> getBestSellerProducts() async {
    try {
      return await _service.getBestSellerProducts();
    } catch (e) {
      throw _mapError(e, context: 'fetching best seller products');
    }
  }

  /// Returns products flagged as new arrivals.
  Future<List<ProductModel>> getNewArrivalProducts() async {
    try {
      return await _service.getNewArrivalProducts();
    } catch (e) {
      throw _mapError(e, context: 'fetching new arrival products');
    }
  }

  /// Returns all products belonging to [categoryId].
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    _validateNonEmpty(categoryId, fieldName: 'categoryId');
    try {
      return await _service.getProductsByCategory(categoryId);
    } catch (e) {
      throw _mapError(e, context: 'fetching related products by category');
    }
  }

  /// Returns all products belonging to [brandId].
  Future<List<ProductModel>> getProductsByBrand(String brandId) async {
    _validateNonEmpty(brandId, fieldName: 'brandId');
    try {
      return await _service.getProductsByBrand(brandId);
    } catch (e) {
      throw _mapError(e, context: 'fetching related products by brand');
    }
  }

  /// Fetches a single product by id, or `null` if it doesn't exist.
  Future<ProductModel?> getProductById(String id) async {
    _validateNonEmpty(id, fieldName: 'id');
    try {
      return await _service.getProductById(id);
    } catch (e) {
      throw _mapError(e, context: 'fetching product by id');
    }
  }

  /// Searches Firestore.
  Future<List<ProductModel>> searchProducts(String keyword) async {
    try {
      return await _service.searchProducts(keyword);
    } catch (e) {
      throw _mapError(e, context: 'searching products');
    }
  }

  /// Computes, filters, and prioritizes related products.
  List<ProductModel> getRelatedProducts({
    required ProductModel currentProduct,
    required List<ProductModel> allProducts,
    int limit = 8,
    bool includeOutOfStock = false,
  }) {
    final Map<String, int> scoredProducts = {};
    final Map<String, ProductModel> productMap = {};

    for (final product in allProducts) {
      // Exclude current product and inactive products
      if (product.id == currentProduct.id || !product.isActive) {
        continue;
      }

      // Optionally exclude out of stock items
      if (!includeOutOfStock && product.stock <= 0) {
        continue;
      }

      int score = 0;

      // Priority 1: Same Category
      if (product.categoryId.isNotEmpty &&
          product.categoryId == currentProduct.categoryId) {
        score += 1000;
      } else if (product.categoryName.isNotEmpty &&
          product.categoryName.toLowerCase() ==
              currentProduct.categoryName.toLowerCase()) {
        score += 1000;
      }

      // Priority 2: Same Brand
      if (product.brandId.isNotEmpty &&
          product.brandId == currentProduct.brandId) {
        score += 500;
      } else if (product.brandName.isNotEmpty &&
          product.brandName.toLowerCase() ==
              currentProduct.brandName.toLowerCase()) {
        score += 500;
      }

      // Priority 3: Shared Tags
      if (currentProduct.tags != null &&
          product.tags != null &&
          currentProduct.tags!.isNotEmpty) {
        final commonTags = product.tags!
            .where((tag) => currentProduct.tags!.contains(tag))
            .length;
        score += commonTags * 100;
      }

      // Priority 4: Featured Products
      if (product.isFeatured) {
        score += 50;
      }

      // Priority 5: Best Sellers
      if (product.isBestSeller) {
        score += 25;
      }

      if (score > 0) {
        scoredProducts[product.id] = score;
        productMap[product.id] = product;
      }
    }

    // Sort products by computed score in descending order
    final sortedKeys = scoredProducts.keys.toList()
      ..sort((a, b) => scoredProducts[b]!.compareTo(scoredProducts[a]!));

    // Deduplicate and return maximum 'limit' items
    return sortedKeys.take(limit).map((id) => productMap[id]!).toList();
  }

  // =========================================================
  // IDS
  // =========================================================

  /// Reserves a new, unused product id.
  String generateProductId() => _service.generateProductId();

  // =========================================================
  // WRITES
  // =========================================================

  /// Creates a new product.
  Future<void> createProduct(
    ProductModel product, {
    required XFile thumbnailFile,
    required List<XFile> galleryFiles,
  }) async {
    try {
      _validateBusinessInvariants(product);
      final sanitized = product.copyWith(
        id: product.id.isNotEmpty ? product.id : _service.generateProductId(),
        name: product.name.trim(),
      );
      await _service.createProduct(
        sanitized,
        thumbnailFile: thumbnailFile,
        galleryFiles: galleryFiles,
      );
    } catch (e) {
      throw _mapError(e, context: 'creating product');
    }
  }

  /// Updates an existing product.
  Future<void> updateProduct(
    ProductModel product, {
    XFile? newThumbnailFile,
    List<XFile>? newGalleryFiles,
  }) async {
    _validateNonEmpty(product.id, fieldName: 'product.id');
    try {
      _validateBusinessInvariants(product);
      final trimmedName = product.name.trim();
      final current = await _service.getProductById(product.id);

      if (current == null) {
        throw ProductRepositoryException(
          'Product with id "${product.id}" was not found.',
        );
      }

      final nameChanged =
          current.name.trim().toLowerCase() != trimmedName.toLowerCase();
      if (nameChanged) {
        final nameTaken = await _service.productNameExists(
          trimmedName,
          excludeId: product.id,
        );
        if (nameTaken) {
          throw ProductRepositoryException(
            'A product named "$trimmedName" already exists.',
          );
        }
      }

      final skuChanged = current.sku.trim() != product.sku.trim();
      if (skuChanged) {
        final skuTaken = await _service.skuExists(
          product.sku,
          excludeId: product.id,
        );
        if (skuTaken) {
          throw ProductRepositoryException(
            'A product with SKU "${product.sku}" already exists.',
          );
        }
      }

      final sanitized = product.copyWith(name: trimmedName);
      await _service.updateProduct(
        sanitized,
        newThumbnailFile: newThumbnailFile,
        newGalleryFiles: newGalleryFiles,
      );
    } on ProductRepositoryException {
      rethrow;
    } catch (e) {
      throw _mapError(e, context: 'updating product');
    }
  }

  /// Deletes a product's Firestore document and its Storage images.
  Future<void> deleteProduct(String productId) async {
    _validateNonEmpty(productId, fieldName: 'productId');
    try {
      await _service.deleteProduct(productId);
    } catch (e) {
      throw _mapError(e, context: 'deleting product');
    }
  }

  // =========================================================
  // INVENTORY / STATUS
  // =========================================================

  Future<void> updateStock(String productId, int stock) async {
    _validateNonEmpty(productId, fieldName: 'productId');
    if (stock < 0) {
      throw const ProductRepositoryException('stock cannot be negative.');
    }
    try {
      await _service.updateStock(productId, stock);
    } catch (e) {
      throw _mapError(e, context: 'updating stock');
    }
  }

  Future<void> increaseSoldCount(String productId, int quantity) async {
    _validateNonEmpty(productId, fieldName: 'productId');
    if (quantity <= 0) {
      throw const ProductRepositoryException(
        'quantity must be greater than zero.',
      );
    }
    try {
      await _service.increaseSoldCount(productId, quantity);
    } catch (e) {
      throw _mapError(e, context: 'increasing sold count');
    }
  }

  Future<void> toggleProductStatus(String productId, bool isActive) async {
    _validateNonEmpty(productId, fieldName: 'productId');
    try {
      await _service.toggleProductStatus(productId, isActive);
    } catch (e) {
      throw _mapError(e, context: 'toggling product status');
    }
  }

  Future<void> toggleFeatured(String productId, bool isFeatured) async {
    _validateNonEmpty(productId, fieldName: 'productId');
    try {
      await _service.toggleFeatured(productId, isFeatured);
    } catch (e) {
      throw _mapError(e, context: 'toggling featured status');
    }
  }

  Future<void> toggleBestSeller(String productId, bool isBestSeller) async {
    _validateNonEmpty(productId, fieldName: 'productId');
    try {
      await _service.toggleBestSeller(productId, isBestSeller);
    } catch (e) {
      throw _mapError(e, context: 'toggling best seller status');
    }
  }

  Future<void> toggleNewArrival(String productId, bool isNewArrival) async {
    _validateNonEmpty(productId, fieldName: 'productId');
    try {
      await _service.toggleNewArrival(productId, isNewArrival);
    } catch (e) {
      throw _mapError(e, context: 'toggling new arrival status');
    }
  }

  // =========================================================
  // PRIVATE HELPERS
  // =========================================================

  void _validateNonEmpty(String value, {required String fieldName}) {
    if (value.trim().isEmpty) {
      throw ProductRepositoryException('$fieldName cannot be empty.');
    }
  }

  void _validateBusinessInvariants(ProductModel product) {
    if (product.price < 0) {
      throw const ProductRepositoryException('Price cannot be negative.');
    }
    if (product.discountPrice != null && product.discountPrice! < 0) {
      throw const ProductRepositoryException('Discount price cannot be negative.');
    }
    if (product.stock < 0) {
      throw const ProductRepositoryException('Stock cannot be negative.');
    }
    if (product.minimumStock < 0) {
      throw const ProductRepositoryException('Minimum stock cannot be negative.');
    }
  }

  ProductRepositoryException _mapError(Object error, {required String context}) {
    if (error is ProductRepositoryException) return error;

    if (error is ProductServiceException) {
      return ProductRepositoryException(error.message, error);
    }

    if (error is ArgumentError) {
      return ProductRepositoryException(
        error.message?.toString() ?? 'Invalid product data while $context.',
        error,
      );
    }

    return ProductRepositoryException('Unexpected error while $context.', error);
  }
}