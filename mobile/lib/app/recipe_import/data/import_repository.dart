import 'dart:convert';
import 'dart:io';
import '../../recipes/domain/recipe.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_endpoints.dart';

class SubmitResult {
  const SubmitResult({required this.jobId, required this.savedContentId});

  final String jobId;
  final String savedContentId;

  factory SubmitResult.fromJson(Map<String, dynamic> json) {
    return SubmitResult(
      jobId: json['jobId'] as String,
      savedContentId: json['savedContentId'] as String,
    );
  }
}

class ContentJob {
  const ContentJob({
    required this.id,
    required this.status,
    this.savedContentId,
    this.progress,
    this.error,
    this.createdAt,
    this.recipe,
  });

  final String id;
  final String status;
  final String? savedContentId;
  final int? progress;
  final String? error;
  final String? createdAt;
  final Recipe? recipe;

  bool get isPending => status == 'pending' || status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';

  factory ContentJob.fromJson(Map<String, dynamic> json) {
    return ContentJob(
      id: json['id'] as String,
      status: json['status'] as String,
      savedContentId: json['savedContentId'] as String?,
      progress: json['progress'] as int?,
      error: json['error'] as String?,
      createdAt: json['createdAt'] as String?,
      recipe: json['recipe'] != null
          ? Recipe.fromJson(json['recipe'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ImportRepository {
  ImportRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<SubmitResult> submitContent(String url) async {
    final response = await _apiClient.post(
      ApiEndpoints.parseContent,
      body: {'url': url},
    );

    if (response.statusCode != 202) {
      if (response.body.isEmpty) {
        throw Exception(
          'Server returned status ${response.statusCode} with no response',
        );
      }
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to submit content');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return SubmitResult.fromJson(data);
  }

  Future<SubmitResult> submitImage(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await _apiClient.post(
      ApiEndpoints.parseContent,
      body: {'imageBase64': base64Image},
    );

    if (response.statusCode != 202) {
      if (response.body.isEmpty) {
        throw Exception(
          'Server returned status ${response.statusCode} with no response',
        );
      }
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to submit image');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return SubmitResult.fromJson(data);
  }

  Future<List<ContentJob>> fetchJobs({List<String>? statuses}) async {
    String endpoint = ApiEndpoints.contentJobs;
    if (statuses != null && statuses.isNotEmpty) {
      endpoint += '?status=${statuses.join(',')}';
    }

    final response = await _apiClient.get(endpoint);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch jobs');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['jobs'] as List<dynamic>;
    return list
        .map((e) => ContentJob.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ContentJob> fetchJob(String jobId) async {
    final response = await _apiClient.get(ApiEndpoints.contentJob(jobId));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch job');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ContentJob.fromJson(data);
  }
}
