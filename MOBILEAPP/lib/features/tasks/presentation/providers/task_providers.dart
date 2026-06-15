import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/task_repository_impl.dart';

final activeUsersProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(taskRepositoryProvider);
  return await repo.getActiveUsers();
});

final assignedByMeTasksProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(taskRepositoryProvider);
  return await repo.getTasksAssignedByMe();
});
