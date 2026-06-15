import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/checklist_repository_impl.dart';

// Providers for Admin Panel
final adminChecklistsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.watch(checklistRepositoryProvider);
  return await repo.getAdminChecklists();
});

// Providers for Worker App
final checklistDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final myChecklistsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.watch(checklistRepositoryProvider);
  final date = ref.watch(checklistDateProvider);
  
  // Format as YYYY-MM-DD
  final dateString = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  return await repo.getMyChecklists(date: dateString);
});

final checklistHistoryProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.watch(checklistRepositoryProvider);
  return await repo.getChecklistHistory();
});
