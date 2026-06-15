import 'package:dio/dio.dart';

class QCRemoteDataSource {
  final Dio _dio;

  QCRemoteDataSource({required Dio dio}) : _dio = dio;

  Future<Map<String, dynamic>> getQCItems() async {
    final response = await _dio.get('/qc/items');
    return response.data;
  }

  Future<Map<String, dynamic>> addQCItem(String itemCode, String category, String description, String uom) async {
    final response = await _dio.post(
      '/qc/items',
      data: {
        'itemCode': itemCode,
        'category': category,
        'description': description,
        'uom': uom,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> submitQCReport(DateTime date, List<Map<String, dynamic>> entries) async {
    final response = await _dio.post(
      '/qc/report',
      data: {
        'date': date.toIso8601String(),
        'entries': entries,
      },
    );
    return response.data;
  }

  Future<List<dynamic>> getQCReportsHistory() async {
    final response = await _dio.get('/qc/report/history');
    return response.data;
  }
}
