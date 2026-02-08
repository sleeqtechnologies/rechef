import 'package:http/http.dart' as http;

class ApiInterceptor {
  ApiInterceptor._();

  static http.Response? onResponse(http.Response response) {
    if (response.statusCode >= 400) {}
    return response;
  }

  static http.StreamedResponse? onStreamedResponse(
    http.StreamedResponse response,
  ) {
    if (response.statusCode >= 400) {}
    return response;
  }
}
