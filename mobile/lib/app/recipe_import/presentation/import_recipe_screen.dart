import 'package:flutter/material.dart';

// TODO: Implement import recipe screen
class ImportRecipeScreen extends StatelessWidget {
  const ImportRecipeScreen({super.key, this.initialUrl, this.initialImagePath});

  final String? initialUrl;
  final String? initialImagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Recipe')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Import Recipe Screen - Coming Soon'),
            if (initialUrl != null) Text('URL: $initialUrl'),
            if (initialImagePath != null) Text('Image: $initialImagePath'),
          ],
        ),
      ),
    );
  }
}
