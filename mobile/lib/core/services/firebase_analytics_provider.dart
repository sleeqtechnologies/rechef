import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>((ref) {
  return FirebaseAnalytics.instance;
});

final appAnalyticsProvider = Provider<AppAnalytics>((ref) {
  final analytics = ref.watch(firebaseAnalyticsProvider);
  return AppAnalytics(analytics);
});

final firebaseAnalyticsObserverProvider = Provider<FirebaseAnalyticsObserver>((
  ref,
) {
  final analytics = ref.watch(firebaseAnalyticsProvider);
  return FirebaseAnalyticsObserver(analytics: analytics);
});

class AppAnalytics {
  AppAnalytics(this._analytics);

  final FirebaseAnalytics _analytics;

  Future<void> logAuthAttempt({
    required String method,
    required String location,
  }) {
    return _logEvent('auth_attempt', {'method': method, 'location': location});
  }

  Future<void> logAuthSuccess({
    required String method,
    required String location,
    required bool isAnonymous,
  }) {
    return _logEvent('auth_success', {
      'method': method,
      'location': location,
      'is_anonymous': isAnonymous ? 1 : 0,
    });
  }

  Future<void> logAuthFailure({
    required String method,
    required String location,
    required Object error,
  }) {
    return _logEvent('auth_failure', {
      'method': method,
      'location': location,
      'error_type': error.runtimeType.toString(),
    });
  }

  Future<void> logShareContentReceived({
    required String contentType,
    required bool routedToImport,
  }) {
    return _logEvent('share_content_received', {
      'content_type': contentType,
      'routed_to_import': routedToImport ? 1 : 0,
    });
  }

  Future<void> logImportSubmitted({
    required String inputType,
    required String source,
  }) {
    return _logEvent('recipe_import_submitted', {
      'input_type': inputType,
      'source': source,
    });
  }

  Future<void> logImportSucceeded({
    required String inputType,
    required String source,
  }) {
    return _logEvent('recipe_import_succeeded', {
      'input_type': inputType,
      'source': source,
    });
  }

  Future<void> logImportFailed({
    required String inputType,
    required String source,
    required Object error,
  }) {
    return _logEvent('recipe_import_failed', {
      'input_type': inputType,
      'source': source,
      'error_type': error.runtimeType.toString(),
    });
  }

  Future<void> logImportLimitReached({
    required String inputType,
    required String source,
  }) {
    return _logEvent('recipe_import_limit_hit', {
      'input_type': inputType,
      'source': source,
    });
  }

  Future<void> logPaywallViewed({required String source}) {
    return _logEvent('paywall_viewed', {'source': source});
  }

  Future<void> logPaywallOfferingLoaded({
    required String source,
    required bool success,
  }) {
    return _logEvent('paywall_offering_loaded', {
      'source': source,
      'success': success ? 1 : 0,
    });
  }

  Future<void> logPaywallResult({
    required String source,
    required String result,
  }) {
    return _logEvent('paywall_result', {'source': source, 'result': result});
  }

  Future<void> logSubscriptionPurchaseCompleted({
    required String source,
    String? productId,
    int? entitlementCount,
  }) {
    return _logEvent('subscription_purchase_done', {
      'source': source,
      if (productId != null && productId.isNotEmpty) 'product_id': productId,
      if (entitlementCount != null) 'entitlement_count': entitlementCount,
    });
  }

  Future<void> logSubscriptionRestoreCompleted({
    required String source,
    required bool active,
    int? entitlementCount,
  }) {
    return _logEvent('subscription_restore_done', {
      'source': source,
      'active': active ? 1 : 0,
      if (entitlementCount != null) 'entitlement_count': entitlementCount,
    });
  }

  Future<void> logCustomerCenterOpened({required String source}) {
    return _logEvent('customer_center_opened', {'source': source});
  }

  Future<void> logRecipeViewed({
    required String recipeId,
    required String recipeName,
    bool isShared = false,
  }) {
    return _logEvent('recipe_viewed', {
      'recipe_id': recipeId,
      'recipe_name': recipeName,
      'is_shared': isShared ? 1 : 0,
    });
  }

  Future<void> logCookingModeStarted({
    required String recipeId,
    required String recipeName,
  }) {
    return _logEvent('cooking_mode_started', {
      'recipe_id': recipeId,
      'recipe_name': recipeName,
    });
  }

  Future<void> logIngredientsAddedToGrocery({
    required String recipeId,
    required int itemCount,
  }) {
    return _logEvent('ingredients_added_to_grocery', {
      'recipe_id': recipeId,
      'item_count': itemCount,
    });
  }

  Future<void> logRecipeShared({required String recipeId}) {
    return _logEvent('recipe_shared', {'recipe_id': recipeId});
  }

  Future<void> logRecipeDeleted({required String recipeId}) {
    return _logEvent('recipe_deleted', {'recipe_id': recipeId});
  }

  Future<void> logRecipeEdited({required String recipeId}) {
    return _logEvent('recipe_edited', {'recipe_id': recipeId});
  }

  Future<void> logRecipeAddedToCookbook({required String recipeId}) {
    return _logEvent('recipe_added_to_cookbook', {'recipe_id': recipeId});
  }

  Future<void> logGroceryOrderOnlineTapped() {
    return _logEvent('grocery_order_online_tapped');
  }

  Future<void> logPantryItemsAdded({required int count}) {
    return _logEvent('pantry_items_added', {'item_count': count});
  }

  Future<void> logCameraOpened() {
    return _logEvent('camera_opened');
  }

  Future<void> logImportSheetOpened() {
    return _logEvent('import_sheet_opened');
  }

  Future<void> logOnboardingStepViewed({
    required int step,
    required String pageName,
  }) {
    return _logEvent('onboarding_step_viewed', {
      'step': step,
      'page_name': pageName,
    });
  }

  Future<void> _logEvent(String name, [Map<String, Object>? parameters]) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (error) {
      debugPrint('[Analytics] Firebase failed to log $name: $error');
    }
    try {
      await Posthog().capture(
        eventName: name,
        properties: parameters?.map((k, v) => MapEntry(k, v)),
      );
    } catch (error) {
      debugPrint('[Analytics] PostHog failed to log $name: $error');
    }
  }
}
