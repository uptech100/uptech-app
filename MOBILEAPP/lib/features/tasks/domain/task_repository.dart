abstract class TaskRepository {
  Future<List<dynamic>> getMyTasks();
  Future<void> completeTask(String taskId, [double? timeTaken]);
  Future<List<dynamic>> getActiveUsers();
  Future<void> assignTask(Map<String, dynamic> data);
  Future<List<dynamic>> getTasksAssignedByMe();
  Future<void> reopenTask(String taskId);
}
