import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/admin_repository.dart';
import 'admin_remote_data_source.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource _remoteDataSource;

  AdminRepositoryImpl(this._remoteDataSource);

  String _handleError(dynamic e) {
    if (e is DioException) {
      return e.response?.data['message'] ?? e.message ?? 'Unknown error occurred';
    }
    return e.toString().replaceAll('Exception: ', '');
  }

  @override
  Future<List<dynamic>> getDepartments() async {
    try {
      return await _remoteDataSource.getDepartments();
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<Map<String, dynamic>> createDepartment(Map<String, dynamic> data) async {
    try {
      return await _remoteDataSource.createDepartment(data);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<Map<String, dynamic>> updateDepartment(String id, Map<String, dynamic> data) async {
    try {
      return await _remoteDataSource.updateDepartment(id, data);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<void> deleteDepartment(String id) async {
    try {
      await _remoteDataSource.deleteDepartment(id);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<List<dynamic>> getUsers() async {
    try {
      return await _remoteDataSource.getUsers();
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    try {
      return await _remoteDataSource.createUser(data);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<Map<String, dynamic>> updateUser(String id, Map<String, dynamic> data) async {
    try {
      return await _remoteDataSource.updateUser(id, data);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    try {
      await _remoteDataSource.deleteUser(id);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<void> resetUserPassword(String id, String newPassword) async {
    try {
      await _remoteDataSource.resetUserPassword(id, newPassword);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<List<dynamic>> getRoles() async {
    try {
      return await _remoteDataSource.getRoles();
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<void> createRole(Map<String, dynamic> data) async {
    try {
      await _remoteDataSource.createRole(data);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<void> updateRole(String id, Map<String, dynamic> data) async {
    try {
      await _remoteDataSource.updateRole(id, data);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<void> deleteRole(String id) async {
    try {
      await _remoteDataSource.deleteRole(id);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<List<dynamic>> getProcesses() async {
    try {
      return await _remoteDataSource.getProcesses();
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<Map<String, dynamic>> createProcess(Map<String, dynamic> data) async {
    try {
      return await _remoteDataSource.createProcess(data);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<Map<String, dynamic>> updateProcess(int id, Map<String, dynamic> data) async {
    try {
      return await _remoteDataSource.updateProcess(id, data);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<void> deleteProcess(int id) async {
    try {
      await _remoteDataSource.deleteProcess(id);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<List<dynamic>> getProducts() async {
    try {
      return await _remoteDataSource.getProducts();
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    try {
      return await _remoteDataSource.createProduct(data);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<Map<String, dynamic>> updateProduct(int id, Map<String, dynamic> data) async {
    try {
      return await _remoteDataSource.updateProduct(id, data);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<void> deleteProduct(int id) async {
    try {
      await _remoteDataSource.deleteProduct(id);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<List<dynamic>> getMisReports(String startDate, String endDate) async {
    try {
      return await _remoteDataSource.getMisReports(startDate, endDate);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(ref.watch(adminRemoteDataSourceProvider));
});
