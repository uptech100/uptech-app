import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/auth_repository.dart';
import 'auth_remote_data_source.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/network/dio_client.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final LocalStorage _localStorage;

  AuthRepositoryImpl(this._remoteDataSource, this._localStorage);

  @override
  Future<bool> login(String mobile, String password) async {
    try {
      final data = await _remoteDataSource.login(mobile, password);
      
      final token = data['token'];
      final user = data['user'];
      
      await _localStorage.setString('uptech_token', token);
      await _localStorage.setString('uptech_user', jsonEncode(user));
      
      return true;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await _localStorage.remove('uptech_token');
    await _localStorage.remove('uptech_user');
  }

  @override
  Future<bool> checkAuthStatus() async {
    final token = _localStorage.getString('uptech_token');
    return token != null && token.isNotEmpty;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(localStorageProvider),
  );
});
