abstract class ChecklistRepository {
  Future<List<dynamic>> getAdminChecklists();
  Future<Map<String, dynamic>> createChecklistTemplate(Map<String, dynamic> data);
  Future<List<dynamic>> getMyChecklists({required String date});
  Future<Map<String, dynamic>> markChecklistComplete(Map<String, dynamic> data);
  Future<List<dynamic>> getChecklistHistory();
}
