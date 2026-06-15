import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage/local_storage.dart';

import '../constants/api_constants.dart';

class DioClient {
  static String get baseUrl => ApiConstants.baseUrl;
  final Dio dio;

  DioClient(LocalStorage localStorage)
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = localStorage.getString('uptech_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate';
        options.headers['Pragma'] = 'no-cache';
        options.headers['Expires'] = '0';
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          await localStorage.remove('uptech_token');
          await localStorage.remove('uptech_user');
          // Global navigation handled via riverpod listening to auth state
        }
        return handler.next(e);
      },
    ));
  }
}

// Providers
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize this in main()');
});

final localStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage(ref.watch(sharedPreferencesProvider));
});

final dioClientProvider = Provider<Dio>((ref) {
  return DioClient(ref.watch(localStorageProvider)).dio;
});
