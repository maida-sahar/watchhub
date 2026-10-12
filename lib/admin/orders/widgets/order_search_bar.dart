import 'package:flutter/material.dart';

/// Search field for the Admin Orders list — searches by Order ID only,
/// against already-loaded orders (no extra Firestore query per
/// keystroke, matching how search works elsewhere in this app).
class OrderSearchBar extends StatelessWidget {
  const OrderSearchBar({
    super.key,
    required this.controller,
    required this.onClear,
  });

  final TextEditingController controller;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Search by Order ID',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: onClear,
              )
            : null,
        filled: true,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}