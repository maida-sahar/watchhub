import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/clay_widgets.dart';

class CancellationReasonSheet extends StatefulWidget {
  const CancellationReasonSheet({super.key});

  @override
  State<CancellationReasonSheet> createState() => _CancellationReasonSheetState();
}

class _CancellationReasonSheetState extends State<CancellationReasonSheet> {
  final List<String> _reasons = [
    'Changed My Mind',
    'Ordered By Mistake',
    'Found Better Price',
    'Delivery Too Slow',
    'Other',
  ];

  String _selectedReason = 'Changed My Mind';
  final TextEditingController _customReasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOther = _selectedReason == 'Other';

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Select Cancellation Reason',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Reasons list
            ..._reasons.map((reason) {
              final isSelected = _selectedReason == reason;
              return RadioListTile<String>(
                value: reason,
                groupValue: _selectedReason,
                activeColor: AppColors.primary,
                title: Text(
                  reason,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedReason = value;
                    });
                  }
                },
              );
            }),
            
            // Custom Input field if "Other" is selected
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isOther
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                      child: TextFormField(
                        controller: _customReasonController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Please write your reason here...',
                          hintStyle: const TextStyle(color: AppColors.textTertiary),
                          fillColor: AppColors.surfaceVariant,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a cancellation reason.';
                          }
                          if (value.trim().length < 5) {
                            return 'Reason is too short (min 5 characters).';
                          }
                          return null;
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Text(
                      'Cancel',
                      style: theme.textTheme.titleMedium?.copyWith(
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
                      if (_formKey.currentState?.validate() ?? true) {
                        final finalReason = isOther
                            ? _customReasonController.text.trim()
                            : _selectedReason;
                        Navigator.pop(context, finalReason);
                      }
                    },
                    child: Text(
                      'Confirm',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
