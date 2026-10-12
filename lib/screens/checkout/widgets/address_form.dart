// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:watch_hub/config/app_colors.dart';
import 'package:watch_hub/config/clay_widgets.dart';
import 'package:watch_hub/models/checkout_model.dart';

class AddressForm extends StatefulWidget {
  final ShippingAddress? initialAddress;
  final Function(ShippingAddress) onSubmit;

  const AddressForm({
    super.key,
    this.initialAddress,
    required this.onSubmit,
  });

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _alternatePhoneController;
  late TextEditingController _countryController;
  late TextEditingController _provinceController;
  late TextEditingController _cityController;
  late TextEditingController _areaController;
  late TextEditingController _streetAddressController;
  late TextEditingController _postalCodeController;
  late TextEditingController _landmarkController;

  late String _addressType;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    final address = widget.initialAddress;

    _fullNameController = TextEditingController(text: address?.fullName ?? '');
    _phoneController = TextEditingController(text: address?.phone ?? '');
    _alternatePhoneController = TextEditingController(text: address?.alternatePhone ?? '');
    _countryController = TextEditingController(text: address?.country ?? 'United States');
    _provinceController = TextEditingController(text: address?.province ?? '');
    _cityController = TextEditingController(text: address?.city ?? '');
    _areaController = TextEditingController(text: address?.area ?? '');
    _streetAddressController = TextEditingController(text: address?.streetAddress ?? '');
    _postalCodeController = TextEditingController(text: address?.postalCode ?? '');
    _landmarkController = TextEditingController(text: address?.landmark ?? '');

    _addressType = address?.addressType ?? 'Home';
    _isDefault = address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _alternatePhoneController.dispose();
    _countryController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _streetAddressController.dispose();
    _postalCodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_isSubmitting) return;
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });
      try {
        final address = ShippingAddress(
          id: widget.initialAddress?.id ?? '',
          userId: widget.initialAddress?.userId ?? '',
          fullName: _fullNameController.text.trim(),
          phone: _phoneController.text.trim(),
          alternatePhone: _alternatePhoneController.text.trim().isEmpty ? null : _alternatePhoneController.text.trim(),
          country: _countryController.text.trim(),
          province: _provinceController.text.trim(),
          city: _cityController.text.trim(),
          area: _areaController.text.trim(),
          streetAddress: _streetAddressController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
          landmark: _landmarkController.text.trim().isEmpty ? null : _landmarkController.text.trim(),
          addressType: _addressType,
          isDefault: _isDefault,
          createdAt: widget.initialAddress?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await widget.onSubmit(address);
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialAddress == null ? 'Add Shipping Address' : 'Edit Address'),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionHeader('Contact Information'),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _fullNameController,
                  label: 'Full Name',
                  hint: 'John Doe',
                  validator: (val) => val == null || val.trim().isEmpty ? 'Full name is required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hint: '+123456789',
                        keyboardType: TextInputType.phone,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Phone is required';
                          }
                          final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
                          final normalized = val.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
                          if (!phoneRegex.hasMatch(normalized)) {
                            return 'Invalid format';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _alternatePhoneController,
                        label: 'Alternate Phone',
                        hint: 'Optional',
                        keyboardType: TextInputType.phone,
                        validator: (val) {
                          if (val != null && val.trim().isNotEmpty) {
                            final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
                            final normalized = val.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
                            if (!phoneRegex.hasMatch(normalized)) {
                              return 'Invalid format';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Address Details'),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _streetAddressController,
                  label: 'Street Address',
                  hint: 'Apt, Suite, Street name',
                  validator: (val) => val == null || val.trim().isEmpty ? 'Street address is required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _areaController,
                        label: 'Area / Neighborhood',
                        hint: 'Downtown',
                        validator: (val) => val == null || val.trim().isEmpty ? 'Area is required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _cityController,
                        label: 'City',
                        hint: 'New York',
                        validator: (val) => val == null || val.trim().isEmpty ? 'City is required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _provinceController,
                        label: 'Province / State',
                        hint: 'NY',
                        validator: (val) => val == null || val.trim().isEmpty ? 'Province is required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _postalCodeController,
                        label: 'Postal Code',
                        hint: '10001',
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Postal code required';
                          }
                          if (val.trim().length < 3 || val.trim().length > 10) {
                            return '3-10 chars';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _countryController,
                        label: 'Country',
                        hint: 'USA',
                        validator: (val) => val == null || val.trim().isEmpty ? 'Country is required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _landmarkController,
                        label: 'Landmark',
                        hint: 'Near library (Optional)',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Address Type'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAddressTypeOption('Home', Icons.home_rounded),
                    _buildAddressTypeOption('Office', Icons.business_rounded),
                    _buildAddressTypeOption('Other', Icons.location_on_rounded),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  value: _isDefault,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      _isDefault = val;
                    });
                  },
                  title: Text(
                    'Set as default address',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'This address will be automatically pre-selected for future checkouts.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 32),
                ClayButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.initialAddress == null ? 'Save Address' : 'Update Address',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textTertiary,
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border, width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.0),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.error, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.error, width: 1.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressTypeOption(String type, IconData icon) {
    final isSelected = _addressType == type;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          _addressType = type;
        });
      },
      child: ClayCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        borderRadius: 16,
        shadows: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              type,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
