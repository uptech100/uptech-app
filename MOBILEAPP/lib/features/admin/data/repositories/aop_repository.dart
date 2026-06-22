import 'package:dio/dio.dart';
import '../../domain/models/aop_models.dart';
import '../../../../core/network/dio_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AopRepository {
  final Dio _dio;

  AopRepository(this._dio);

  Future<AopSummaryModel> getSummary(String fy) async {
    final response = await _dio.get('/aop/summary', queryParameters: {'fy': fy});
    return AopSummaryModel.fromJson(response.data);
  }

  Future<AopMonthlyModel> getMonthly(String fy, int month) async {
    final response = await _dio.get('/aop/monthly', queryParameters: {'fy': fy, 'month': month});
    return AopMonthlyModel.fromJson(response.data);
  }

  Future<AopDrilldownModel> getDrilldown(String fy, int month, String category) async {
    final response = await _dio.get('/aop/drilldown', queryParameters: {
      'fy': fy,
      'month': month,
      'category': category,
    });
    return AopDrilldownModel.fromJson(response.data);
  }

  Future<({List<AopTransaction> data, int total, int page, int totalPages})> getTransactions({
    required String fy,
    String? category,
    int? month,
    String search = '',
    int page = 1,
  }) async {
    final response = await _dio.get('/aop/transactions', queryParameters: {
      'fy': fy,
      if (category != null) 'category': category,
      if (month != null) 'month': month,
      if (search.isNotEmpty) 'search': search,
      'page': page,
    });
    
    final data = (response.data['data'] as List).map((t) => AopTransaction.fromJson(t)).toList();
    return (
      data: data,
      total: response.data['total'] as int,
      page: response.data['page'] as int,
      totalPages: response.data['totalPages'] as int,
    );
  }
}

final aopRepositoryProvider = Provider<AopRepository>((ref) {
  return AopRepository(ref.watch(dioClientProvider));
});
