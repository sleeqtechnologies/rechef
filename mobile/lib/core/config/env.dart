import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Live API (Vercel). Override with API_BASE_URL in .env if needed.
const String _liveApiBaseUrl = 'https://rechef-eight.vercel.app';

String get apiBaseUrl {
  if (kReleaseMode) {
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
