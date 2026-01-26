import 'package:http/http.dart' as http;

/// Interceptor for API requests/responses
/// Can be used for logging, error handling, retry logic, etc.
class ApiInterceptor {
  ApiInterceptor._();

  static http.Response? onResponse(http.Response response) {
    // Log response if needed
    // Handle common errors
    if (response.statusCode >= 400) {
      // Could throw custom exceptions here
    }
    return response;
  }

  static http.StreamedResponse? onStreamedResponse(
    http.StreamedResponse response,
  ) {
    if (response.statusCode >= 400) {
      // Handle errors
    }
    return response;
  }
}
