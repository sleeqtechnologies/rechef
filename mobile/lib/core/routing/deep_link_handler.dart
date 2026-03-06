import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'navigation_utils.dart';

class DeepLinkHandler {
  DeepLinkHandler._();

  static const _validWebHosts = {
    'rechef.app',
    'www.rechef.app',
    'rechef-ten.vercel.app',
  };
  static final _shareCodeRegex = RegExp(r'^[a-zA-Z0-9_-]+$');

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
    if (uri.scheme == 'https' && _validWebHosts.contains(uri.host)) {
      final path = uri.path;
      if (path.startsWith('/recipe/')) {
        final code = path.substring('/recipe/'.length).trim();
        if (code.isNotEmpty && _shareCodeRegex.hasMatch(code)) {
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
        final url = queryParams['url'];
        if (url != null) {
          final parsed = Uri.tryParse(url);
          if (parsed == null ||
              !(parsed.scheme == 'http' || parsed.scheme == 'https')) {
            return false;
          }
        }

        NavigationUtils.goToRecipeImport(
          context,
          url: url,
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
