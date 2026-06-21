import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_repository_impl.dart';

// Departments Provider
final departmentsProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return await repo.getDepartments();
});

// Users Provider
final usersProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return await repo.getUsers();
});

// Roles Provider
final rolesProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return await repo.getRoles();
});

// Processes Provider
final processesProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return await repo.getProcesses();
});

// Products Provider
final productsProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return await repo.getProducts();
});

// MIS Reports Provider
final misReportsProvider = FutureProvider.family<List<dynamic>, String>((ref, dateRange) async {
  final parts = dateRange.split('|');
  final startDate = parts[0];
  final endDate = parts[1];
  final repo = ref.watch(adminRepositoryProvider);
  return await repo.getMisReports(startDate, endDate);
});

// Dashboard Stats Provider (Computed from departments and users)
final adminDashboardStatsProvider = Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final usersState = ref.watch(usersProvider);
  final deptsState = ref.watch(departmentsProvider);

  if (usersState is AsyncLoading || deptsState is AsyncLoading) {
    return const AsyncValue.loading();
  }
  if (usersState is AsyncError) {
    return AsyncValue.error(usersState.error!, usersState.stackTrace!);
  }
  if (deptsState is AsyncError) {
    return AsyncValue.error(deptsState.error!, deptsState.stackTrace!);
  }

  final users = usersState.value ?? [];
  final depts = deptsState.value ?? [];

  int activeUsers = 0;
  int inactiveUsers = 0;

  for (var user in users) {
    if (user['status'] == 'Active') {
      activeUsers++;
    } else {
      inactiveUsers++;
    }
  }

  return AsyncValue.data({
    'totalUsers': users.length,
    'totalDepartments': depts.length,
    'activeUsers': activeUsers,
    'inactiveUsers': inactiveUsers,
  });
});
