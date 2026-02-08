import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config/env.dart';

class ApiClient {
  ApiClient({http.Client? client, FirebaseAuth? auth})
      : _client = client ?? http.Client(),
        _auth = auth ?? FirebaseAuth.instance;

  final http.Client _client;
  final FirebaseAuth _auth;

  String get _baseUrl => apiBaseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    final user = _auth.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    return _client.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
    );
  }

  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    final headers = await _getHeaders();
    return _client.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> put(String endpoint, {Map<String, dynamic>? body}) async {
    final headers = await _getHeaders();
    return _client.put(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> patch(String endpoint, {Map<String, dynamic>? body}) async {
    final headers = await _getHeaders();
    return _client.patch(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    return _client.delete(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
    );
  }

  Future<http.Response> postMultipart(
    String endpoint,
    http.MultipartFile file,
  ) async {
    final headers = await _getHeaders();
    headers.remove('Content-Type'); 

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl$endpoint'),
    );
    request.headers.addAll(headers);
    request.files.add(file);

    final streamedResponse = await _client.send(request);
    return await http.Response.fromStream(streamedResponse);
  }
}
