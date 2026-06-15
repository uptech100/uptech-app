import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/checklist_repository.dart';
import 'checklist_remote_data_source.dart';

class ChecklistRepositoryImpl implements ChecklistRepository {
  final ChecklistRemoteDataSource _remoteDataSource;

  ChecklistRepositoryImpl(this._remoteDataSource);

  String _handleError(dynamic e) {
    if (e is DioException) {
      return e.response?.data['message'] ?? e.message ?? 'Unknown error occurred';
    }
    return e.toString().replaceAll('Exception: ', '');
  }

  @override
  Future<List<dynamic>> getAdminChecklists() async {
    try {
      return await _remoteDataSource.getAdminChecklists();
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<Map<String, dynamic>> createChecklistTemplate(Map<String, dynamic> data) async {
    try {
      return await _remoteDataSource.createChecklistTemplate(data);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<List<dynamic>> getMyChecklists({required String date}) async {
    try {
      return await _remoteDataSource.getMyChecklists(date: date);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<Map<String, dynamic>> markChecklistComplete(Map<String, dynamic> data) async {
    try {
      return await _remoteDataSource.markChecklistComplete(data);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<List<dynamic>> getChecklistHistory() async {
    try {
      return await _remoteDataSource.getChecklistHistory();
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }
}

final checklistRepositoryProvider = Provider<ChecklistRepository>((ref) {
  return ChecklistRepositoryImpl(ref.watch(checklistRemoteDataSourceProvider));
});
