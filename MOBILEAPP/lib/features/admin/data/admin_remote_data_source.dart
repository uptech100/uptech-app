import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';

abstract class AdminRemoteDataSource {
  Future<List<dynamic>> getDepartments();
  Future<Map<String, dynamic>> createDepartment(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateDepartment(String id, Map<String, dynamic> data);
  Future<void> deleteDepartment(String id);

  Future<List<dynamic>> getUsers();
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateUser(String id, Map<String, dynamic> data);
  Future<void> deleteUser(String id);
  Future<void> resetUserPassword(String id, String newPassword);

  Future<List<dynamic>> getRoles();
  Future<void> createRole(Map<String, dynamic> data);
  Future<void> updateRole(String id, Map<String, dynamic> data);
  Future<void> deleteRole(String id);
  Future<List<dynamic>> getProcesses();
  Future<Map<String, dynamic>> createProcess(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateProcess(int id, Map<String, dynamic> data);
  Future<void> deleteProcess(int id);

  Future<List<dynamic>> getProducts();
  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateProduct(int id, Map<String, dynamic> data);
  Future<void> deleteProduct(int id);
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final Dio _dio;

  AdminRemoteDataSourceImpl(this._dio);

  @override
  Future<List<dynamic>> getDepartments() async {
    final response = await _dio.get('/admin/departments');
    return response.data as List<dynamic>;
  }

  @override
  Future<Map<String, dynamic>> createDepartment(Map<String, dynamic> data) async {
    final response = await _dio.post('/admin/departments', data: data);
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> updateDepartment(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/admin/departments/$id', data: data);
    return response.data;
  }

  @override
  Future<void> deleteDepartment(String id) async {
    await _dio.delete('/admin/departments/$id');
  }

  @override
  Future<List<dynamic>> getUsers() async {
    final response = await _dio.get('/admin/users');
    return response.data as List<dynamic>;
  }

  @override
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    final response = await _dio.post('/admin/users', data: data);
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> updateUser(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/admin/users/$id', data: data);
    return response.data;
  }

  @override
  Future<void> deleteUser(String id) async {
    await _dio.delete('/admin/users/$id');
  }

  @override
  Future<void> resetUserPassword(String id, String newPassword) async {
    await _dio.post('/admin/users/$id/reset-password', data: {'password': newPassword});
  }

  @override
  Future<List<dynamic>> getRoles() async {
    final response = await _dio.get('/admin/roles');
    return response.data as List<dynamic>;
  }

  @override
  Future<void> createRole(Map<String, dynamic> data) async {
    await _dio.post('/admin/roles', data: data);
  }

  @override
  Future<void> updateRole(String id, Map<String, dynamic> data) async {
    await _dio.put('/admin/roles/$id', data: data);
  }

  @override
  Future<void> deleteRole(String id) async {
    await _dio.delete('/admin/roles/$id');
  }

  @override
  Future<List<dynamic>> getProcesses() async {
    final response = await _dio.get('/admin/processes');
    return response.data as List<dynamic>;
  }

  @override
  Future<Map<String, dynamic>> createProcess(Map<String, dynamic> data) async {
    final response = await _dio.post('/admin/processes', data: data);
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> updateProcess(int id, Map<String, dynamic> data) async {
    final response = await _dio.put('/admin/processes/$id', data: data);
    return response.data;
  }

  @override
  Future<void> deleteProcess(int id) async {
    await _dio.delete('/admin/processes/$id');
  }

  @override
  Future<List<dynamic>> getProducts() async {
    final response = await _dio.get('/admin/products');
    return response.data as List<dynamic>;
  }

  @override
  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    final response = await _dio.post('/admin/products', data: data);
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> updateProduct(int id, Map<String, dynamic> data) async {
    final response = await _dio.put('/admin/products/$id', data: data);
    return response.data;
  }

  @override
  Future<void> deleteProduct(int id) async {
    await _dio.delete('/admin/products/$id');
  }
}

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  return AdminRemoteDataSourceImpl(ref.watch(dioClientProvider));
});
