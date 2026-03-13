import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Live API (Vercel). Override with API_BASE_URL in .env if needed.
const String _liveApiBaseUrl = 'https://rechef-eight.vercel.app';

/// Default test RevenueCat API key. Override with platform-specific keys in .env.
const String _defaultRevenueCatApiKey = 'test_HZPsnVkxuDTJGMjFiKBaxHhNTiu';

String get apiBaseUrl {
  // Any non-debug build should target the production backend.
  if (!kDebugMode) {
    return dotenv.env['API_BASE_URL'] ?? _liveApiBaseUrl;
  }
  final useDev = dotenv.env['USE_DEV_URL']?.toLowerCase() == 'true';
  if (useDev) {
    return dotenv.env['API_DEV_URL'] ??
        dotenv.env['API_BASE_URL'] ??
        'http://localhost:3000';
  }
  return dotenv.env['API_BASE_URL'] ?? _liveApiBaseUrl;
}

String get posthogApiKey => dotenv.env['POSTHOG_API_KEY'] ?? '';

String get revenueCatApiKey {
  // Prefer platform-specific keys so Android uses `goog_` and iOS uses `appl_`.
  final platformKey = switch (defaultTargetPlatform) {
    TargetPlatform.android => dotenv.env['REVENUE_CAT_API_KEY_ANDROID'],
    TargetPlatform.iOS => dotenv.env['REVENUE_CAT_API_KEY_IOS'],
    _ => null,
  };

  final key = platformKey ??
      dotenv.env['REVENUE_CAT_API_KEY'] ??
      _defaultRevenueCatApiKey;
  if (kDebugMode) {
    final isUsingEnv =
        platformKey != null || dotenv.env['REVENUE_CAT_API_KEY'] != null;
    debugPrint(
      '[RevenueCat] Using ${isUsingEnv ? "ENV" : "DEFAULT"} API key: ${key.substring(0, 10)}...',
    );
  }
  return key;
}
