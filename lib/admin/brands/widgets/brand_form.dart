import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../admin/brands/widgets/brand_banner_picker.dart';
import '../../../admin/brands/widgets/brand_logo_picker.dart';
import '../../../admin/brands/widgets/display_order_field.dart';
import '../../../admin/brands/widgets/featured_switch.dart';

class BrandForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController countryController;
  final TextEditingController websiteController;
  final TextEditingController displayOrderController;
  final bool isFeatured;
  final bool isActive;
  final String? initialLogoUrl;
  final String? initialBannerUrl;
  final ValueChanged<XFile?> onLogoSelected;
  final ValueChanged<XFile?> onBannerSelected;
  final ValueChanged<bool> onFeaturedChanged;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onSubmit;
  final bool isLoading;

  const BrandForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.descriptionController,
    required this.countryController,
    required this.websiteController,
    required this.displayOrderController,
    required this.isFeatured,
    required this.isActive,
    this.initialLogoUrl,
    this.initialBannerUrl,
    required this.onLogoSelected,
    required this.onBannerSelected,
    required this.onFeaturedChanged,
    required this.onActiveChanged,
    required this.onSubmit,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          BrandLogoPicker(
            initialImageUrl: initialLogoUrl,
            onImageSelected: onLogoSelected,
          ),
          const SizedBox(height: 16),
          BrandBannerPicker(
            initialImageUrl: initialBannerUrl,
            onImageSelected: onBannerSelected,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Brand Name *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.branding_watermark),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Brand name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: countryController,
            decoration: const InputDecoration(
              labelText: 'Country',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.flag),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: websiteController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Website URL',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.language),
            ),
          ),
          const SizedBox(height: 16),
          DisplayOrderField(controller: displayOrderController),
          const SizedBox(height: 16),
          FeaturedSwitch(
            value: isFeatured,
            onChanged: onFeaturedChanged,
          ),
          SwitchListTile.adaptive(
            title: const Text('Active Brand'),
            subtitle: const Text('Inactive brands are hidden from the User App'),
            value: isActive,
            onChanged: onActiveChanged,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isLoading
                ? const CircularProgressIndicator()
                : const Text('Save Brand', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}