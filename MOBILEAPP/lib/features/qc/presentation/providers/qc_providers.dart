import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/qc_repository.dart';
import '../../data/qc_remote_data_source.dart';
import '../../data/qc_repository_impl.dart';
import '../../domain/models/qc_item.dart';
import '../../domain/models/qc_daily_log.dart';

final qcRemoteDataSourceProvider = Provider<QCRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return QCRemoteDataSource(dio: dio);
});

final qcRepositoryProvider = Provider<QCRepository>((ref) {
  final remoteDataSource = ref.read(qcRemoteDataSourceProvider);
  return QCRepositoryImpl(remoteDataSource: remoteDataSource);
});

final qcItemsGroupedProvider = FutureProvider<Map<String, List<QCItem>>>((ref) async {
  final repository = ref.read(qcRepositoryProvider);
  return repository.getQCItemsGroupedByCategory();
});

final qcCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.read(qcRepositoryProvider);
  return repository.getCategories();
});

final qcReportsHistoryProvider = FutureProvider<List<QCDailyLog>>((ref) async {
  final repository = ref.read(qcRepositoryProvider);
  return repository.getQCReportsHistory();
});
