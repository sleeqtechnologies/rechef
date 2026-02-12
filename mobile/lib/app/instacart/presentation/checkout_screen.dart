import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

// TODO: Implement checkout screen
class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key, this.cartId});

  final String? cartId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('checkout.title'.tr())),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('checkout.coming_soon'.tr()),
            if (cartId != null) Text('Cart ID: $cartId'),
          ],
        ),
      ),
    );
  }
}
