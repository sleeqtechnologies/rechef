import 'package:flutter/material.dart';

import '../../../core/widgets/custom_app_bar.dart';

// TODO: Implement pantry screen
class PantryScreen extends StatelessWidget {
  const PantryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Pantry'),
      body: const Center(child: Text('Pantry Screen - Coming Soon')),
    );
  }
}
