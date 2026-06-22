import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/aop_provider.dart';

class AopAnalysisScreen extends ConsumerWidget {
  const AopAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aopDataAsync = ref.watch(aopAnalysisProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: aopDataAsync.when(
        data: (data) {
          if (data.isEmpty) {
            return const Center(child: Text('No AOP Data available'));
          }

          // Predefine months exactly as per data
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
                  color: AppTheme.primaryWhite,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(AppTheme.primaryColor.withValues(alpha: 0.1)),
                    columns: [
                      const DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                      const DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                      ...months.map((m) => DataColumn(label: Text(m, style: const TextStyle(fontWeight: FontWeight.bold)))),
                    ],
                    rows: _buildRows(data, months),
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err\n\n$stack')),
      ),
    );
  }

  List<DataRow> _buildRows(List<dynamic> data, List<String> months) {
    List<DataRow> rows = [];
    
    for (var item in data) {
      final category = item['category'] as String;
      final targets = item['targets'] as Map<String, dynamic>;
      final achieved = item['achieved'] as Map<String, dynamic>;
      final shortfall = item['shortfall'] as Map<String, dynamic>;

      // Target Row
      rows.add(DataRow(cells: [
        DataCell(Text(category, style: const TextStyle(fontWeight: FontWeight.bold))),
        const DataCell(Text('Target', style: TextStyle(color: Colors.blue))),
        ...months.map((m) => DataCell(Text('${targets[m] ?? 0}'))),
      ]));

      // Achieved Row
      rows.add(DataRow(cells: [
        const DataCell(Text('')), // Empty for category to avoid repetition
        const DataCell(Text('Achieved', style: TextStyle(color: AppTheme.success))),
        ...months.map((m) => DataCell(Text('${achieved[m] ?? 0}'))),
      ]));

      // Shortfall Row
      rows.add(DataRow(cells: [
        const DataCell(Text('')),
        const DataCell(Text('Shortfall', style: TextStyle(color: AppTheme.danger))),
        ...months.map((m) {
          final s = shortfall[m] ?? 0;
          return DataCell(Text('$s', style: TextStyle(color: (s as int) > 0 ? AppTheme.danger : AppTheme.success)));
        }),
      ]));
    }
    return rows;
  }
}
