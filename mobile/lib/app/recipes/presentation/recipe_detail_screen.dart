import 'package:flutter/material.dart';

// TODO: Implement recipe detail screen
class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipe')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Recipe Detail Screen - Coming Soon'),
            Text('Recipe ID: $recipeId'),
          ],
        ),
      ),
    );
  }
}
