import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/aop_provider.dart';
import '../widgets/aop_widgets.dart';
import 'aop_monthly_screen.dart';
import 'aop_table_screen.dart';
import 'aop_transactions_screen.dart';

class AopDashboardScreen extends ConsumerStatefulWidget {
  const AopDashboardScreen({super.key});

  @override
  ConsumerState<AopDashboardScreen> createState() => _AopDashboardScreenState();
}

class _AopDashboardScreenState extends ConsumerState<AopDashboardScreen> {
  int _selectedMonthIndex = 2; // Default to Jun (index 2 of activeMonths)

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(aopSummaryProvider('2026-27'));
    final monthlyAsync = ref.watch(aopMonthlyProvider((fy: '2026-27', month: _selectedMonthIndex)));

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('AOP Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          Chip(
            label: const Text('FY 2026-27', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopMetrics(summaryAsync),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Monthly Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    icon: const Icon(Icons.bar_chart),
                    label: const Text('View Charts'),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AopMonthlyScreen(monthIndex: _selectedMonthIndex)));
                    },
                  )
                ],
              ),
              const SizedBox(height: 16),
              _buildMonthSelector(summaryAsync),
              const SizedBox(height: 16),
              _buildCategoryList(monthlyAsync),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                      icon: const Icon(Icons.table_chart),
                      label: const Text('Full Table View'),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AopTableScreen()));
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: Colors.teal),
                      icon: const Icon(Icons.list_alt),
                      label: const Text('Transactions'),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AopTransactionsScreen()));
                      },
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopMetrics(AsyncValue summaryAsync) {
    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (data) {
        int mtdTarget = 0;
        int mtdActual = 0;
        int ytdTarget = 0;
        int ytdActual = 0;

        for (var cat in data.categories) {
          final t = data.targets[cat] as List<int>;
          final a = data.actuals[cat] as List<int>;
          
          if (t.length > 2) {
            mtdTarget += t[2];
            mtdActual += a[2];
          }
          for (int i = 0; i < t.length; i++) {
            ytdTarget += t[i];
            ytdActual += a[i];
          }
        }

        final mtdPct = mtdTarget > 0 ? (mtdActual / mtdTarget * 100).round() : 0;
        final ytdPct = ytdTarget > 0 ? (ytdActual / ytdTarget * 100).round() : 0;
        final shortfall = ytdTarget - ytdActual;

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            AopMetricCard(
              title: 'Current MTD',
              value: '$mtdActual / $mtdTarget',
              subtitle: '$mtdPct% Achieved',
              color: mtdPct >= 90 ? Colors.green : (mtdPct >= 50 ? Colors.orange : Colors.red),
            ),
            AopMetricCard(
              title: 'YTD Actual',
              value: '$ytdActual / $ytdTarget',
              subtitle: '$ytdPct% Achieved',
              color: ytdPct >= 90 ? Colors.green : (ytdPct >= 50 ? Colors.orange : Colors.red),
            ),
            AopMetricCard(
              title: 'YTD Shortfall',
              value: shortfall > 0 ? '$shortfall' : '0',
              subtitle: shortfall > 0 ? 'Behind Target' : 'Exceeded Target',
              color: shortfall > 0 ? Colors.red : Colors.green,
            ),
            const AopMetricCard(
              title: 'Best Category',
              value: 'MAGNETIC V',
              subtitle: '100% Achieved',
              color: Colors.green,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMonthSelector(AsyncValue summaryAsync) {
    return summaryAsync.when(
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
      data: (data) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(data.months.length, (index) {
              final m = data.months[index];
              final isSelected = index == _selectedMonthIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(m),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedMonthIndex = index);
                  },
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildCategoryList(AsyncValue monthlyAsync) {
    return monthlyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (data) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: data.rows.length + 1,
          itemBuilder: (context, index) {
            final isTotal = index == data.rows.length;
            final row = isTotal ? data.totals : data.rows[index];

            return Card(
              color: isTotal ? Colors.blue.shade50 : Colors.white,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(row.category, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.w600)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('T: ${row.target} | A: ${row.actual}'),
                        Text(row.shortfall > 0 ? 'S: ${row.shortfall}' : 'Exceeded', style: TextStyle(color: row.shortfall > 0 ? Colors.red : Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: row.target > 0 ? (row.actual / row.target).clamp(0.0, 1.0) : 0.0,
                      backgroundColor: Colors.grey.shade200,
                      color: row.status == 'achieved' ? Colors.green : (row.status == 'atRisk' ? Colors.orange : Colors.red),
                    ),
                  ],
                ),
                trailing: AopStatusBadge(status: row.status),
                onTap: isTotal ? null : () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => AopDrilldownSheet(fy: '2026-27', monthIndex: _selectedMonthIndex, category: row.category),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
