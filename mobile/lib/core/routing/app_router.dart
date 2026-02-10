import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/auth/presentation/sign_in_screen.dart';
import '../../app/auth/providers/auth_providers.dart';
import '../../app/main_layout.dart';
import '../../app/pantry/presentation/pantry_screen.dart';
import '../../app/recipes/presentation/recipe_detail_screen.dart';
import '../../app/recipes/presentation/recipe_list_screen.dart';
import '../../app/recipes/presentation/shared_recipe_screen.dart';
import '../../app/recipes/presentation/share_stats_screen.dart';
import '../../app/recipe_import/presentation/import_recipe_screen.dart';
import '../../app/recipe_import/presentation/camera_screen.dart';
import '../../app/grocery/presentation/grocery_list_screen.dart';
import '../../app/instacart/presentation/checkout_screen.dart';
import '../../app/meal_planning/presentation/meal_plan_screen.dart';
import '../../app/subscription/presentation/paywall_screen.dart';
import '../../app/subscription/presentation/subscription_settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState.value != null;
      final isAuthRoute = state.matchedLocation == '/';

      if (!isAuthenticated && !isAuthRoute) {
        return '/';
      }

      if (isAuthenticated && isAuthRoute) {
        return '/recipes';
      }

      return null;
    },
    routes: [
      // Auth
      GoRoute(
        path: '/',
        name: 'sign-in',
        builder: (context, state) => const SignInScreen(),
      ),

      // Main navigation with bottom bar (shell route)
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(location: state.uri.path, child: child);
        },
        routes: [
          // Recipes
          GoRoute(
            path: '/recipes',
            name: 'recipes',
            builder: (context, state) => const RecipeListScreen(),
          ),

          // Pantry
          GoRoute(
            path: '/pantry',
            name: 'pantry',
            builder: (context, state) => const PantryScreen(),
          ),

          // Grocery List
          GoRoute(
            path: '/grocery',
            name: 'grocery',
            builder: (context, state) {
              final recipeIds = state.uri.queryParameters['recipes']?.split(
                ',',
              );
              return GroceryListScreen(recipeIds: recipeIds);
            },
          ),
        ],
      ),

      // Recipe Import (for share extension and manual import) - no bottom bar
      // Must be before /recipes/:id so it isn't matched as a param
      GoRoute(
        path: '/recipes/import',
        name: 'recipe-import',
        builder: (context, state) {
          final url = state.uri.queryParameters['url'];
          final imagePath = state.uri.queryParameters['image'];
          return ImportRecipeScreen(
            initialUrl: url,
            initialImagePath: imagePath,
          );
        },
      ),

      // Shared Recipe (no bottom bar) - must be before /recipes/:id
      GoRoute(
        path: '/shared-recipe/:code',
        name: 'shared-recipe',
        builder: (context, state) {
          final code = state.pathParameters['code']!;
          return SharedRecipeScreen(shareCode: code);
        },
      ),

      // Recipe Detail (no bottom bar)
      GoRoute(
        path: '/recipes/:id',
        name: 'recipe-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RecipeDetailScreen(recipeId: id);
        },
        routes: [
          GoRoute(
            path: 'share-stats',
            name: 'share-stats',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ShareStatsScreen(recipeId: id);
            },
          ),
        ],
      ),

      // Camera Screen (for taking recipe photos) - no bottom bar
      GoRoute(
        path: '/camera',
        name: 'camera',
        builder: (context, state) => const CameraScreen(),
      ),

      // Meal Planning - no bottom bar
      GoRoute(
        path: '/meal-plan',
        name: 'meal-plan',
        builder: (context, state) => const MealPlanScreen(),
      ),

      // Instacart Callback (for deep linking) - no bottom bar
      GoRoute(
        path: '/instacart/callback',
        name: 'instacart-callback',
        builder: (context, state) {
          final cartId = state.uri.queryParameters['cart_id'];
          return CheckoutScreen(cartId: cartId);
        },
      ),

      // Subscription Paywall - no bottom bar
      GoRoute(
        path: '/paywall',
        name: 'paywall',
        builder: (context, state) => const PaywallScreen(),
      ),

      // Subscription Settings - no bottom bar
      GoRoute(
        path: '/subscription',
        name: 'subscription',
        builder: (context, state) => const SubscriptionSettingsScreen(),
      ),
    ],
  );
});
