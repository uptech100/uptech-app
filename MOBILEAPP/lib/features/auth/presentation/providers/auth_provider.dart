import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../domain/auth_repository.dart';
import '../../data/auth_repository_impl.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  String? errorMessage;

  AuthNotifier(this._authRepository) : super(AuthState.initial) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    state = AuthState.loading;
    try {
      final isAuth = await _authRepository.checkAuthStatus();
      if (isAuth) {
        state = AuthState.authenticated;
      } else {
        state = AuthState.unauthenticated;
      }
    } catch (e) {
      errorMessage = e.toString();
      state = AuthState.error;
    }
  }

  Future<bool> login(String mobile, String password) async {
    state = AuthState.loading;
    errorMessage = null;
    
    try {
      final success = await _authRepository.login(mobile, password);
      if (success) {
        state = AuthState.authenticated;
        return true;
      }
      return false;
    } catch (e) {
      if (e is DioException) {
        errorMessage = e.response?.data['message'] ?? 'Connection error. Please try again.';
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      state = AuthState.error;
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    state = AuthState.unauthenticated;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
