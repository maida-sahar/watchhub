import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/user_provider.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _photoUrl;
  bool _avatarLoadFailed = false;
  String _selectedTheme = 'system';
  String _selectedLanguage = 'en';
  bool _compactMode = false;

  bool _pushEnabled = true;
  bool _orderEnabled = true;
  bool _promotionEnabled = true;
  bool _wishlistEnabled = true;
  bool _reviewEnabled = true;
  bool _systemEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated && auth.user != null) {
        context.read<SettingsProvider>().loadSettings(auth.user!.uid).then((_) {
          if (!mounted) return;
          final settings = context.read<SettingsProvider>().settings;
          if (settings != null) {
            _nameController.text = settings.profile.name;
            _phoneController.text = settings.profile.phone;
            setState(() {
              _photoUrl = settings.profile.photoUrl;
              _avatarLoadFailed = false;
              _selectedTheme = settings.appPreferences.theme;
              _selectedLanguage = settings.appPreferences.language;
              _compactMode = settings.appPreferences.compactMode;

              _pushEnabled = settings.notifications.pushEnabled;
              _orderEnabled = settings.notifications.orderEnabled;
              _promotionEnabled = settings.notifications.promotionEnabled;
              _wishlistEnabled = settings.notifications.wishlistEnabled;
              _reviewEnabled = settings.notifications.reviewEnabled;
              _systemEnabled = settings.notifications.systemEnabled;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final auth = context.read<AuthProvider>();
    final userProv = context.read<UserProvider>();
    final picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image == null) return;

      final newUrl = await userProv.updateUserProfilePicture(
        uid: auth.currentUid!,
        imageFile: image,
        role: auth.currentRole!,
      );

      if (newUrl != null) {
        setState(() {
          _photoUrl = newUrl;
          _avatarLoadFailed = false;
        });

        if (mounted) {
          final settingsProv = context.read<SettingsProvider>();
          final currentSettings = settingsProv.settings;
          if (currentSettings != null) {
            final updatedSettings = currentSettings.copyWith(
              profile: currentSettings.profile.copyWith(photoUrl: newUrl),
            );
            settingsProv.updateSettings(updatedSettings);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else if (userProv.profilePictureError != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userProv.profilePictureError!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking/uploading image: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<SettingsProvider>();
    final auth = context.read<AuthProvider>();
    final currentSettings = provider.settings;
    if (currentSettings == null) return;

    final updated = currentSettings.copyWith(
      profile: currentSettings.profile.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        photoUrl: _photoUrl ?? currentSettings.profile.photoUrl,
      ),
      notifications: currentSettings.notifications.copyWith(
        pushEnabled: _pushEnabled,
        orderEnabled: _orderEnabled,
        promotionEnabled: _promotionEnabled,
        wishlistEnabled: _wishlistEnabled,
        reviewEnabled: _reviewEnabled,
        systemEnabled: _systemEnabled,
      ),
      appPreferences: currentSettings.appPreferences.copyWith(
        theme: _selectedTheme,
        language: _selectedLanguage,
        compactMode: _compactMode,
      ),
    );

    final success = await provider.updateSettings(updated);
    if (success) {
      await auth.checkUserRole();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to save settings.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final settingsProv = context.watch<SettingsProvider>();
    final userProv = context.watch<UserProvider>();

    if (!auth.isAuthenticated || auth.user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view settings.')),
      );
    }

    final user = auth.user!;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          if (settingsProv.settings != null)
            TextButton.icon(
              onPressed: settingsProv.isSaving ? null : _saveSettings,
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
          : settingsProv.errorMessage != null && settingsProv.settings == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(settingsProv.errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => settingsProv.loadSettings(user.uid),
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
                        // Profile Avatar Section
                        Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                backgroundImage: _photoUrl != null && _photoUrl!.isNotEmpty && !_avatarLoadFailed
                                    ? CachedNetworkImageProvider(_photoUrl!)
                                    : null,
                                // A broken/expired photo URL must not crash the
                                // screen or leave a permanently-blank avatar —
                                // fall back to the default person icon instead.
                                onBackgroundImageError: (_photoUrl != null && _photoUrl!.isNotEmpty)
                                    ? (_, __) {
                                        if (mounted && !_avatarLoadFailed) {
                                          setState(() => _avatarLoadFailed = true);
                                        }
                                      }
                                    : null,
                                child: _photoUrl == null || _photoUrl!.isEmpty || _avatarLoadFailed
                                    ? const Icon(Icons.person_rounded, size: 50, color: AppColors.primary)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: InkWell(
                                  onTap: userProv.isUploadingProfilePicture ? null : _pickAndUploadImage,
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.primary,
                                    child: userProv.isUploadingProfilePicture
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Section 1: Profile Settings
                        _buildSectionHeader(theme, 'Profile Information'),
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
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Full Name',
                                    prefixIcon: const Icon(Icons.person_outline_rounded),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  validator: (val) => val == null || val.trim().isEmpty ? 'Name cannot be empty' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    labelText: 'Phone Number',
                                    prefixIcon: const Icon(Icons.phone_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Email (Read Only)
                                TextFormField(
                                  initialValue: user.email,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Email Address (Linked)',
                                    prefixIcon: const Icon(Icons.email_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    filled: true,
                                    fillColor: isDark ? Colors.white10 : Colors.grey[100],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 2: Notification Preferences
                        _buildSectionHeader(theme, 'Notification Preferences'),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              children: [
                                SwitchListTile(
                                  title: const Text('Push Notifications'),
                                  subtitle: const Text('Globally enable/disable push alerts'),
                                  secondary: const Icon(Icons.notifications_active_outlined),
                                  value: _pushEnabled,
                                  onChanged: (val) => setState(() => _pushEnabled = val),
                                ),
                                const Divider(height: 8),
                                AbsorbPointer(
                                  absorbing: !_pushEnabled,
                                  child: Opacity(
                                    opacity: _pushEnabled ? 1.0 : 0.5,
                                    child: Column(
                                      children: [
                                        SwitchListTile(
                                          title: const Text('Order Updates'),
                                          subtitle: const Text('Confimations, shipping, and delivery notifications'),
                                          secondary: const Icon(Icons.receipt_long_outlined),
                                          value: _orderEnabled,
                                          onChanged: (val) => setState(() => _orderEnabled = val),
                                        ),
                                        const Divider(height: 8),
                                        SwitchListTile(
                                          title: const Text('Promotional & Deals'),
                                          subtitle: const Text('Flash sales, coupon releases, and discount codes'),
                                          secondary: const Icon(Icons.local_offer_outlined),
                                          value: _promotionEnabled,
                                          onChanged: (val) => setState(() => _promotionEnabled = val),
                                        ),
                                        const Divider(height: 8),
                                        SwitchListTile(
                                          title: const Text('Wishlist Alerts'),
                                          subtitle: const Text('Price drops on your favorited watches'),
                                          secondary: const Icon(Icons.favorite_border_rounded),
                                          value: _wishlistEnabled,
                                          onChanged: (val) => setState(() => _wishlistEnabled = val),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 3: App Preferences
                        _buildSectionHeader(theme, 'App Settings'),
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
                                DropdownButtonFormField<String>(
                                  value: _selectedTheme,
                                  decoration: InputDecoration(
                                    labelText: 'Interface Mode',
                                    prefixIcon: const Icon(Icons.brightness_medium_rounded),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'system', child: Text('System Default')),
                                    DropdownMenuItem(value: 'light', child: Text('Light Mode')),
                                    DropdownMenuItem(value: 'dark', child: Text('Dark Mode')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedTheme = val);
                                  },
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _selectedLanguage,
                                  decoration: InputDecoration(
                                    labelText: 'App Language',
                                    prefixIcon: const Icon(Icons.language_rounded),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'en', child: Text('English (US)')),
                                    DropdownMenuItem(value: 'es', child: Text('Español (ES)')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedLanguage = val);
                                  },
                                ),
                                const SizedBox(height: 8),
                                SwitchListTile(
                                  title: const Text('Compact Layout'),
                                  subtitle: const Text('Denser listings for easier scanning'),
                                  secondary: const Icon(Icons.view_headline_rounded),
                                  value: _compactMode,
                                  onChanged: (val) => setState(() => _compactMode = val),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 4: Account Information
                        _buildSectionHeader(theme, 'Account Security'),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.fingerprint_rounded, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'User Identifier (UID)',
                                            style: theme.textTheme.labelMedium?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            user.uid,
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Row(
                                  children: [
                                    const Icon(Icons.date_range_rounded, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Joined Date',
                                            style: theme.textTheme.labelMedium?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            user.createdAt.toLocal().toString().substring(0, 16),
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Logout Button
                        SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.error),
                              foregroundColor: AppColors.error,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Log Out Account', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Log Out'),
                                  content: const Text('Are you sure you want to log out of WatchHub?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Log Out'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await auth.logout();
                              }
                            },
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
