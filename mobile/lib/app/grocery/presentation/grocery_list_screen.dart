import 'package:flutter/material.dart';

import '../../../core/widgets/custom_app_bar.dart';

// TODO: Implement grocery list screen
class GroceryListScreen extends StatelessWidget {
  const GroceryListScreen({super.key, this.recipeIds});

  final List<String>? recipeIds;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Grocery'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Grocery List Screen - Coming Soon'),
            if (recipeIds != null && recipeIds!.isNotEmpty)
              Text('Recipes: ${recipeIds!.join(', ')}'),
          ],
        ),
      ),
    );
  }
}
