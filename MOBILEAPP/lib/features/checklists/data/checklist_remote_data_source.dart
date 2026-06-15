import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';

abstract class ChecklistRemoteDataSource {
  Future<List<dynamic>> getAdminChecklists();
  Future<Map<String, dynamic>> createChecklistTemplate(Map<String, dynamic> data);
  Future<List<dynamic>> getMyChecklists({required String date});
  Future<Map<String, dynamic>> markChecklistComplete(Map<String, dynamic> data);
  Future<List<dynamic>> getChecklistHistory();
}

class ChecklistRemoteDataSourceImpl implements ChecklistRemoteDataSource {
  final Dio _dio;

  ChecklistRemoteDataSourceImpl(this._dio);

  @override
  Future<List<dynamic>> getAdminChecklists() async {
    final response = await _dio.get('/checklists/templates');
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> createChecklistTemplate(Map<String, dynamic> data) async {
    final response = await _dio.post('/checklists/templates', data: data);
    return response.data;
  }

  @override
  Future<List<dynamic>> getMyChecklists({required String date}) async {
    final response = await _dio.get('/checklists/my-logs', queryParameters: {'date': date});
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> markChecklistComplete(Map<String, dynamic> data) async {
    final response = await _dio.post('/checklists/logs', data: data);
    return response.data;
  }

  @override
  Future<List<dynamic>> getChecklistHistory() async {
    final response = await _dio.get('/checklists/history');
    return response.data;
  }
}

final checklistRemoteDataSourceProvider = Provider<ChecklistRemoteDataSource>((ref) {
  return ChecklistRemoteDataSourceImpl(ref.watch(dioClientProvider));
});
