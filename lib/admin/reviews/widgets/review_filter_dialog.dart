import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../config/clay_widgets.dart';
import '../../../providers/review_provider.dart';

class ReviewFilterDialog extends StatefulWidget {
  const ReviewFilterDialog({super.key});

  @override
  State<ReviewFilterDialog> createState() => _ReviewFilterDialogState();
}

class _ReviewFilterDialogState extends State<ReviewFilterDialog> {
  late String _statusFilter;
  int? _ratingFilter;
  late String _dateFilter;
  DateTimeRange? _customRange;

  final Map<String, String> _statusOptions = {
    'all': 'All Reviews',
    'approved': 'Approved Only',
    'pending': 'Pending Only',
    'hidden': 'Hidden Only',
    'rejected': 'Rejected Only',
    'reported': 'Reported Only',
  };

  final Map<String, String> _dateOptions = {
    'all': 'All Time',
    'today': 'Today',
    'week': 'This Week',
    'month': 'This Month',
    'custom': 'Custom Range',
  };

  @override
  void initState() {
    super.initState();
    final provider = context.read<ReviewProvider>();
    _statusFilter = provider.statusFilter;
    _ratingFilter = provider.ratingFilter;
    _dateFilter = provider.dateFilter;
    _customRange = provider.customDateRange;
  }

  Future<void> _selectCustomRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _customRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
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
        _customRange = picked;
        _dateFilter = 'custom';
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
            
            // 1. Status Section
            Text(
              'Moderation Status',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _statusOptions.entries.map((entry) {
                final isSelected = _statusFilter == entry.key;
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
                        _statusFilter = entry.key;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 2. Rating Star Section
            Text(
              'Rating Score',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All Stars'),
                  selected: _ratingFilter == null,
                  selectedColor: AppColors.primary.withOpacity(0.12),
                  backgroundColor: AppColors.surface,
                  labelStyle: AppTypography.bodyMedium.copyWith(
                    fontWeight: _ratingFilter == null ? FontWeight.bold : FontWeight.normal,
                    color: _ratingFilter == null ? AppColors.primary : AppColors.textSecondary,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _ratingFilter = null;
                      });
                    }
                  },
                ),
                ...List.generate(5, (index) {
                  final score = index + 1;
                  final isSelected = _ratingFilter == score;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$score'),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: isSelected ? AppColors.primary : Colors.amber,
                        ),
                      ],
                    ),
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
                          _ratingFilter = score;
                        });
                      }
                    },
                  );
                }),
              ],
            ),
            const SizedBox(height: 24),

            // 3. Date Selection Section
            Text(
              'Time Period',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _dateOptions.entries.map((entry) {
                final isSelected = _dateFilter == entry.key;
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withOpacity(0.12),
                  backgroundColor: AppColors.surface,
                  labelStyle: AppTypography.bodyMedium.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      if (entry.key == 'custom') {
                        _selectCustomRange();
                      } else {
                        setState(() {
                          _dateFilter = entry.key;
                          _customRange = null;
                        });
                      }
                    }
                  },
                );
              }).toList(),
            ),
            if (_dateFilter == 'custom' && _customRange != null) ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectCustomRange,
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
                          '${DateFormat('MMM dd, yyyy').format(_customRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_customRange!.end)}',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.edit_rounded, color: AppColors.textSecondary, size: 16),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _statusFilter = 'all';
                        _ratingFilter = null;
                        _dateFilter = 'all';
                        _customRange = null;
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
                      final provider = context.read<ReviewProvider>();
                      provider.setStatusFilter(_statusFilter);
                      provider.setRatingFilter(_ratingFilter);
                      provider.setDateFilter(_dateFilter);
                      provider.setCustomDateRange(_customRange);
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
