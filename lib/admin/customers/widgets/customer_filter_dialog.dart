import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../config/clay_widgets.dart';
import '../../../providers/user_provider.dart';

class CustomerFilterDialog extends StatefulWidget {
  const CustomerFilterDialog({super.key});

  @override
  State<CustomerFilterDialog> createState() => _CustomerFilterDialogState();
}

class _CustomerFilterDialogState extends State<CustomerFilterDialog> {
  late String _selectedType;
  DateTimeRange? _selectedRange;

  final Map<String, String> _filterOptions = {
    'all': 'All Customers',
    'active': 'Active Customers',
    'inactive': 'Inactive Customers',
    'new': 'New Customers',
    'with_orders': 'With Orders',
    'without_orders': 'Without Orders',
    'top_spending': 'Top Spending Customers',
  };

  @override
  void initState() {
    super.initState();
    final provider = context.read<UserProvider>();
    _selectedType = provider.filterType;
    _selectedRange = provider.dateRange;
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _selectedRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedRange = picked;
      });
    }
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: AppColors.divider, height: 24),
            Text(
              'Customer Type',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _filterOptions.entries.map((entry) {
                final isSelected = _selectedType == entry.key;
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withOpacity(0.12),
                  disabledColor: AppColors.surface,
                  backgroundColor: AppColors.surface,
                  labelStyle: AppTypography.bodyMedium.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedType = entry.key;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Join Date Range',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectDateRange,
              borderRadius: BorderRadius.circular(16),
              child: ClayCard(
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedRange == null
                            ? 'Select date range'
                            : '${DateFormat('MMM dd, yyyy').format(_selectedRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedRange!.end)}',
                        style: AppTypography.bodyMedium.copyWith(
                          color: _selectedRange == null ? AppColors.textSecondary : AppColors.textPrimary,
                          fontWeight: _selectedRange == null ? FontWeight.normal : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_selectedRange != null)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          setState(() {
                            _selectedRange = null;
                          });
                        },
                      )
                    else
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedType = 'all';
                        _selectedRange = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(
                      'Reset All',
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
                      final provider = context.read<UserProvider>();
                      provider.setFilterType(_selectedType);
                      provider.setDateRange(_selectedRange);
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Apply Filters',
                      style: AppTypography.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
