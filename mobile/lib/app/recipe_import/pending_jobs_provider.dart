import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../recipes/recipe_provider.dart';
import 'data/import_repository.dart';
import 'import_provider.dart';

class PendingJobsNotifier extends Notifier<List<ContentJob>> {
  Timer? _pollTimer;

  @override
  List<ContentJob> build() {
    ref.onDispose(() => _pollTimer?.cancel());
    _fetchPendingJobs();
    return [];
  }

  void addJob(ContentJob job) {
    state = [job, ...state];
    _startPolling();
  }

  Future<void> checkJobs() async {
    await _fetchPendingJobs();
  }

  Future<void> _fetchPendingJobs() async {
    try {
      final repo = ref.read(importRepositoryProvider);
      final jobs = _removeStaleJobs(
        await repo.fetchJobs(statuses: ['pending', 'processing']),
      );
      state = jobs;
      if (jobs.isNotEmpty) {
        _startPolling();
      } else {
        _stopPolling();
      }
    } catch (_) {}
  }

  void _startPolling() {
    if (_pollTimer?.isActive == true) return;
    _pollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _pollJobs(),
    );
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  static const _staleThreshold = Duration(minutes: 10);

  List<ContentJob> _removeStaleJobs(List<ContentJob> jobs) {
    final now = DateTime.now();
    return jobs.where((j) {
      if (j.createdAt == null) return true;
      final created = DateTime.tryParse(j.createdAt!);
      if (created == null) return true;
      return now.difference(created) < _staleThreshold;
    }).toList();
  }

  Future<void> _pollJobs() async {
    if (state.isEmpty) {
      _stopPolling();
      return;
    }

    try {
      final repo = ref.read(importRepositoryProvider);
      final updatedJobs = _removeStaleJobs(
        await repo.fetchJobs(statuses: ['pending', 'processing']),
      );

      final previousIds = state.map((j) => j.id).toSet();
      final currentIds = updatedJobs.map((j) => j.id).toSet();
      final completedIds = previousIds.difference(currentIds);

      if (completedIds.isNotEmpty) {
        ref.invalidate(recipesProvider);
      }

      state = updatedJobs;

      if (updatedJobs.isEmpty) {
        _stopPolling();
      }
    } catch (_) {
      _stopPolling();
      state = [];
    }
  }
}

final pendingJobsProvider =
    NotifierProvider<PendingJobsNotifier, List<ContentJob>>(
  PendingJobsNotifier.new,
);
