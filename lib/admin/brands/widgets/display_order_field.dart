import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DisplayOrderField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const DisplayOrderField({
    super.key,
    required this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(
        labelText: 'Display Order',
        hintText: 'e.g. 0, 1, 2...',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.sort),
      ),
      validator: validator ??
          (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Display order is required';
            }
            final number = int.tryParse(value);
            if (number == null || number < 0) {
              return 'Display order must be a non-negative integer';
            }
            return null;
          },
    );
  }
}