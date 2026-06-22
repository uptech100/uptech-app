import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/aop_models.dart';
import '../../data/repositories/aop_repository.dart';
import '../../../../core/network/dio_client.dart';

// Table Provider (Legacy endpoint refactored to support existing table + new structure)
final aopTableProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.watch(dioClientProvider);
  final response = await dio.get('/aop/table');
  return response.data as List<dynamic>;
});

// Summary provider
final aopSummaryProvider = FutureProvider.family<AopSummaryModel, String>((ref, fy) async {
  final repo = ref.read(aopRepositoryProvider);
  return repo.getSummary(fy);
});

// Monthly provider
final aopMonthlyProvider = FutureProvider.family<AopMonthlyModel, ({String fy, int month})>((ref, params) async {
  return ref.read(aopRepositoryProvider).getMonthly(params.fy, params.month);
});

// Drilldown provider
final aopDrilldownProvider = FutureProvider.family<AopDrilldownModel, ({String fy, int month, String category})>((ref, params) async {
  return ref.read(aopRepositoryProvider).getDrilldown(params.fy, params.month, params.category);
});

class AopTransactionState {
  final List<AopTransaction> data;
  final int total;
  final int page;
  final int totalPages;
  final bool isLoading;
  final String? error;

  AopTransactionState({
    required this.data,
    required this.total,
    required this.page,
    required this.totalPages,
    this.isLoading = false,
    this.error,
  });

  factory AopTransactionState.initial() => AopTransactionState(data: [], total: 0, page: 1, totalPages: 1, isLoading: true);
}

class AopTransactionNotifier extends StateNotifier<AopTransactionState> {
  final AopRepository _repo;
  String? _category;
  int? _month;
  String _search = '';
  int _page = 1;

  AopTransactionNotifier(this._repo) : super(AopTransactionState.initial()) {
    _fetch();
  }

  Future<void> _fetch() async {
    state = AopTransactionState(data: state.data, total: state.total, page: state.page, totalPages: state.totalPages, isLoading: true);
    try {
      final res = await _repo.getTransactions(fy: '2026-27', category: _category, month: _month, search: _search, page: _page);
      state = AopTransactionState(data: res.data, total: res.total, page: res.page, totalPages: res.totalPages, isLoading: false);
    } catch (e) {
      state = AopTransactionState(data: state.data, total: state.total, page: state.page, totalPages: state.totalPages, isLoading: false, error: e.toString());
    }
  }

  void setFilters({String? category, int? month, String search = ''}) {
    _category = category;
    _month = month;
    _search = search;
    _page = 1;
    _fetch();
  }

  void nextPage() {
    if (_page < state.totalPages) {
      _page++;
      _fetch();
    }
  }

  void prevPage() {
    if (_page > 1) {
      _page--;
      _fetch();
    }
  }
}

final aopTransactionProvider = StateNotifierProvider<AopTransactionNotifier, AopTransactionState>((ref) {
  return AopTransactionNotifier(ref.watch(aopRepositoryProvider));
});
