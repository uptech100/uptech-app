abstract class AuthRepository {
  Future<bool> login(String mobile, String password);
  Future<void> logout();
  Future<bool> checkAuthStatus();
}
