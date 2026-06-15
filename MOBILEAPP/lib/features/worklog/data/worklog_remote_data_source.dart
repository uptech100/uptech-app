import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';

abstract class WorklogRemoteDataSource {
  Future<Map<String, dynamic>> getTodayLog({String? date});
  Future<Map<String, dynamic>> addWorkEntry(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateWorkEntry(int entryId, Map<String, dynamic> data);
  Future<Map<String, dynamic>> finalizeLog(int logId);
  Future<List<dynamic>> getWorkHistory();
  Future<Map<String, dynamic>> getWorkerOptions();
}

class WorklogRemoteDataSourceImpl implements WorklogRemoteDataSource {
  final Dio _dio;

  WorklogRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> getTodayLog({String? date}) async {
    final response = await _dio.get(
      '/worklog/today',
      queryParameters: date != null ? {'date': date} : null,
    );
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> addWorkEntry(Map<String, dynamic> data) async {
    final response = await _dio.post('/worklog/entry', data: data);
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> updateWorkEntry(int entryId, Map<String, dynamic> data) async {
    final response = await _dio.put('/worklog/entry/$entryId', data: data);
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> finalizeLog(int logId) async {
    final response = await _dio.post('/worklog/finalize', data: {'logId': logId});
    return response.data;
  }

  @override
  Future<List<dynamic>> getWorkHistory() async {
    final response = await _dio.get('/worklog/history');
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getWorkerOptions() async {
    final response = await _dio.get('/worklog/options');
    return response.data;
  }
}

final worklogRemoteDataSourceProvider = Provider<WorklogRemoteDataSource>((ref) {
  return WorklogRemoteDataSourceImpl(ref.watch(dioClientProvider));
});
