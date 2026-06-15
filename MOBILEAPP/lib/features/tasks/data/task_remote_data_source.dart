import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';

abstract class TaskRemoteDataSource {
  Future<List<dynamic>> getMyTasks();
  Future<void> completeTask(String taskId, [double? timeTaken]);
  Future<List<dynamic>> getActiveUsers();
  Future<void> assignTask(Map<String, dynamic> data);
  Future<List<dynamic>> getTasksAssignedByMe();
  Future<void> reopenTask(String taskId);
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final Dio _dio;

  TaskRemoteDataSourceImpl(this._dio);

  @override
  Future<List<dynamic>> getMyTasks() async {
    try {
      final response = await _dio.get('/tasks/today');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch tasks');
    }
  }

  @override
  Future<void> completeTask(String taskId, [double? timeTaken]) async {
    try {
      final Map<String, dynamic> data = {};
      if (timeTaken != null) data['timeTaken'] = timeTaken;
      await _dio.put('/tasks/$taskId/complete', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to complete task');
    }
  }

  @override
  Future<List<dynamic>> getActiveUsers() async {
    try {
      final response = await _dio.get('/tasks/users');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch users');
    }
  }

  @override
  Future<void> assignTask(Map<String, dynamic> data) async {
    try {
      await _dio.post('/tasks', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to assign task');
    }
  }

  @override
  Future<List<dynamic>> getTasksAssignedByMe() async {
    try {
      final response = await _dio.get('/tasks/assigned-by-me');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch assigned tasks');
    }
  }

  @override
  Future<void> reopenTask(String taskId) async {
    try {
      await _dio.post('/tasks/$taskId/reopen');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to reopen task');
    }
  }
}

final taskRemoteDataSourceProvider = Provider<TaskRemoteDataSource>((ref) {
  return TaskRemoteDataSourceImpl(ref.watch(dioClientProvider));
});
