import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/onboarding_provider.dart';
import '../widgets/onboarding_page_wrapper.dart';

class GroceryFeaturePage extends ConsumerWidget {
  const GroceryFeaturePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingProvider.notifier);

    return OnboardingPageWrapper(
      title: "Don't have an ingredient?",
      subtitle:
          'We have an easy-to-manage grocery list for your recipes',
      showBackButton: true,
      onBack: () => notifier.previousPage(),
      bottomAction: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () => notifier.nextPage(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF4F63),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Continue',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Grocery list mockup
          _GroceryMockup(),
          const SizedBox(height: 32),
          // Instacart integration callout
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF43B02A).withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF43B02A).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF43B02A).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_rounded,
                    color: Color(0xFF43B02A),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'One-click Instacart checkout',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Send your grocery list straight to Instacart for delivery.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Add missing ingredients from any recipe with a single tap, '
            'then check out via Instacart.',
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.6),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _GroceryMockup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      ('Chicken Breast', '2 lbs', true),
      ('Olive Oil', '1 tbsp', true),
      ('Bell Peppers', '3', false),
      ('Garlic', '4 cloves', false),
      ('Soy Sauce', '2 tbsp', true),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.checklist_rounded,
                  size: 20,
                  color: Color(0xFFFF4F63),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Grocery List',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${items.length} items',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...items.map((item) => _GroceryItem(
                name: item.$1,
                quantity: item.$2,
                checked: item.$3,
              )),
        ],
      ),
    );
  }
}

class _GroceryItem extends StatelessWidget {
  const _GroceryItem({
    required this.name,
    required this.quantity,
    required this.checked,
  });

  final String name;
  final String quantity;
  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            checked
                ? Icons.check_circle_rounded
                : Icons.circle_outlined,
            size: 22,
            color: checked ? const Color(0xFFFF4F63) : Colors.grey.shade400,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                decoration: checked ? TextDecoration.lineThrough : null,
                color: checked ? Colors.grey.shade400 : null,
              ),
            ),
          ),
          Text(
            quantity,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
