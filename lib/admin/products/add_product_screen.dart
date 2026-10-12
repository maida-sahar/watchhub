import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/brand_provider.dart';
import '../../utils/price_parser.dart';
import 'widgets/product_form.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _shortDescController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _skuController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _tagController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedBrandId;

  bool _isActive = true;
  bool _isFeatured = false;
  bool _isBestSeller = false;
  bool _isNewArrival = true;

  XFile? _thumbnailFile;
  final List<XFile> _localGalleryFiles = [];
  final Map<String, String> _specifications = {};
  final List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<CategoryProvider>(context, listen: false).loadCategories();
      Provider.of<BrandProvider>(context, listen: false).loadBrands();
    });
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
            TextField(controller: keyController, decoration: const InputDecoration(labelText: 'Feature (e.g. Movement)')),
            TextField(controller: valueController, decoration: const InputDecoration(labelText: 'Value (e.g. Automatic)')),
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
    if (_thumbnailFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product thumbnail is required')),
      );
      return;
    }

    // Use the shared sanitizing parser here too — not double.parse/
    // double.tryParse directly — so a currency-formatted value like
    // "$ 12,500" that passed PriceSection's validator parses to the
    // same 12500.0 here, instead of throwing/returning null.
    final double basePrice = PriceParser.tryParse(_priceController.text) ?? 0;
    final double? parsedDiscount = _discountPriceController.text.trim().isNotEmpty
        ? PriceParser.tryParse(_discountPriceController.text)
        : null;
    final bool hasDiscount =
        parsedDiscount != null && parsedDiscount > 0 && parsedDiscount < basePrice;
    // `discountPercentage` isn't a separate form field — it's derived from
    // price/discountPrice so the "-X%" badge shown on product cards has a
    // real value instead of always reading 0.
    final double discountPercentage =
        hasDiscount ? ((basePrice - parsedDiscount) / basePrice) * 100 : 0.0;

    // Denormalize category/brand display names onto the product at write
    // time — ProductModel.categoryName/brandName exist specifically so the
    // User App can show/search/filter by category & brand name without an
    // extra Firestore lookup per product. Both provider lists are already
    // loaded (see initState), so this is a pure in-memory lookup.
    final matchedCategories = Provider.of<CategoryProvider>(context, listen: false)
        .categories
        .where((c) => c.id == _selectedCategoryId);
    final categoryName =
        matchedCategories.isNotEmpty ? matchedCategories.first.name : '';

    final matchedBrands = Provider.of<BrandProvider>(context, listen: false)
        .brands
        .where((b) => b.id == _selectedBrandId);
    final brandName = matchedBrands.isNotEmpty ? matchedBrands.first.name : '';

    final newProduct = ProductModel(
      id: '',
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      shortDescription: _shortDescController.text.trim(),
      price: basePrice,
      discountPrice: hasDiscount ? parsedDiscount : basePrice,
      discountPercentage: discountPercentage,
      sku: _skuController.text.trim(),
      stock: int.parse(_stockController.text.trim()),
      minimumStock: _minStockController.text.isNotEmpty
          ? int.parse(_minStockController.text.trim())
          : 5,
      categoryId: _selectedCategoryId!,
      categoryName: categoryName,
      brandId: _selectedBrandId!,
      brandName: brandName,
      isActive: _isActive,
      isFeatured: _isFeatured,
      isBestSeller: _isBestSeller,
      isNewArrival: _isNewArrival,
      thumbnail: '',
      galleryImages: [],
      specifications: _specifications,
      tags: _tags,
      createdAt: DateTime.now(),
       updatedAt: DateTime.now(),
    );

    try {
      // ProductProvider.createProduct returns a bool and swallows its own
      // exceptions (see _runGuardedBool) rather than throwing — so it
      // previously fell straight through to Navigator.pop() below
      // regardless of whether the product actually saved. That silently
      // reported success even when the Firestore write failed after the
      // image upload had already succeeded. The bool must be checked.
      final provider = Provider.of<ProductProvider>(context, listen: false);
      final success = await provider.createProduct(
        newProduct,
        thumbnailFile: _thumbnailFile!,
        galleryFiles: _localGalleryFiles,
      );
      if (!mounted) return;
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add product: ${provider.errorMessage ?? 'Unknown error'}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding product: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<ProductProvider>(context).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
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
              onActiveChanged: (val) => setState(() => _isActive = val),
              onFeaturedChanged: (val) => setState(() => _isFeatured = val),
              onBestSellerChanged: (val) => setState(() => _isBestSeller = val),
              onNewArrivalChanged: (val) => setState(() => _isNewArrival = val),
              thumbnailFile: _thumbnailFile,
              networkThumbnailUrl: null,
              networkGalleryUrls: const [],
              localGalleryFiles: _localGalleryFiles,
              onThumbnailSelected: (file) => setState(() => _thumbnailFile = file),
              onGallerySelected: (files) => setState(() => _localGalleryFiles.addAll(files)),
              onRemoveGalleryImage: (idx, isNetwork) {
                setState(() => _localGalleryFiles.removeAt(idx));
              },
              onReorderNetworkGallery: (_, __) {},
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
          child: const Text('Save Product'),
        ),
      ),
    );
  }
}