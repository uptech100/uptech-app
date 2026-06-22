import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/aop_models.dart';
import '../providers/aop_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AopMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const AopMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class AopStatusBadge extends StatelessWidget {
  final String status;

  const AopStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case 'achieved':
        bg = Colors.green.withValues(alpha: 0.2);
        text = Colors.green[800]!;
        label = 'Achieved';
        break;
      case 'atRisk':
        bg = Colors.orange.withValues(alpha: 0.2);
        text = Colors.orange[800]!;
        label = 'At Risk';
        break;
      case 'critical':
        bg = Colors.red.withValues(alpha: 0.2);
        text = Colors.red[800]!;
        label = 'Critical';
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.2);
        text = Colors.grey[800]!;
        label = 'N/A';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class AopDrilldownSheet extends ConsumerWidget {
  final String fy;
  final int monthIndex;
  final String category;

  const AopDrilldownSheet({
    super.key,
    required this.fy,
    required this.monthIndex,
    required this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(aopDrilldownProvider((fy: fy, month: monthIndex, category: category)));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: asyncData.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (data) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('${data.category} - ${data.month}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Target: ${data.target}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text('Actual: ${data.actual}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      Text('Shortfall: ${data.target - data.actual}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 30),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: data.specs.length,
                      itemBuilder: (context, index) {
                        final spec = data.specs[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(spec.specCode, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(spec.specFull, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Qty: ${spec.totalQty}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('${spec.sharePct}% share', style: const TextStyle(fontSize: 12, color: Colors.blue)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: spec.sharePct / 100,
                                  backgroundColor: Colors.grey[200],
                                  color: Colors.blue,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class AopBarChart extends StatelessWidget {
  final List<AopMonthlyRow> rows;

  const AopBarChart({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox();
    
    double maxY = 0;
    for (var r in rows) {
      if (r.target > maxY) maxY = r.target.toDouble();
      if (r.actual > maxY) maxY = r.actual.toDouble();
    }
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= rows.length) return const SizedBox();
                final cat = rows[index].category;
                final abbr = cat.length > 5 ? cat.substring(0, 5) : cat;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(abbr, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        barGroups: rows.asMap().entries.map((e) {
          final i = e.key;
          final r = e.value;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: r.target.toDouble(),
                color: Colors.blue.withValues(alpha: 0.4),
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
              BarChartRodData(
                toY: r.actual.toDouble(),
                color: Colors.teal,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
