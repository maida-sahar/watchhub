import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'brand_dropdown.dart';
import 'category_dropdown.dart';
import 'image_gallery.dart';
import 'inventory_section.dart';
import 'price_section.dart';
import 'product_images_picker.dart';
import 'specifications_section.dart';
import 'status_switches.dart';
import 'tags_section.dart';

class ProductForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController shortDescController;
  final TextEditingController descController;
  final TextEditingController priceController;
  final TextEditingController discountPriceController;
  final TextEditingController skuController;
  final TextEditingController stockController;
  final TextEditingController minStockController;

  final String? selectedCategoryId;
  final String? selectedBrandId;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onBrandChanged;

  final bool isActive;
  final bool isFeatured;
  final bool isBestSeller;
  final bool isNewArrival;
  final ValueChanged<bool> onActiveChanged;
  final ValueChanged<bool> onFeaturedChanged;
  final ValueChanged<bool> onBestSellerChanged;
  final ValueChanged<bool> onNewArrivalChanged;

  final XFile? thumbnailFile;
  final String? networkThumbnailUrl;
  final List<String> networkGalleryUrls;
  final List<XFile> localGalleryFiles;
  final ValueChanged<XFile?> onThumbnailSelected;
  final Function(List<XFile>) onGallerySelected;
  final Function(int index, bool isNetwork) onRemoveGalleryImage;
  final Function(int oldIdx, int newIdx) onReorderNetworkGallery;

  final Map<String, String> specifications;
  final List<String> tags;
  final VoidCallback onAddSpecification;
  final Function(String key) onRemoveSpecification;
  final TextEditingController tagController;
  final VoidCallback onAddTag;
  final Function(String tag) onRemoveTag;

  const ProductForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.shortDescController,
    required this.descController,
    required this.priceController,
    required this.discountPriceController,
    required this.skuController,
    required this.stockController,
    required this.minStockController,
    required this.selectedCategoryId,
    required this.selectedBrandId,
    required this.onCategoryChanged,
    required this.onBrandChanged,
    required this.isActive,
    required this.isFeatured,
    required this.isBestSeller,
    required this.isNewArrival,
    required this.onActiveChanged,
    required this.onFeaturedChanged,
    required this.onBestSellerChanged,
    required this.onNewArrivalChanged,
    required this.thumbnailFile,
    required this.networkThumbnailUrl,
    required this.networkGalleryUrls,
    required this.localGalleryFiles,
    required this.onThumbnailSelected,
    required this.onGallerySelected,
    required this.onRemoveGalleryImage,
    required this.onReorderNetworkGallery,
    required this.specifications,
    required this.tags,
    required this.onAddSpecification,
    required this.onRemoveSpecification,
    required this.tagController,
    required this.onAddTag,
    required this.onRemoveTag,
  });

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickThumbnail() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      widget.onThumbnailSelected(image);
    }
  }

  Future<void> _pickGallery() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      widget.onGallerySelected(images);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ProductImagesPicker(
              thumbnailFile: widget.thumbnailFile,
              networkThumbnailUrl: widget.networkThumbnailUrl,
              onPickThumbnail: _pickThumbnail,
              onPickGallery: _pickGallery,
            ),
            const SizedBox(height: 12),
            ImageGallery(
              networkImages: widget.networkGalleryUrls,
              localImages: widget.localGalleryFiles,
              onRemove: widget.onRemoveGalleryImage,
              onReorderNetwork: widget.onReorderNetworkGallery,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: widget.nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name *',
                border: OutlineInputBorder(),
              ),
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'Product Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.shortDescController,
              decoration: const InputDecoration(
                labelText: 'Short Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.descController,
              decoration: const InputDecoration(
                labelText: 'Full Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CategoryDropdown(
                    selectedCategoryId: widget.selectedCategoryId,
                    onChanged: widget.onCategoryChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BrandDropdown(
                    selectedBrandId: widget.selectedBrandId,
                    onChanged: widget.onBrandChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            PriceSection(
              priceController: widget.priceController,
              discountPriceController: widget.discountPriceController,
              selectedCurrency: 'USD',
              onCurrencyChanged: (_) {},
            ),
            const SizedBox(height: 16),
            InventorySection(
              skuController: widget.skuController,
              stockController: widget.stockController,
              minStockController: widget.minStockController,
            ),
            const SizedBox(height: 16),
            SpecificationsSection(
              specifications: widget.specifications,
              onAddSpec: widget.onAddSpecification,
              onRemoveSpec: widget.onRemoveSpecification,
            ),
            const SizedBox(height: 16),
            TagsSection(
              tags: widget.tags,
              tagController: widget.tagController,
              onAddTag: widget.onAddTag,
              onRemoveTag: widget.onRemoveTag,
            ),
            const SizedBox(height: 16),
            StatusSwitches(
              isActive: widget.isActive,
              isFeatured: widget.isFeatured,
              isBestSeller: widget.isBestSeller,
              isNewArrival: widget.isNewArrival,
              onActiveChanged: widget.onActiveChanged,
              onFeaturedChanged: widget.onFeaturedChanged,
              onBestSellerChanged: widget.onBestSellerChanged,
              onNewArrivalChanged: widget.onNewArrivalChanged,
            ),
          ],
        ),
      ),
    );
  }
}