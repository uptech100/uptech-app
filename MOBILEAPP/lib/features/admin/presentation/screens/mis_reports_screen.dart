import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/admin_providers.dart';

class MisReportsScreen extends ConsumerStatefulWidget {
  const MisReportsScreen({super.key});

  @override
  ConsumerState<MisReportsScreen> createState() => _MisReportsScreenState();
}

class _MisReportsScreenState extends ConsumerState<MisReportsScreen> {
  String _selectedFilter = 'Weekly';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  final List<String> _filters = ['Weekly', 'Quarterly', '6 Months', '1 Year', 'Custom'];

  void _updateDates(String filter) {
    setState(() {
      _selectedFilter = filter;
      final now = DateTime.now();
      _endDate = now;

      switch (filter) {
        case 'Weekly':
          _startDate = now.subtract(const Duration(days: 7));
          break;
        case 'Quarterly':
          _startDate = now.subtract(const Duration(days: 90));
          break;
        case '6 Months':
          _startDate = now.subtract(const Duration(days: 180));
          break;
        case '1 Year':
          _startDate = now.subtract(const Duration(days: 365));
          break;
        case 'Custom':
          // Keep existing dates
          break;
      }
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: AppTheme.primaryWhite,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedFilter = 'Custom';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateRange = '${_startDate.toIso8601String()}|${_endDate.toIso8601String()}';

    final misDataAsync = ref.watch(misReportsProvider(dateRange));

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Column(
        children: [
          _buildFilterHeader(),
          Expanded(
            child: misDataAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
              error: (err, stack) => Center(
                child: Text('Error: ${err.toString()}', style: const TextStyle(color: AppTheme.danger)),
              ),
              data: (data) => _buildDataList(data),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeader() {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.primaryWhite,
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Performance Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              DropdownButton<String>(
                value: _selectedFilter,
                dropdownColor: AppTheme.primaryWhite,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                underline: Container(height: 2, color: AppTheme.primaryColor),
                icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    if (newValue == 'Custom') {
                      _selectDateRange(context);
                    } else {
                      _updateDates(newValue);
                    }
                  }
                },
                items: _filters.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Showing data from ${dateFormat.format(_startDate)} to ${dateFormat.format(_endDate)}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDataList(List<dynamic> data) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No active users found.', style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final user = data[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final tasks = user['tasks'];
    final checklists = user['checklists'];
    final metrics = user['metrics'] ?? {
      'time': 0,
      'quantity': 0,
      'quality': 0,
      'cost': 0,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppTheme.primaryWhite,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                  child: Text(
                    user['name'][0].toUpperCase(),
                    style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${user['department']} | ${user['role']}',
                        style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildStatSection('Tasks', tasks)),
                Container(width: 1, height: 100, color: Colors.white10),
                Expanded(child: _buildStatSection('Checklists', checklists)),
              ],
            ),
            const Divider(color: Colors.white10, height: 32),
            Row(
              children: [
                Expanded(child: _buildMetricItem(Icons.timer_outlined, 'Time Logged', '${metrics['time']} Hrs', Colors.blue)),
                Expanded(child: _buildMetricItem(Icons.inventory_2_outlined, 'Quantity', '${metrics['quantity']} Pairs', Colors.orange)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildMetricItem(Icons.verified_outlined, 'Quality Passed', '${metrics['quality']}', Colors.green)),
                Expanded(child: _buildMetricItem(Icons.currency_rupee_outlined, 'Cost', '₹${metrics['cost']}', Colors.purple)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatSection(String title, Map<String, dynamic> stats) {
    final int score = stats['score'] ?? 0;
    final bool isNegative = score < 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:', style: TextStyle(color: AppTheme.textSecondary)),
              Text('${stats['total']}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Completed:', style: TextStyle(color: AppTheme.textSecondary)),
              Text('${stats['completed']}', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pending:', style: TextStyle(color: AppTheme.textSecondary)),
              Text('${stats['pending']}', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: isNegative ? AppTheme.danger.withOpacity(0.1) : AppTheme.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isNegative ? AppTheme.danger.withOpacity(0.5) : AppTheme.success.withOpacity(0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Score:',
                  style: TextStyle(
                    color: isNegative ? AppTheme.danger : AppTheme.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$score',
                  style: TextStyle(
                    color: isNegative ? AppTheme.danger : AppTheme.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
