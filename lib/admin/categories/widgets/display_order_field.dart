import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A Material 3 numeric field for editing a category's `displayOrder`.
///
/// Enforces "must be >= 0" both at the input level (digits-only keyboard
/// and input formatter) and via [validator], so invalid values are
/// rejected before the surrounding form is ever submitted.
class DisplayOrderField extends StatelessWidget {
  const DisplayOrderField({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(
        labelText: 'Display Order',
        helperText: 'Lower numbers appear first (0 = highest priority).',
        prefixIcon: Icon(Icons.sort),
        border: OutlineInputBorder(),
      ),
      validator: _validate,
    );
  }

  /// Validates the raw text value: required, integer, and non-negative.
  static String? _validate(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Display order is required.';
    }
    final parsed = int.tryParse(text);
    if (parsed == null) {
      return 'Display order must be a whole number.';
    }
    if (parsed < 0) {
      return 'Display order cannot be negative.';
    }
    return null;
  }
}