class RecipeAuthor {
  const RecipeAuthor({required this.name, this.sourceUrl});

  final String name;
  final String? sourceUrl;
}

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

class DemoRecipe {
  const DemoRecipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.author,
    required this.minutes,
    required this.servings,
    required this.ingredients,
    required this.ingredientsInPantry,
    required this.steps,
  });

  final String id;
  final String title;
  final String imageUrl;
  final RecipeAuthor? author;
  final int minutes;
  final int servings;
  final List<RecipeIngredient> ingredients;
  final int ingredientsInPantry;
  final List<String> steps;
}

class DemoRecipes {
  DemoRecipes._();

  static final List<DemoRecipe> all = [
    const DemoRecipe(
      id: '1',
      title: 'Classic Margherita Pizza',
      imageUrl:
          'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=800',
      author: RecipeAuthor(name: 'Marco Rossi', sourceUrl: 'italianfoodlab.com'),
      minutes: 45,
      servings: 4,
      ingredientsInPantry: 3,
      ingredients: [
        RecipeIngredient(name: 'Pizza dough', quantity: '500g', inPantry: true),
        RecipeIngredient(name: 'San Marzano tomatoes', quantity: '400g'),
        RecipeIngredient(
            name: 'Fresh mozzarella', quantity: '250g', inPantry: true),
        RecipeIngredient(name: 'Fresh basil', quantity: '1 bunch'),
        RecipeIngredient(
            name: 'Extra virgin olive oil', quantity: '2 tbsp', inPantry: true),
        RecipeIngredient(name: 'Salt', quantity: 'to taste'),
      ],
      steps: [
        'Preheat your oven to the highest temperature (ideally 250°C / 480°F) with a pizza stone or inverted baking sheet inside.',
        'Stretch the dough into a thin round on a floured surface. Transfer to parchment paper.',
        'Crush the San Marzano tomatoes by hand and spread evenly over the dough, leaving a 1 cm border.',
        'Tear the mozzarella into pieces and distribute over the sauce.',
        'Slide onto the hot stone and bake for 8-10 minutes until the crust is golden and cheese is bubbling.',
        'Remove from oven, top with fresh basil leaves, drizzle with olive oil, and serve immediately.',
      ],
    ),
    const DemoRecipe(
      id: '2',
      title: 'Thai Green Curry',
      imageUrl:
          'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=800',
      author: RecipeAuthor(name: 'Suda Pimchan', sourceUrl: 'thaitable.com'),
      minutes: 35,
      servings: 3,
      ingredientsInPantry: 2,
      ingredients: [
        RecipeIngredient(name: 'Chicken breast', quantity: '400g'),
        RecipeIngredient(name: 'Green curry paste', quantity: '3 tbsp'),
        RecipeIngredient(
            name: 'Coconut milk', quantity: '400ml', inPantry: true),
        RecipeIngredient(name: 'Thai basil', quantity: '1 cup'),
        RecipeIngredient(name: 'Bamboo shoots', quantity: '200g'),
        RecipeIngredient(name: 'Fish sauce', quantity: '2 tbsp', inPantry: true),
        RecipeIngredient(name: 'Palm sugar', quantity: '1 tbsp'),
      ],
      steps: [
        'Heat a tablespoon of coconut cream in a wok over medium-high heat until it splits.',
        'Add the green curry paste and fry for 1-2 minutes until fragrant.',
        'Add the chicken, stir to coat in the paste, and cook for 3 minutes.',
        'Pour in the coconut milk and bring to a gentle simmer.',
        'Add bamboo shoots and cook for 10 minutes until the chicken is cooked through.',
        'Season with fish sauce and palm sugar. Stir in Thai basil leaves just before serving.',
      ],
    ),
    const DemoRecipe(
      id: '3',
      title: 'Avocado Toast with Poached Eggs',
      imageUrl:
          'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=800',
      author: RecipeAuthor(name: 'Emily Chen'),
      minutes: 15,
      servings: 2,
      ingredientsInPantry: 4,
      ingredients: [
        RecipeIngredient(
            name: 'Sourdough bread', quantity: '2 slices', inPantry: true),
        RecipeIngredient(name: 'Ripe avocado', quantity: '1 large'),
        RecipeIngredient(name: 'Eggs', quantity: '2', inPantry: true),
        RecipeIngredient(name: 'Lemon juice', quantity: '1 tsp', inPantry: true),
        RecipeIngredient(name: 'Red pepper flakes', quantity: 'pinch'),
        RecipeIngredient(
            name: 'Salt & pepper', quantity: 'to taste', inPantry: true),
      ],
      steps: [
        'Bring a pot of water to a gentle simmer and add a splash of vinegar.',
        'Toast the sourdough slices until golden and crispy.',
        'Mash the avocado with lemon juice, salt, and pepper.',
        'Crack each egg into a small cup, then gently slide into the simmering water. Poach for 3-4 minutes.',
        'Spread the mashed avocado on the toast, top with a poached egg, and finish with red pepper flakes.',
      ],
    ),
    const DemoRecipe(
      id: '4',
      title: 'Japanese Miso Ramen',
      imageUrl:
          'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=800',
      author: RecipeAuthor(name: 'Yuki Tanaka', sourceUrl: 'ramenlover.jp'),
      minutes: 60,
      servings: 2,
      ingredientsInPantry: 1,
      ingredients: [
        RecipeIngredient(name: 'Ramen noodles', quantity: '200g'),
        RecipeIngredient(name: 'White miso paste', quantity: '3 tbsp'),
        RecipeIngredient(name: 'Chicken stock', quantity: '1L', inPantry: true),
        RecipeIngredient(name: 'Chashu pork', quantity: '150g'),
        RecipeIngredient(name: 'Soft-boiled eggs', quantity: '2'),
        RecipeIngredient(name: 'Corn kernels', quantity: '60g'),
        RecipeIngredient(name: 'Green onions', quantity: '2 stalks'),
        RecipeIngredient(name: 'Nori sheets', quantity: '2'),
      ],
      steps: [
        'Heat the chicken stock in a pot. Dissolve the miso paste into the warm stock, stirring well.',
        'Cook the ramen noodles according to package instructions. Drain and set aside.',
        'Slice the chashu pork and halve the soft-boiled eggs.',
        'Divide noodles between two bowls, then ladle the hot miso broth over them.',
        'Arrange chashu, egg halves, corn, sliced green onions, and nori on top.',
        'Serve immediately while piping hot.',
      ],
    ),
    const DemoRecipe(
      id: '5',
      title: 'Berry Açaí Smoothie Bowl',
      imageUrl:
          'https://images.unsplash.com/photo-1590301157890-4810ed352733?w=800',
      minutes: 10,
      servings: 1,
      ingredientsInPantry: 2,
      ingredients: [
        RecipeIngredient(name: 'Frozen açaí packets', quantity: '2'),
        RecipeIngredient(
            name: 'Frozen mixed berries', quantity: '1 cup', inPantry: true),
        RecipeIngredient(name: 'Banana', quantity: '1'),
        RecipeIngredient(
            name: 'Almond milk', quantity: '½ cup', inPantry: true),
        RecipeIngredient(name: 'Granola', quantity: '¼ cup'),
        RecipeIngredient(name: 'Fresh strawberries', quantity: '3-4'),
        RecipeIngredient(name: 'Chia seeds', quantity: '1 tsp'),
      ],
      steps: [
        'Blend the açaí packets, frozen berries, banana, and almond milk until thick and smooth.',
        'Pour the mixture into a bowl.',
        'Top with granola, sliced strawberries, and chia seeds.',
        'Serve immediately and enjoy cold.',
      ],
    ),
    const DemoRecipe(
      id: '6',
      title: 'Lemon Herb Grilled Salmon',
      imageUrl:
          'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800',
      author: RecipeAuthor(name: 'Sarah Williams', sourceUrl: 'freshcatch.co'),
      minutes: 25,
      servings: 2,
      ingredientsInPantry: 3,
      ingredients: [
        RecipeIngredient(name: 'Salmon fillets', quantity: '2 pieces'),
        RecipeIngredient(name: 'Lemon', quantity: '1', inPantry: true),
        RecipeIngredient(name: 'Fresh dill', quantity: '2 tbsp'),
        RecipeIngredient(
            name: 'Garlic cloves', quantity: '2', inPantry: true),
        RecipeIngredient(
            name: 'Olive oil', quantity: '2 tbsp', inPantry: true),
        RecipeIngredient(name: 'Salt & pepper', quantity: 'to taste'),
      ],
      steps: [
        'Mix olive oil, minced garlic, lemon zest, lemon juice, and chopped dill in a bowl.',
        'Marinate the salmon fillets in the mixture for 15 minutes.',
        'Preheat grill or grill pan to medium-high heat.',
        'Grill the salmon skin-side down for 4-5 minutes, then flip and cook for another 3-4 minutes.',
        'Serve with lemon wedges and a side of your choice.',
      ],
    ),
  ];

  static DemoRecipe byId(String id) {
    return all.firstWhere(
      (recipe) => recipe.id == id,
      orElse: () => all.first,
    );
  }
}
