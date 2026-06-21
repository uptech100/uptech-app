import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';

final workerMisProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, dateRange) async {
  final parts = dateRange.split('|');
  final startDate = parts[0];
  final endDate = parts[1];
  
  final dio = ref.watch(dioClientProvider);
  final response = await dio.get('/mis/worker', queryParameters: {
    'startDate': startDate,
    'endDate': endDate,
  });
  
  return response.data as Map<String, dynamic>;
});
