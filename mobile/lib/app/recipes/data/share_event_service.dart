import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/env.dart';
import '../../../core/constants/api_endpoints.dart';

class ShareEventService {
  ShareEventService._();

  /// Record a share event (public endpoint, no auth required)
  static Future<void> recordEvent({
    required String shareCode,
    required String eventType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final url = Uri.parse(
        '$apiBaseUrl${ApiEndpoints.getSharedRecipePublic(shareCode)}/events',
      );
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'eventType': eventType,
          if (metadata != null) 'metadata': metadata,
        }),
      );
    } catch (_) {
      // Silently fail - event tracking is best-effort
    }
  }
}
