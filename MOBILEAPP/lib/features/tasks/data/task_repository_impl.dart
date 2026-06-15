import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/task_repository.dart';
import 'task_remote_data_source.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource _remoteDataSource;

  TaskRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<dynamic>> getMyTasks() {
    return _remoteDataSource.getMyTasks();
  }

  @override
  Future<void> completeTask(String taskId, [double? timeTaken]) {
    return _remoteDataSource.completeTask(taskId, timeTaken);
  }

  @override
  Future<List<dynamic>> getActiveUsers() {
    return _remoteDataSource.getActiveUsers();
  }

  @override
  Future<void> assignTask(Map<String, dynamic> data) {
    return _remoteDataSource.assignTask(data);
  }

  @override
  Future<List<dynamic>> getTasksAssignedByMe() {
    return _remoteDataSource.getTasksAssignedByMe();
  }

  @override
  Future<void> reopenTask(String taskId) {
    return _remoteDataSource.reopenTask(taskId);
  }
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepositoryImpl(ref.watch(taskRemoteDataSourceProvider));
});
