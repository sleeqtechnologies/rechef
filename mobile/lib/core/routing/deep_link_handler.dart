import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'navigation_utils.dart';

/// Handles deep links from external sources (Instacart, share extensions, etc.)
class DeepLinkHandler {
  DeepLinkHandler._();

  /// Handle Instacart deep link
  /// Format: instacart://callback?cart_id=123
  static bool handleInstacartLink(BuildContext context, Uri uri) {
    if (uri.scheme == 'instacart' || uri.host == 'instacart') {
      final cartId = uri.queryParameters['cart_id'];
      NavigationUtils.goToInstacartCallback(context, cartId: cartId);
      return true;
    }
    return false;
  }

  /// Handle app deep link
  /// Format: rechef://recipes/import?url=https://...
  /// Also handles Universal Links: https://rechef.app/recipe/:code
  static bool handleAppDeepLink(BuildContext context, Uri uri) {
    // Handle Universal Links (recipe share URLs)
    if (uri.scheme == 'https' &&
        (uri.host == 'rechef.app' ||
            uri.host == 'www.rechef.app' ||
            uri.host == 'rechef-ten.vercel.app')) {
      final path = uri.path;
      if (path.startsWith('/recipe/')) {
        final code = path.substring('/recipe/'.length);
        if (code.isNotEmpty) {
          context.go('/shared-recipe/$code');
          return true;
        }
      }
      return false;
    }

    // Handle custom scheme deep links
    if (uri.scheme == 'rechef' || uri.scheme == 'com.rechef.app') {
      // Remove scheme and host, keep path and query
      final path = uri.path;
      final queryParams = uri.queryParameters;

      if (path.startsWith('/recipes/import')) {
        NavigationUtils.goToRecipeImport(
          context,
          url: queryParams['url'],
          imagePath: queryParams['image'],
        );
        return true;
      }

      // For other paths, use go_router directly
      // Build full location with query parameters
      final location = queryParams.isNotEmpty
          ? '${uri.path}?${uri.query}'
          : uri.path;
      context.go(location);
      return true;
    }
    return false;
  }

  /// Handle share extension data
  /// Called when app is opened from share extension
  static void handleShareExtension(
    BuildContext context, {
    String? url,
    String? imagePath,
    String? text,
  }) {
    if (url != null || imagePath != null) {
      NavigationUtils.goToRecipeImport(context, url: url, imagePath: imagePath);
    } else if (text != null) {
      // Try to extract URL from text
      final uri = Uri.tryParse(text);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        NavigationUtils.goToRecipeImport(context, url: text);
      }
    }
  }
}
