import '../domain/qc_repository.dart';
import '../domain/models/qc_item.dart';
import '../domain/models/qc_daily_log.dart';
import 'qc_remote_data_source.dart';

class QCRepositoryImpl implements QCRepository {
  final QCRemoteDataSource remoteDataSource;

  QCRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Map<String, List<QCItem>>> getQCItemsGroupedByCategory() async {
    final response = await remoteDataSource.getQCItems();
    final itemsList = (response['items'] as List).map((i) => QCItem.fromJson(i)).toList();
    
    final Map<String, List<QCItem>> grouped = {};
    for (var item in itemsList) {
      if (!grouped.containsKey(item.category)) {
        grouped[item.category] = [];
      }
      grouped[item.category]!.add(item);
    }
    return grouped;
  }

  @override
  Future<List<String>> getCategories() async {
    final response = await remoteDataSource.getQCItems();
    return List<String>.from(response['categories']);
  }

  @override
  Future<QCItem> addQCItem(String itemCode, String category, String description, String uom) async {
    final response = await remoteDataSource.addQCItem(itemCode, category, description, uom);
    return QCItem.fromJson(response);
  }

  @override
  Future<QCDailyLog> submitQCReport(DateTime date, List<Map<String, dynamic>> entries) async {
    final response = await remoteDataSource.submitQCReport(date, entries);
    return QCDailyLog.fromJson(response);
  }

  @override
  Future<List<QCDailyLog>> getQCReportsHistory() async {
    final responseList = await remoteDataSource.getQCReportsHistory();
    return responseList.map((json) => QCDailyLog.fromJson(json)).toList();
  }
}
