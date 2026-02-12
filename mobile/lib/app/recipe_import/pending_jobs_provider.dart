import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/recipe_ready_notifications.dart';
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

  void dismissJob(String jobId) {
    state = state.where((j) => j.id != jobId).toList();
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
      final existingFailed = state.where((j) => j.isFailed).toList();
      state = [...existingFailed, ...jobs];
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
    final pendingInState = state.where((j) => !j.isFailed).toList();
    if (pendingInState.isEmpty) {
      _stopPolling();
      return;
    }

    try {
      final repo = ref.read(importRepositoryProvider);
      final updatedJobs = _removeStaleJobs(
        await repo.fetchJobs(statuses: ['pending', 'processing']),
      );

      final previousPendingIds = pendingInState.map((j) => j.id).toSet();
      final currentPendingIds = updatedJobs.map((j) => j.id).toSet();
      final disappearedIds = previousPendingIds.difference(currentPendingIds);

      final List<ContentJob> newFailedJobs = [];
      bool hasCompleted = false;

      for (final id in disappearedIds) {
        try {
          final job = await repo.fetchJob(id);
          if (job.isFailed) {
            newFailedJobs.add(job);
          } else {
            hasCompleted = true;
          }
        } catch (_) {
          hasCompleted = true;
        }
      }

      if (hasCompleted) {
        ref.invalidate(recipesProvider);
        if (WidgetsBinding.instance.lifecycleState !=
            AppLifecycleState.resumed) {
          RecipeReadyNotifications.instance.show();
        }
      }

      final existingFailed = state.where((j) => j.isFailed).toList();
      state = [...existingFailed, ...newFailedJobs, ...updatedJobs];

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
