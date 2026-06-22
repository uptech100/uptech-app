import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/aop_provider.dart';
import '../widgets/aop_widgets.dart';

class AopMonthlyScreen extends ConsumerWidget {
  final int monthIndex;

  const AopMonthlyScreen({super.key, required this.monthIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyAsync = ref.watch(aopMonthlyProvider((fy: '2026-27', month: monthIndex)));

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Monthly AOP Charts'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: monthlyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (data) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Target vs Actual - ${data.month}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        height: 300,
                        child: AopBarChart(rows: data.rows),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Category Breakdown', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.rows.length,
                    itemBuilder: (context, index) {
                      final row = data.rows[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(row.category, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('T: ${row.target} | A: ${row.actual}'),
                          trailing: AopStatusBadge(status: row.status),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => AopDrilldownSheet(fy: '2026-27', monthIndex: monthIndex, category: row.category),
                            );
                          },
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
