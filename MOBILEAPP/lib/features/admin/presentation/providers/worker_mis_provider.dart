import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';

final workerMisProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, params) async {
  final parts = params.split('|');
  final startDate = parts[0];
  final endDate = parts[1];
  final userId = parts.length > 2 ? parts[2] : '';
  
  if (userId.isEmpty) return null;

  final dio = ref.watch(dioClientProvider);
  final response = await dio.get('/mis/worker', queryParameters: {
    'startDate': startDate,
    'endDate': endDate,
    'userId': userId,
  });
  
  return response.data as Map<String, dynamic>;
});
