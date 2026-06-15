abstract class AdminRepository {
  // Departments
  Future<List<dynamic>> getDepartments();
  Future<Map<String, dynamic>> createDepartment(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateDepartment(String id, Map<String, dynamic> data);
  Future<void> deleteDepartment(String id);

  // Users
  Future<List<dynamic>> getUsers();
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateUser(String id, Map<String, dynamic> data);
  Future<void> deleteUser(String id);
  Future<void> resetUserPassword(String id, String newPassword);

  // Roles
  Future<List<dynamic>> getRoles();
  Future<void> createRole(Map<String, dynamic> data);
  Future<void> updateRole(String id, Map<String, dynamic> data);
  Future<void> deleteRole(String id);

  // Processes
  Future<List<dynamic>> getProcesses();
  Future<Map<String, dynamic>> createProcess(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateProcess(int id, Map<String, dynamic> data);
  Future<void> deleteProcess(int id);

  // Products
  Future<List<dynamic>> getProducts();
  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateProduct(int id, Map<String, dynamic> data);
  Future<void> deleteProduct(int id);
}
