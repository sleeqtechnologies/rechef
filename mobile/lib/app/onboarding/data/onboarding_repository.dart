import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../domain/onboarding_data.dart';

const _onboardingCompleteKey = 'onboarding_complete';
const _onboardingDataKey = 'onboarding_data';

class OnboardingRepository {
  OnboardingRepository({required this.apiClient});

  final ApiClient apiClient;

  // --- Local persistence via SharedPreferences ---

  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
  }

  Future<void> saveOnboardingDataLocally(OnboardingData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_onboardingDataKey, data.toJsonString());
  }

  Future<OnboardingData?> loadOnboardingDataLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_onboardingDataKey);
    if (jsonString == null) return null;
    try {
      return OnboardingData.fromJsonString(jsonString);
    } catch (e) {
      debugPrint('[OnboardingRepository] Failed to parse local data: $e');
      return null;
    }
  }

  // --- API sync ---

  Future<void> syncOnboardingData(OnboardingData data) async {
    try {
      await apiClient.post('/api/users/onboarding', body: {
        'goals': data.goals,
        'recipeSources': data.recipeSources,
        'organizationMethod': data.organizationMethod,
      });
    } catch (e) {
      debugPrint('[OnboardingRepository] Failed to sync onboarding data: $e');
    }
  }

  Future<void> syncPantryItems(List<String> items) async {
    if (items.isEmpty) return;
    try {
      await apiClient.post('/api/pantry', body: {
        'items': items,
      });
    } catch (e) {
      debugPrint('[OnboardingRepository] Failed to sync pantry items: $e');
    }
  }
}

/// Provider for the onboarding repository.
final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(apiClient: ApiClient());
});

/// Provider that exposes whether onboarding has been completed.
/// This is read by the router to determine the initial redirect.
final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final repo = ref.read(onboardingRepositoryProvider);
  return repo.hasCompletedOnboarding();
});
