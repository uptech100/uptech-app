import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

final aopAnalysisProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.watch(dioClientProvider);
  
  try {
    final response = await dio.get('/api/aop/analysis');

    if (response.statusCode == 200) {
      return response.data as List<dynamic>;
    } else {
      throw Exception('Failed to load AOP analysis: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to load AOP analysis: $e');
  }
});
