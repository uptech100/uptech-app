import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final aopAnalysisProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final token = ref.read(authProvider).token;
  if (token == null) throw Exception('Not authenticated');

  final response = await http.get(
    Uri.parse('${ApiConstants.baseUrl}/api/aop/analysis'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data as List<dynamic>;
  } else {
    throw Exception('Failed to load AOP analysis: ${response.statusCode}');
  }
});
