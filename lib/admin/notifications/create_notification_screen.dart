import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_typography.dart';
import '../../config/clay_widgets.dart';
import '../../providers/notification_provider.dart';
import 'widgets/notification_recipient_selector.dart';

class CreateNotificationScreen extends StatefulWidget {
  const CreateNotificationScreen({super.key});

  @override
  State<CreateNotificationScreen> createState() => _CreateNotificationScreenState();
}

class _CreateNotificationScreenState extends State<CreateNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  String _selectedType = 'system'; // 'order', 'product', 'wishlist', 'promotion', 'review', 'system'
  String _recipientType = 'all'; // 'all', 'role', 'users'
  String? _recipientRole = 'customer';
  List<String> _recipientIds = [];

  final List<String> _typesList = ['order', 'product', 'wishlist', 'promotion', 'review', 'system'];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _openRecipientSelector() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationRecipientSelector(
        initialRecipientType: _recipientType,
        initialRecipientRole: _recipientRole,
        initialRecipientIds: _recipientIds,
      ),
    );

    if (result != null) {
      setState(() {
        _recipientType = result['recipientType'] as String;
        _recipientRole = result['recipientRole'] as String?;
        _recipientIds = List<String>.from(result['recipientIds'] ?? []);
      });
    }
  }

  String _getTargetDescription() {
    switch (_recipientType) {
      case 'all':
        return 'All System Users';
      case 'role':
        return 'Role: ${_recipientRole == "customer" ? "Customers Only" : "Administrators Only"}';
      case 'users':
        return 'Selected: ${_recipientIds.length} users';
      default:
        return 'Unselected';
    }
  }

  Future<void> _submit(NotificationProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await provider.createNotification(
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      type: _selectedType,
      recipientType: _recipientType,
      recipientRole: _recipientRole,
      recipientIds: _recipientIds,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification broadcasted successfully.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.processError ?? 'Failed to send notification.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Compose Notification',
          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Recipient Selector Row
                Text(
                  'Recipient Target Group',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _openRecipientSelector,
                  borderRadius: BorderRadius.circular(20),
                  child: ClayCard(
                    borderRadius: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.people_alt_rounded, color: AppColors.primary, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Target Recipient Group',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getTargetDescription(),
                                style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.edit_rounded, color: AppColors.textSecondary, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Type selector
                Text(
                  'Notification Type / Topic',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _typesList.map((type) {
                    final isSelected = _selectedType == type;
                    return ChoiceChip(
                      label: Text(type.toUpperCase()),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withOpacity(0.12),
                      backgroundColor: AppColors.surface,
                      labelStyle: AppTypography.bodyMedium.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedType = type;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // 3. Message Compose
                Text(
                  'Message Content',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                // Title Field
                ClayCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  borderRadius: 20,
                  child: TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Enter notification title...',
                      border: InputBorder.none,
                      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                    ),
                    style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Body Field
                ClayCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  borderRadius: 20,
                  child: TextFormField(
                    controller: _bodyController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Enter notification body message...',
                      border: InputBorder.none,
                      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                    ),
                    style: AppTypography.bodyMedium,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Body message is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 36),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ClayButton(
                    onPressed: provider.isProcessing ? null : () => _submit(provider),
                    child: provider.isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          )
                        : Text(
                            'Send Notification',
                            style: AppTypography.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
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
}
