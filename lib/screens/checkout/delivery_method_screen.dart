import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watch_hub/config/app_colors.dart';
import 'package:watch_hub/config/app_routes.dart';
import 'package:watch_hub/providers/checkout_provider.dart';
import 'widgets/delivery_method_card.dart';
import 'widgets/place_order_button.dart';

class DeliveryMethodScreen extends StatelessWidget {
  const DeliveryMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final checkoutProvider = context.watch<CheckoutProvider>();
    final selectedMethod = checkoutProvider.selectedDeliveryMethod;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Delivery Method'),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: CheckoutProvider.availableDeliveryMethods.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final method = CheckoutProvider.availableDeliveryMethods[index];
                  final isSelected = selectedMethod?.id == method.id;

                  return DeliveryMethodCard(
                    method: method,
                    isSelected: isSelected,
                    onTap: () => checkoutProvider.selectDeliveryMethod(method),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: PlaceOrderButton(
                text: 'Proceed to Order Review',
                onPressed: selectedMethod == null
                    ? null
                    : () {
                        Navigator.of(context).pushNamed(AppRoutes.customerOrderReview);
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
