import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../models/settings_model.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _storeNameController = TextEditingController();
  final _storeDescController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _deliveryChargeController = TextEditingController();
  final _taxRateController = TextEditingController();

  bool _deliveryAvailable = true;
  bool _orderAutoConfirm = true;
  bool _globalNotificationsEnabled = true;
  bool _maintenanceMode = false;
  String _selectedCurrency = 'USD';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadAdminSettings().then((_) {
        if (!mounted) return;
        final admin = context.read<SettingsProvider>().adminSettings;
        if (admin != null) {
          _storeNameController.text = admin.storeName;
          _storeDescController.text = admin.storeDescription;
          _phoneController.text = admin.phone;
          _emailController.text = admin.email;
          _addressController.text = admin.address;
          _cityController.text = admin.city;
          _deliveryChargeController.text = admin.defaultDeliveryCharge.toString();
          _taxRateController.text = admin.taxRate.toString();
          
          setState(() {
            _deliveryAvailable = admin.deliveryAvailable;
            _orderAutoConfirm = admin.orderAutoConfirm;
            _globalNotificationsEnabled = admin.globalNotificationsEnabled;
            _maintenanceMode = admin.maintenanceMode;
            _selectedCurrency = admin.currency;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeDescController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _deliveryChargeController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  Future<void> _saveAdminSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final settingsProv = context.read<SettingsProvider>();
    final currentAdmin = settingsProv.adminSettings ?? const AdminSettings();

    final double charge = double.tryParse(_deliveryChargeController.text.trim()) ?? 5.0;
    final double tax = double.tryParse(_taxRateController.text.trim()) ?? 0.0;

    final updated = currentAdmin.copyWith(
      storeName: _storeNameController.text.trim(),
      storeDescription: _storeDescController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      defaultDeliveryCharge: charge,
      taxRate: tax,
      deliveryAvailable: _deliveryAvailable,
      orderAutoConfirm: _orderAutoConfirm,
      globalNotificationsEnabled: _globalNotificationsEnabled,
      maintenanceMode: _maintenanceMode,
      currency: _selectedCurrency,
    );

    final success = await settingsProv.updateAdminSettings(updated);
    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Store settings updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(settingsProv.errorMessage ?? 'Failed to save store settings.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settingsProv = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: isDark ? Colors.black : AppColors.background,
      appBar: AppBar(
        title: const Text('Store Settings'),
        actions: [
          if (settingsProv.adminSettings != null)
            TextButton.icon(
              onPressed: settingsProv.isSaving ? null : _saveAdminSettings,
              icon: settingsProv.isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded, color: AppColors.primary),
              label: Text(
                'Save',
                style: TextStyle(
                  color: settingsProv.isSaving ? Colors.grey : AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: settingsProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : settingsProv.errorMessage != null && settingsProv.adminSettings == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(settingsProv.errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => settingsProv.loadAdminSettings(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SafeArea(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                      children: [
                        // Section 1: Store Information
                        _buildSectionHeader(theme, 'Store Information'),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _storeNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Store Name',
                                    prefixIcon: const Icon(Icons.store_rounded),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  validator: (val) => val == null || val.trim().isEmpty ? 'Store name is required' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _storeDescController,
                                  decoration: InputDecoration(
                                    labelText: 'Store Description',
                                    prefixIcon: const Icon(Icons.description_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 2: Contact Details
                        _buildSectionHeader(theme, 'Contact Details'),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    labelText: 'Contact Phone Number',
                                    prefixIcon: const Icon(Icons.phone_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: 'Contact Email Address',
                                    prefixIcon: const Icon(Icons.email_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 3: Store Location/Address
                        _buildSectionHeader(theme, 'Store Location'),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _addressController,
                                  decoration: InputDecoration(
                                    labelText: 'Complete Store Address',
                                    prefixIcon: const Icon(Icons.location_on_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _cityController,
                                  decoration: InputDecoration(
                                    labelText: 'City',
                                    prefixIcon: const Icon(Icons.location_city_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 4: Shipping & Order Settings
                        _buildSectionHeader(theme, 'Shipping & Order Configuration'),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                SwitchListTile(
                                  title: const Text('Delivery Available'),
                                  subtitle: const Text('Enable or disable delivery globally'),
                                  value: _deliveryAvailable,
                                  onChanged: (val) => setState(() => _deliveryAvailable = val),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                const Divider(height: 8),
                                TextFormField(
                                  controller: _deliveryChargeController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Default Delivery Charge (\$)',
                                    prefixIcon: const Icon(Icons.local_shipping_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Delivery charge is required';
                                    if (double.tryParse(val) == null) return 'Enter a valid decimal number';
                                    return null;
                                  },
                                ),
                                const Divider(height: 24),
                                SwitchListTile(
                                  title: const Text('Auto-Confirm Orders'),
                                  subtitle: const Text('Mark orders as processing automatically'),
                                  value: _orderAutoConfirm,
                                  onChanged: (val) => setState(() => _orderAutoConfirm = val),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 5: Global System & App preferences
                        _buildSectionHeader(theme, 'Global System Controls'),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                SwitchListTile(
                                  title: const Text('Maintenance Mode'),
                                  subtitle: const Text('Show a maintenance bulletin block to customers'),
                                  value: _maintenanceMode,
                                  onChanged: (val) => setState(() => _maintenanceMode = val),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                const Divider(height: 8),
                                SwitchListTile(
                                  title: const Text('Global Push Notifications'),
                                  subtitle: const Text('Allow sending of FCM broadcasts'),
                                  value: _globalNotificationsEnabled,
                                  onChanged: (val) => setState(() => _globalNotificationsEnabled = val),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                const Divider(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _selectedCurrency,
                                  decoration: InputDecoration(
                                    labelText: 'Default Marketplace Currency',
                                    prefixIcon: const Icon(Icons.monetization_on_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                                    DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                                    DropdownMenuItem(value: 'GBP', child: Text('GBP (£)')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedCurrency = val);
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _taxRateController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Tax Percentage (%)',
                                    prefixIcon: const Icon(Icons.percent_rounded),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Tax percentage is required';
                                    if (double.tryParse(val) == null) return 'Enter a valid decimal percentage';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
