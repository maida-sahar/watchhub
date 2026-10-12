import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/order_provider.dart';
import '../../../services/order_service.dart' show OrderService;
import 'order_card.dart' show OrderStatusDisplay;

/// Lets an admin advance an order's status, or cancel it.
///
/// Only forward moves through [OrderService.statusSequence] are offered
/// (matching what `OrderService.updateOrderStatus` actually allows),
/// plus a separate "Cancel Order" option when the order isn't already
/// in a terminal state. Every change requires confirmation, and shows
/// loading/success/error feedback via `OrderProvider`.
class OrderStatusDropdown extends StatelessWidget {
  const OrderStatusDropdown({
    super.key,
    required this.orderId,
    required this.currentStatus,
  });

  final String orderId;
  final String currentStatus;

  static const String _cancelOption = '__cancel__';

  bool get _isTerminal {
    final normalized = currentStatus.trim().toLowerCase();
    return normalized == 'delivered' || normalized == 'cancelled';
  }

  List<String> get _availableNextStatuses {
    final normalized = currentStatus.trim().toLowerCase();
    final currentIndex = OrderService.statusSequence.indexOf(normalized);
    if (currentIndex == -1) return const [];
    // De-duplicate defensively: DropdownButtonFormField asserts that every
    // item value is unique, and will crash the whole screen if the same
    // status string appears twice (e.g. from a duplicate entry in
    // OrderService.statusSequence, or a casing mismatch that produced two
    // differently-cased copies of the same status). A LinkedHashSet-style
    // dedupe here keeps the original order while guaranteeing uniqueness.
    final seen = <String>{};
    return OrderService.statusSequence
        .sublist(currentIndex + 1)
        .where((status) => seen.add(status))
        .toList();
  }

  Future<void> _handleSelection(BuildContext context, String value) async {
    final provider = context.read<OrderProvider>();

    if (value == _cancelOption) {
      final reason = await _showCancelDialog(context);
      if (reason == null) return; // Admin dismissed the dialog.

      final success = await provider.cancelOrder(orderId, reason);
      if (!context.mounted) return;
      _showResultSnack(
        context,
        success: success,
        successMessage: 'Order cancelled.',
        errorMessage: provider.errorMessage ?? 'Failed to cancel order.',
      );
      return;
    }

    final confirmed = await _showConfirmDialog(context, value);
    if (confirmed != true) return;

    final success = await provider.updateOrderStatus(orderId, value);
    if (!context.mounted) return;
    _showResultSnack(
      context,
      success: success,
      successMessage: 'Order status updated to "${OrderStatusDisplay.label(value)}".',
      errorMessage: provider.statusUpdateError ?? 'Failed to update order status.',
    );
  }

  Future<bool?> _showConfirmDialog(BuildContext context, String newStatus) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update order status?'),
        content: Text(
          'Change status from "${OrderStatusDisplay.label(currentStatus)}" '
          'to "${OrderStatusDisplay.label(newStatus)}"?\n\n'
          'The customer will see this update immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showCancelDialog(BuildContext context) {
    final reasonController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will restore stock for all items and cannot be undone. '
              'Please provide a reason:',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              autofocus: true,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g. Customer requested cancellation',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Dismiss'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              Navigator.of(dialogContext).pop(reason);
            },
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
  }

  void _showResultSnack(
    BuildContext context, {
    required bool success,
    required String successMessage,
    required String errorMessage,
  }) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? successMessage : errorMessage),
        backgroundColor: success ? null : theme.colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<OrderProvider>();
    final nextStatuses = _availableNextStatuses;

    if (_isTerminal) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: OrderStatusDisplay.color(context, currentStatus).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'This order is ${OrderStatusDisplay.label(currentStatus)} — no further status changes are possible.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Update Status', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: null,
                hint: const Text('Select new status'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  ...nextStatuses.map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(OrderStatusDisplay.label(status)),
                    ),
                  ),
                  const DropdownMenuItem(
                    value: _cancelOption,
                    child: Text('Cancel Order', style: TextStyle(color: Colors.red)),
                  ),
                ],
                onChanged: provider.isUpdatingStatus
                    ? null
                    : (value) {
                        if (value != null) _handleSelection(context, value);
                      },
              ),
            ),
            if (provider.isUpdatingStatus) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ],
    );
  }
}