import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/aop_provider.dart';

class AopTableScreen extends ConsumerWidget {
  const AopTableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tableAsync = ref.watch(aopTableProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('AOP Master Table'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: tableAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (data) {
          if (data.isEmpty) return const Center(child: Text('No AOP Data'));

          final months = [
            'Apr-26', 'May-26', 'Jun-26', 'Jul-26', 'Aug-26', 'Sep-26',
            'Oct-26', 'Nov-26', 'Dec-26', 'Jan-27', 'Feb-27', 'Mar-27'
          ];

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppTheme.primaryColor.withValues(alpha: 0.1)),
                    dataRowMaxHeight: 60,
                    columns: [
                      const DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                      ...months.map((m) => DataColumn(label: Text(m, style: const TextStyle(fontWeight: FontWeight.bold)))),
                    ],
                    rows: _buildRows(data, months),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<DataRow> _buildRows(List<dynamic> data, List<String> months) {
    List<DataRow> rows = [];
    
    // We add a single row per category, with target/actual formatted together
    for (var item in data) {
      final category = item['category'] as String;
      final targets = item['targets'] as Map<String, dynamic>;
      final achieved = item['achieved'] as Map<String, dynamic>;

      rows.add(DataRow(cells: [
        DataCell(Text(category, style: const TextStyle(fontWeight: FontWeight.bold))),
        ...months.map((m) {
          final t = targets[m] ?? 0;
          final a = achieved[m] ?? 0;
          return DataCell(
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('T: $t', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text('A: $a', style: TextStyle(fontWeight: FontWeight.bold, color: a >= t && t > 0 ? Colors.green : (a > 0 ? Colors.orange : Colors.black))),
              ],
            )
          );
        }),
      ]));
    }
    return rows;
  }
}
