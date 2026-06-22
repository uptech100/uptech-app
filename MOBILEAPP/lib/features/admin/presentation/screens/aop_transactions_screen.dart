import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/aop_provider.dart';

class AopTransactionsScreen extends ConsumerWidget {
  const AopTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aopTransactionProvider);
    final notifier = ref.read(aopTransactionProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('AOP Transactions'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search Specification',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (val) {
                      // Basic debounce can be added here, for now directly filter
                      notifier.setFilters(search: val);
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading && state.data.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: state.data.length,
                    itemBuilder: (context, index) {
                      final t = state.data[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          leading: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(t.dispatchDate.split('T')[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          title: Text(t.specification, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text(t.category, style: const TextStyle(color: Colors.blue)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.teal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('${t.quantity} ${t.uom}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: state.page > 1 ? () => notifier.prevPage() : null,
                  child: const Text('Previous'),
                ),
                Text('Page ${state.page} of ${state.totalPages}'),
                TextButton(
                  onPressed: state.page < state.totalPages ? () => notifier.nextPage() : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
