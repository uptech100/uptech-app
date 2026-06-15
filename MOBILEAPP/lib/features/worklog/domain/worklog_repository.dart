abstract class WorklogRepository {
  Future<Map<String, dynamic>> getTodayLog({String? date});
  Future<Map<String, dynamic>> addWorkEntry(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateWorkEntry(int entryId, Map<String, dynamic> data);
  Future<Map<String, dynamic>> finalizeLog(int logId);
  Future<List<dynamic>> getWorkHistory();
  Future<Map<String, dynamic>> getWorkerOptions();
}
