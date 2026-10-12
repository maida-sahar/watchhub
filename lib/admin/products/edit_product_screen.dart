// standard import
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/brand_provider.dart';
import '../../utils/price_parser.dart';
import 'widgets/product_form.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _shortDescController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _discountPriceController;
  late TextEditingController _skuController;
  late TextEditingController _stockController;
  late TextEditingController _minStockController;
  final _tagController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedBrandId;

  late bool _isActive;
  late bool _isFeatured;
  late bool _isBestSeller;
  late bool _isNewArrival;

  XFile? _thumbnailFile;
  late String _networkThumbnailUrl;
  late List<String> _networkGalleryUrls;
  final List<XFile> _localGalleryFiles = [];
  late Map<String, String> _specifications;
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p.name);
    _shortDescController = TextEditingController(text: p.shortDescription ?? '');
    _descController = TextEditingController(text: p.description);
    _priceController = TextEditingController(text: p.price.toString());
    _discountPriceController = TextEditingController(
      text: (p.discountPrice != null && p.discountPrice! > 0) ? p.discountPrice.toString() : '',
    );
    _skuController = TextEditingController(text: p.sku);
    _stockController = TextEditingController(text: p.stock.toString());
    
    // Fixed model property: minStock instead of minimumStock
    _minStockController = TextEditingController(text: p.minimumStock.toString());

    _selectedCategoryId = p.categoryId;
    _selectedBrandId = p.brandId;

    _isActive = p.isActive;
    _isFeatured = p.isFeatured;
    _isBestSeller = p.isBestSeller;
    _isNewArrival = p.isNewArrival;

    _networkThumbnailUrl = p.thumbnail;
    
    // Fixed model property: galleryImages instead of imageUrls
    _networkGalleryUrls = List.from(p.galleryImages);
    _specifications = Map.from(p.specifications ?? {});
    _tags = List.from(p.tags ?? []);

    // Same as AddProductScreen: the dropdowns only read from
    // CategoryProvider/BrandProvider, nobody fetches for them, so without
    // this the lists stay empty and the dropdown shows the existing
    // product's category/brand id with no matching item in it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<CategoryProvider>(context, listen: false).loadCategories();
      Provider.of<BrandProvider>(context, listen: false).loadBrands();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortDescController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _skuController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addSpecification() {
    final keyController = TextEditingController();
    final valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Specification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: keyController, decoration: const InputDecoration(labelText: 'Feature')),
            TextField(controller: valueController, decoration: const InputDecoration(labelText: 'Value')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (keyController.text.isNotEmpty && valueController.text.isNotEmpty) {
                setState(() {
                  _specifications[keyController.text.trim()] = valueController.text.trim();
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          )
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Use the shared sanitizing parser here too — not double.parse/
    // double.tryParse directly — so a currency-formatted value like
    // "$ 12,500" that passed PriceSection's validator parses to the
    // same 12500.0 here, instead of throwing/returning null.
    final double basePrice = PriceParser.tryParse(_priceController.text) ?? 0;
    final double? parsedDiscount = PriceParser.tryParse(_discountPriceController.text);
    final bool hasDiscount =
        parsedDiscount != null && parsedDiscount > 0 && parsedDiscount < basePrice;
    // `discountPercentage` isn't a separate form field — it's derived from
    // price/discountPrice so the "-X%" badge shown on product cards has a
    // real value instead of always reading 0 (or a stale value carried
    // over from before this edit).
    final double discountPercentage =
        hasDiscount ? ((basePrice - parsedDiscount) / basePrice) * 100 : 0.0;

    final updatedProduct = widget.product.copyWith(
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      shortDescription: _shortDescController.text.trim(),
      price: basePrice,
      // `copyWith` treats a `null` discountPrice as "leave it unchanged"
      // (see ProductModel.copyWith), so clearing the discount field must
      // explicitly pass `basePrice` here — otherwise the old discount
      // silently survives even after the admin removes it from the form.
      discountPrice: hasDiscount ? parsedDiscount : basePrice,
      discountPercentage: discountPercentage,
      sku: _skuController.text.trim(),
      stock: int.parse(_stockController.text.trim()),
      minimumStock: int.parse(_minStockController.text.trim()),
      categoryId: _selectedCategoryId,
      brandId: _selectedBrandId,
      isActive: _isActive,
      isFeatured: _isFeatured,
      isBestSeller: _isBestSeller,
      isNewArrival: _isNewArrival,
      thumbnail: _networkThumbnailUrl,
      imageUrls: _networkGalleryUrls,
      specifications: _specifications,
      tags: _tags,
      updatedAt: DateTime.now(),
    );

    try {
      // Same fix as add_product_screen.dart: updateProduct returns a
      // bool and swallows its own exceptions rather than throwing, so
      // this previously always popped the screen regardless of whether
      // the update actually succeeded.
      final provider = Provider.of<ProductProvider>(context, listen: false);
      final success = await provider.updateProduct(
        updatedProduct,
        newThumbnailFile: _thumbnailFile,
        newGalleryFiles: _localGalleryFiles,
      );
      if (!mounted) return;
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update product: ${provider.errorMessage ?? 'Unknown error'}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating product: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<ProductProvider>(context).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ProductForm(
                formKey: _formKey,
                nameController: _nameController,
                shortDescController: _shortDescController,
                descController: _descController,
                priceController: _priceController,
                discountPriceController: _discountPriceController,
                skuController: _skuController,
                stockController: _stockController,
                minStockController: _minStockController,
                selectedCategoryId: _selectedCategoryId,
                selectedBrandId: _selectedBrandId,
                onCategoryChanged: (val) => setState(() => _selectedCategoryId = val),
                onBrandChanged: (val) => setState(() => _selectedBrandId = val),
                isActive: _isActive,
                isFeatured: _isFeatured,
                isBestSeller: _isBestSeller,
                isNewArrival: _isNewArrival,
                onActiveChanged: (val) => setState(() => _isActive = val ?? false),
                onFeaturedChanged: (val) => setState(() => _isFeatured = val ?? false),
                onBestSellerChanged: (val) => setState(() => _isBestSeller = val ?? false),
                onNewArrivalChanged: (val) => setState(() => _isNewArrival = val ?? false),
                thumbnailFile: _thumbnailFile,
                networkThumbnailUrl: _networkThumbnailUrl,
                networkGalleryUrls: _networkGalleryUrls,
                localGalleryFiles: _localGalleryFiles,
                onThumbnailSelected: (file) => setState(() => _thumbnailFile = file),
                onGallerySelected: (files) => setState(() => _localGalleryFiles.addAll(files)),
                onRemoveGalleryImage: (idx, isNetwork) {
                  setState(() {
                    if (isNetwork) {
                      _networkGalleryUrls.removeAt(idx);
                    } else {
                      _localGalleryFiles.removeAt(idx);
                    }
                  });
                },
                onReorderNetworkGallery: (oldIdx, newIdx) {
                  setState(() {
                    if (newIdx > oldIdx) newIdx -= 1;
                    final item = _networkGalleryUrls.removeAt(oldIdx);
                    _networkGalleryUrls.insert(newIdx, item);
                  });
                },
                specifications: _specifications,
                tags: _tags,
                onAddSpecification: _addSpecification,
                onRemoveSpecification: (key) => setState(() => _specifications.remove(key)),
                tagController: _tagController,
                onAddTag: () {
                  if (_tagController.text.trim().isNotEmpty) {
                    setState(() {
                      _tags.add(_tagController.text.trim());
                      _tagController.clear();
                    });
                  }
                },
                onRemoveTag: (tag) => setState(() => _tags.remove(tag)),
              ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
          onPressed: isLoading ? null : _submit,
          child: const Text('Update Product'),
        ),
      ),
    );
  }
}