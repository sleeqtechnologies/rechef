import 'package:flutter/material.dart';

import '../../../core/widgets/custom_app_bar.dart';

class RecipeListScreen extends StatelessWidget {
  const RecipeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Recipes'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [const Text('Recipe List Screen - Coming Soon')],
        ),
      ),
    );
  }
}
