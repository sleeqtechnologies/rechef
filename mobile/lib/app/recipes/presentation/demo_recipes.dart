import 'package:flutter/foundation.dart';

@immutable
class RecipeIngredient {
  const RecipeIngredient({
    required this.name,
    required this.quantity,
    this.inPantry = false,
  });

  final String name;
  final String quantity;
  final bool inPantry;
}

@immutable
class RecipeAuthor {
  const RecipeAuthor({
    required this.name,
    this.avatarUrl,
    this.sourceUrl,
  });

  final String name;
  final String? avatarUrl;
  final String? sourceUrl;
}

@immutable
class DemoRecipe {
  const DemoRecipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.minutes,
    required this.servings,
    required this.tags,
    required this.ingredients,
    required this.steps,
    this.author,
  });

  final String id;
  final String title;
  final String imageUrl;
  final int minutes;
  final int servings;
  final List<String> tags;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final RecipeAuthor? author;

  int get ingredientsInPantry =>
      ingredients.where((i) => i.inPantry).length;
}

class DemoRecipes {
  DemoRecipes._();

  static const List<DemoRecipe> all = [
    DemoRecipe(
      id: 'spicy-chicken-fajita-pasta',
      title: 'Spicy Chicken Fajita Pasta Recipe',
      imageUrl: 'https://picsum.photos/seed/rechef-1/900/900',
      minutes: 40,
      servings: 4,
      tags: ['Spicy', 'Quick', 'Weeknight'],
      author: RecipeAuthor(
        name: 'Eltan Bernath',
        sourceUrl: 'instagram.com/reel/dn0xy..',
      ),
      ingredients: [
        RecipeIngredient(name: 'Diced skinless chicken breast', quantity: '600 g'),
        RecipeIngredient(name: 'Onion powder', quantity: '1 tbsp', inPantry: true),
        RecipeIngredient(name: 'Garlic powder', quantity: '1 tbsp'),
        RecipeIngredient(name: 'Thyme', quantity: '1 tbsp', inPantry: true),
        RecipeIngredient(name: 'Smoked paprika', quantity: '2 tbsp'),
        RecipeIngredient(name: 'Salt', quantity: '1 tbsp', inPantry: true),
        RecipeIngredient(name: 'Chilli powder', quantity: '1.5 tbsp', inPantry: true),
        RecipeIngredient(name: 'Olive oil', quantity: '1 tbsp', inPantry: true),
        RecipeIngredient(name: 'Diced white onion', quantity: '1/2', inPantry: true),
        RecipeIngredient(name: 'Garlic cloves', quantity: '4'),
        RecipeIngredient(name: 'Tomato purée / tomato paste', quantity: '35g'),
        RecipeIngredient(name: 'Chicken stock', quantity: '250 - 300ml', inPantry: true),
        RecipeIngredient(name: 'Light cream cheese (or 6 light laughing cow cheese wedges)', quantity: '600 g', inPantry: true),
      ],
      steps: [
        'Combine the ingredients for the marinade along with 1½ teaspoons salt and ½ teaspoon black pepper. Use a whisk to combine before adding the jalapeño slices and the chicken breast. Let marinate covered in the refrigerator for 4-6 hours.',
        'Remove from the refrigerator and allow the chicken to sit at room temperature for 30 minutes before cooking.',
        'Set a large cast iron skillet or nonstick skillet over high heat and let heat up for a couple of minutes. Drizzle in a teaspoon of oil and add half the chicken to the pan and cook on each side for about 3-5 minutes or longer depending on the thickness of the chicken. If the pan becomes too hot, reduce the heat to medium-high.',
        'Remove the chicken from the pan and allow to rest for several minutes. Cook the remaining chicken the same way. Slice the chicken into thin slices.',
        'Add another teaspoon of oil to the pan over high heat, add half the onions and bell peppers. Let the veggies begin to sizzle and toss as necessary. You can drizzle in some of that chicken marinade if you want to flavor the veggies but be sure to cook them well. Season with a pinch of salt and pepper. Remove the veggies to a plate and cook the remaining veggies the same way.',
        'Serve the chicken fajitas in tortillas or on rice bowls topped with your favorite toppings!',
      ],
    ),
    DemoRecipe(
      id: 'creamy-butter-chicken-pasta',
      title: 'Creamy Butter Chicken Pasta Recipe',
      imageUrl: 'https://picsum.photos/seed/rechef-2/900/900',
      minutes: 35,
      servings: 4,
      tags: ['Creamy', 'Comfort'],
      author: RecipeAuthor(
        name: 'Gordon Ramsay',
        sourceUrl: 'youtube.com/watch?v=abc123',
      ),
      ingredients: [
        RecipeIngredient(name: 'Pasta', quantity: '12 oz'),
        RecipeIngredient(name: 'Chicken thighs, chopped', quantity: '1 lb'),
        RecipeIngredient(name: 'Butter', quantity: '2 tbsp', inPantry: true),
        RecipeIngredient(name: 'Onion, finely chopped', quantity: '1 small'),
        RecipeIngredient(name: 'Garlic, minced', quantity: '2 cloves'),
        RecipeIngredient(name: 'Tomato paste', quantity: '2 tbsp', inPantry: true),
        RecipeIngredient(name: 'Garam masala', quantity: '1 tbsp', inPantry: true),
        RecipeIngredient(name: 'Paprika', quantity: '1 tsp', inPantry: true),
        RecipeIngredient(name: 'Tomato sauce', quantity: '1 cup'),
        RecipeIngredient(name: 'Cream', quantity: '3/4 cup'),
        RecipeIngredient(name: 'Salt', quantity: 'to taste', inPantry: true),
        RecipeIngredient(name: 'Cilantro', quantity: 'for garnish'),
      ],
      steps: [
        'Cook pasta until al dente and drain.',
        'Sear chicken in a pan until cooked through; set aside.',
        'Melt butter, sauté onion until soft, then add garlic.',
        'Stir in tomato paste and spices for 1 minute.',
        'Add tomato sauce and simmer 5 minutes; stir in cream.',
        'Return chicken to sauce and toss with pasta.',
        'Top with cilantro and serve.',
      ],
    ),
    DemoRecipe(
      id: 'lemon-garlic-salmon',
      title: 'Lemon Garlic Salmon with Rice',
      imageUrl: 'https://picsum.photos/seed/rechef-3/900/900',
      minutes: 25,
      servings: 2,
      tags: ['Healthy', 'Seafood'],
      author: RecipeAuthor(
        name: 'Jamie Oliver',
        sourceUrl: 'jamieoliver.com/recipes',
      ),
      ingredients: [
        RecipeIngredient(name: 'Salmon fillets', quantity: '2'),
        RecipeIngredient(name: 'Olive oil', quantity: '1 tbsp', inPantry: true),
        RecipeIngredient(name: 'Garlic, minced', quantity: '2 cloves'),
        RecipeIngredient(name: 'Lemon (zest + juice)', quantity: '1'),
        RecipeIngredient(name: 'Salt & pepper', quantity: 'to taste', inPantry: true),
        RecipeIngredient(name: 'Cooked rice', quantity: 'for serving'),
        RecipeIngredient(name: 'Chopped parsley', quantity: 'for garnish'),
      ],
      steps: [
        'Season salmon with salt and pepper.',
        'Sear salmon skin-side down 3–4 minutes; flip and cook 2–3 minutes.',
        'Add oil, garlic, lemon zest, and lemon juice; spoon sauce over salmon.',
        'Serve over rice and garnish with parsley.',
      ],
    ),
    DemoRecipe(
      id: 'veggie-taco-bowls',
      title: 'Veggie Taco Bowls',
      imageUrl: 'https://picsum.photos/seed/rechef-4/900/900',
      minutes: 20,
      servings: 3,
      tags: ['Vegetarian', 'Meal Prep'],
      author: RecipeAuthor(
        name: 'Minimalist Baker',
        sourceUrl: 'minimalistbaker.com',
      ),
      ingredients: [
        RecipeIngredient(name: 'Black beans, rinsed', quantity: '1 can'),
        RecipeIngredient(name: 'Corn', quantity: '1 cup'),
        RecipeIngredient(name: 'Bell pepper, diced', quantity: '1'),
        RecipeIngredient(name: 'Cumin', quantity: '1 tsp', inPantry: true),
        RecipeIngredient(name: 'Chili powder', quantity: '1 tsp', inPantry: true),
        RecipeIngredient(name: 'Salt', quantity: 'to taste', inPantry: true),
        RecipeIngredient(name: 'Cooked rice or quinoa', quantity: 'for serving'),
        RecipeIngredient(name: 'Salsa, avocado, and lime', quantity: 'for topping'),
      ],
      steps: [
        'Warm beans and corn with spices in a pan.',
        'Assemble bowls with rice/quinoa, beans, corn, and bell pepper.',
        'Top with salsa, avocado, and a squeeze of lime.',
      ],
    ),
  ];

  static DemoRecipe byId(String id) {
    return all.firstWhere((r) => r.id == id, orElse: () => all.first);
  }
}
