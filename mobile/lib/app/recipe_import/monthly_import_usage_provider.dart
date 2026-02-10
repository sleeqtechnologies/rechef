import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'import_provider.dart';

class MonthlyImportUsage {
  const MonthlyImportUsage({
    required this.used,
    required this.limit,
  });

  /// Number of imports the user has started in the current calendar month.
  final int used;

  /// The free-tier monthly limit.
  final int limit;
}

/// Tracks how many recipes the user has imported in the current calendar month.
///
/// This uses existing content jobs from the backend (no new endpoints). It
/// counts all jobs whose `createdAt` falls within the current UTC month.
final monthlyImportUsageProvider =
    FutureProvider<MonthlyImportUsage>((ref) async {
  final repo = ref.read(importRepositoryProvider);
  // Passing no statuses returns all jobs; we filter client-side by month.
  final jobs = await repo.fetchJobs();

  final now = DateTime.now().toUtc();
  final startOfMonth = DateTime.utc(now.year, now.month);
  final startOfNextMonth = now.month == 12
      ? DateTime.utc(now.year + 1, 1)
      : DateTime.utc(now.year, now.month + 1);

  int used = 0;
  for (final job in jobs) {
    final createdStr = job.createdAt;
    if (createdStr == null) continue;
    final created = DateTime.tryParse(createdStr)?.toUtc();
    if (created == null) continue;

    final isInMonth = !created.isBefore(startOfMonth) &&
        created.isBefore(startOfNextMonth);
    if (isInMonth) {
      used++;
    }
  }

  // Free users get 5 imports per calendar month.
  return MonthlyImportUsage(used: used, limit: 5);
});

