import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../models/brand_model.dart';
import '../../../providers/brand_provider.dart';
import 'widgets/brand_form.dart';

class EditBrandScreen extends StatefulWidget {
  final BrandModel brand;

  const EditBrandScreen({super.key, required this.brand});

  @override
  State<EditBrandScreen> createState() => _EditBrandScreenState();
}

class _EditBrandScreenState extends State<EditBrandScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _countryController;
  late TextEditingController _websiteController;
  late TextEditingController _displayOrderController;

  XFile? _logoFile;
  XFile? _bannerFile;
  late bool _isFeatured;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.brand.name);
    _descriptionController =
        TextEditingController(text: widget.brand.description);
    _countryController = TextEditingController(text: widget.brand.country);
    _websiteController = TextEditingController(text: widget.brand.website);
    _displayOrderController =
        TextEditingController(text: widget.brand.displayOrder.toString());
    _isFeatured = widget.brand.isFeatured;
    _isActive = widget.brand.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _countryController.dispose();
    _websiteController.dispose();
    _displayOrderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final brandProvider = Provider.of<BrandProvider>(context, listen: false);

    // Validate duplicate name check locally before issuing server mutation
    if (_nameController.text.trim().toLowerCase() !=
        widget.brand.name.toLowerCase()) {
      final isUnique =
          brandProvider.isBrandNameUnique(_nameController.text.trim());
      if (!isUnique) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A brand with this name already exists.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedBrand = widget.brand.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        country: _countryController.text.trim(),
        website: _websiteController.text.trim(),
        displayOrder:
            int.tryParse(_displayOrderController.text.trim()) ?? widget.brand.displayOrder,
        isFeatured: _isFeatured,
        isActive: _isActive,
      );

      await brandProvider.updateBrand(
        updatedBrand,
        newLogoFile: _logoFile,
        newBannerFile: _bannerFile,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Brand updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update brand: ${e.toString().replaceAll('BrandRepositoryException: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Brand'),
      ),
      body: BrandForm(
        formKey: _formKey,
        nameController: _nameController,
        descriptionController: _descriptionController,
        countryController: _countryController,
        websiteController: _websiteController,
        displayOrderController: _displayOrderController,
        isFeatured: _isFeatured,
        isActive: _isActive,
        initialLogoUrl: widget.brand.logoUrl,
        initialBannerUrl: widget.brand.bannerUrl,
        onLogoSelected: (file) => _logoFile = file,
        onBannerSelected: (file) => _bannerFile = file,
        onFeaturedChanged: (val) => setState(() => _isFeatured = val),
        onActiveChanged: (val) => setState(() => _isActive = val),
        onSubmit: _submit,
        isLoading: _isLoading,
      ),
    );
  }
}