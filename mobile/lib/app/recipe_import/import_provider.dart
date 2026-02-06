import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import 'data/import_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final importRepositoryProvider = Provider<ImportRepository>((ref) {
  return ImportRepository(apiClient: ref.watch(apiClientProvider));
});
