import 'models/qc_item.dart';
import 'models/qc_daily_log.dart';

abstract class QCRepository {
  Future<Map<String, List<QCItem>>> getQCItemsGroupedByCategory();
  Future<List<String>> getCategories();
  Future<QCItem> addQCItem(String itemCode, String category, String description, String uom);
  Future<QCDailyLog> submitQCReport(DateTime date, List<Map<String, dynamic>> entries);
  Future<List<QCDailyLog>> getQCReportsHistory();
}
