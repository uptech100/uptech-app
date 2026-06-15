import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/worklog_repository_impl.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final todayLogProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(worklogRepositoryProvider);
  final date = ref.watch(selectedDateProvider);
  // Send clean date string to avoid timezone parsing issues
  final dateString = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  return await repo.getTodayLog(date: dateString);
});

final workHistoryProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(worklogRepositoryProvider);
  return await repo.getWorkHistory();
});

final workerOptionsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(worklogRepositoryProvider);
  return await repo.getWorkerOptions();
});
