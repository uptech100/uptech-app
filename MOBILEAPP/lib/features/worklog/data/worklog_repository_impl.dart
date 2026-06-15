import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/worklog_repository.dart';
import 'worklog_remote_data_source.dart';

class WorklogRepositoryImpl implements WorklogRepository {
  final WorklogRemoteDataSource _remoteDataSource;

  WorklogRepositoryImpl(this._remoteDataSource);

  String _handleError(dynamic e) {
    if (e is DioException) {
      return e.response?.data['message'] ?? e.message ?? 'Unknown error occurred';
    }
    return e.toString().replaceAll('Exception: ', '');
  }

  @override
  Future<Map<String, dynamic>> getTodayLog({String? date}) async {
    try {
      return await _remoteDataSource.getTodayLog(date: date);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<Map<String, dynamic>> addWorkEntry(Map<String, dynamic> data) async {
    try {
      return await _remoteDataSource.addWorkEntry(data);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<Map<String, dynamic>> updateWorkEntry(int entryId, Map<String, dynamic> data) async {
    try {
      return await _remoteDataSource.updateWorkEntry(entryId, data);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<Map<String, dynamic>> finalizeLog(int logId) async {
    try {
      return await _remoteDataSource.finalizeLog(logId);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<List<dynamic>> getWorkHistory() async {
    try {
      return await _remoteDataSource.getWorkHistory();
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<Map<String, dynamic>> getWorkerOptions() async {
    try {
      return await _remoteDataSource.getWorkerOptions();
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }
}

final worklogRepositoryProvider = Provider<WorklogRepository>((ref) {
  return WorklogRepositoryImpl(ref.watch(worklogRemoteDataSourceProvider));
});
