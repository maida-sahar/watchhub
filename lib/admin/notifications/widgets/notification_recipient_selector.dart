import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../config/clay_widgets.dart';
import '../../../providers/user_provider.dart';

class NotificationRecipientSelector extends StatefulWidget {
  final String initialRecipientType;
  final String? initialRecipientRole;
  final List<String> initialRecipientIds;

  const NotificationRecipientSelector({
    super.key,
    required this.initialRecipientType,
    this.initialRecipientRole,
    required this.initialRecipientIds,
  });

  @override
  State<NotificationRecipientSelector> createState() => _NotificationRecipientSelectorState();
}

class _NotificationRecipientSelectorState extends State<NotificationRecipientSelector> {
  late String _recipientType; // 'all', 'role', 'users'
  String? _recipientRole; // 'customer', 'admin'
  late List<String> _selectedUserIds;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _recipientType = widget.initialRecipientType;
    _recipientRole = widget.initialRecipientRole ?? 'customer';
    _selectedUserIds = List.from(widget.initialRecipientIds);

    // Watch users data immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().watchCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            // Filter user list locally based on text input
            final allCustomers = userProvider.customers;
            final filteredCustomers = allCustomers.where((u) {
              final query = _searchQuery.toLowerCase();
              return u.name.toLowerCase().contains(query) ||
                  u.email.toLowerCase().contains(query);
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Recipients',
                      style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: AppColors.divider, height: 24),
                
                // Recipient Type Chips
                Text(
                  'Target Group Type',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _typeChip('all', 'All Users', Icons.group_rounded),
                    const SizedBox(width: 10),
                    _typeChip('role', 'By User Role', Icons.badge_rounded),
                    const SizedBox(width: 10),
                    _typeChip('users', 'Selected Users', Icons.person_add_rounded),
                  ],
                ),
                const SizedBox(height: 20),

                // Sub-panels based on selected type
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _buildSubSelectionPanel(userProvider, filteredCustomers),
                  ),
                ),

                const Divider(color: AppColors.divider, height: 24),
                
                // Confirm buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text(
                          'Cancel',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ClayButton(
                        onPressed: () {
                          // Validate select users count
                          if (_recipientType == 'users' && _selectedUserIds.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select at least one user.'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }
                          Navigator.pop(context, {
                            'recipientType': _recipientType,
                            'recipientRole': _recipientType == 'role' ? _recipientRole : null,
                            'recipientIds': _recipientType == 'users' ? _selectedUserIds : <String>[],
                          });
                        },
                        child: Text(
                          'Save Selection',
                          style: AppTypography.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _typeChip(String type, String label, IconData icon) {
    final isSelected = _recipientType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _recipientType = type;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.08) : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 20),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubSelectionPanel(UserProvider userProvider, List<dynamic> filteredCustomers) {
    if (_recipientType == 'all') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group_rounded, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              'Notification will be broadcasted to all users in the system.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_recipientType == 'role') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Target Role',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Customers'),
                  selected: _recipientRole == 'customer',
                  selectedColor: AppColors.primary.withOpacity(0.12),
                  backgroundColor: AppColors.surface,
                  labelStyle: AppTypography.bodyLarge.copyWith(
                    fontWeight: _recipientRole == 'customer' ? FontWeight.bold : FontWeight.normal,
                    color: _recipientRole == 'customer' ? AppColors.primary : AppColors.textSecondary,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _recipientRole = 'customer';
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Administrators'),
                  selected: _recipientRole == 'admin',
                  selectedColor: AppColors.primary.withOpacity(0.12),
                  backgroundColor: AppColors.surface,
                  labelStyle: AppTypography.bodyLarge.copyWith(
                    fontWeight: _recipientRole == 'admin' ? FontWeight.bold : FontWeight.normal,
                    color: _recipientRole == 'admin' ? AppColors.primary : AppColors.textSecondary,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _recipientRole = 'admin';
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Specific Users target
    return Column(
      children: [
        // Search user field
        ClayCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          borderRadius: 16,
          child: TextField(
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search user name or email...',
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              border: InputBorder.none,
              hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
            ),
            style: AppTypography.bodyMedium,
          ),
        ),
        const SizedBox(height: 12),
        // Selection count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Selected: ${_selectedUserIds.length} users',
              style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            if (_selectedUserIds.isNotEmpty)
              TextButton(
                onPressed: () => setState(() {
                  _selectedUserIds.clear();
                }),
                child: const Text('Clear Selection'),
              ),
          ],
        ),
        // Customer checklist
        Expanded(
          child: userProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredCustomers.isEmpty
                  ? Center(child: Text('No users match search criteria.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)))
                  : ListView.builder(
                      itemCount: filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final u = filteredCustomers[index];
                        final isChecked = _selectedUserIds.contains(u.uid);

                        return CheckboxListTile(
                          value: isChecked,
                          title: Text(u.name, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                          subtitle: Text(u.email, style: AppTypography.bodySmall),
                          activeColor: AppColors.primary,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedUserIds.add(u.uid);
                              } else {
                                _selectedUserIds.remove(u.uid);
                              }
                            });
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
