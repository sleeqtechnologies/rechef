import 'package:flutter/material.dart';

// TODO: Implement checkout screen
class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key, this.cartId});

  final String? cartId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Checkout Screen - Coming Soon'),
            if (cartId != null) Text('Cart ID: $cartId'),
          ],
        ),
      ),
    );
  }
}
