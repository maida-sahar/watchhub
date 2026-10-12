import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../admin/brands/widgets/brand_form.dart';
import '../../providers/brand_provider.dart';

class AddBrandScreen extends StatefulWidget {
  const AddBrandScreen({super.key});

  @override
  State<AddBrandScreen> createState() => _AddBrandScreenState();
}

class _AddBrandScreenState extends State<AddBrandScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _countryController = TextEditingController();
  final _websiteController = TextEditingController();
  final _displayOrderController = TextEditingController(text: '0');

  XFile? _logoFile;
  XFile? _bannerFile;
  bool _isFeatured = false;
  bool _isActive = true;
  bool _isLoading = false;

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

    if (_logoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a brand logo')),
      );
      return;
    }

    if (_bannerFile == null) {
      // BrandProvider.createBrand() requires a non-nullable bannerFile
      // (that signature is locked, per this task's constraints), so a
      // banner must be selected before create can succeed here.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a brand banner')),
      );
      return;
    }

    final brandProvider = Provider.of<BrandProvider>(context, listen: false);

    // BrandProvider has no isBrandNameUnique() method — this is a fast,
    // in-memory client-side hint using brands already loaded by
    // BrandListScreen's loadBrands() call. BrandService.createBrand()
    // still performs the authoritative uniqueness check server-side.
    final enteredName = _nameController.text.trim().toLowerCase();
    final isDuplicate = brandProvider.brands
        .any((b) => b.name.trim().toLowerCase() == enteredName);
    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A brand with this name already exists')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // BrandProvider.createBrand() never throws — it catches internally
    // and reports failure via its return value + errorMessage, so this
    // reads the bool result instead of relying on try/catch.
    final success = await brandProvider.createBrand(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      country: _countryController.text.trim(),
      website: _websiteController.text.trim(),
      displayOrder: int.parse(_displayOrderController.text.trim()),
      isFeatured: _isFeatured,
      isActive: _isActive,
      logoFile: _logoFile!,
      bannerFile: _bannerFile!,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brand added successfully')),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            brandProvider.errorMessage ?? 'Failed to add brand',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Brand'),
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