import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/worker_mis_provider.dart';
import '../providers/admin_providers.dart';

class WorkerMisScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  
  const WorkerMisScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<WorkerMisScreen> createState() => _WorkerMisScreenState();
}

class _WorkerMisScreenState extends ConsumerState<WorkerMisScreen> {
  String _selectedFilter = 'Weekly';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  String? _selectedUserId;

  final List<String> _filters = ['Daily', 'Weekly', 'Quarterly', '6 Months', '1 Year'];

  void _updateDates(String filter) {
    setState(() {
      _selectedFilter = filter;
      final now = DateTime.now();
      _endDate = now;

      switch (filter) {
        case 'Daily':
          _startDate = now;
          break;
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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);
    final users = usersAsync.value ?? [];
    final workerUsers = users.where((u) => u['role']['name'] == 'Worker').toList();

    if (workerUsers.isNotEmpty && _selectedUserId == null) {
      // Don't set state during build, just use the first one if null
      // Actually we will leave it null to show "Select Worker" by default
    }

    final dateRange = '${_startDate.toIso8601String()}|${_endDate.toIso8601String()}|${_selectedUserId ?? ''}';
    final misDataAsync = _selectedUserId == null ? null : ref.watch(workerMisProvider(dateRange));

    final content = Column(
      children: [
        _buildFilterHeader(workerUsers),
        Expanded(
          child: misDataAsync == null 
            ? const Center(child: Text('Please select a worker to view their MIS.', style: TextStyle(color: AppTheme.textSecondary)))
            : misDataAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
            error: (err, stack) => Center(
              child: Text('Error: ${err.toString()}', style: const TextStyle(color: AppTheme.danger)),
            ),
            data: (data) => data == null ? const SizedBox() : _buildDashboard(data),
          ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Worker MIS Dashboard'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: content,
    );
  }

  Widget _buildFilterHeader(List<dynamic> workerUsers) {
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
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedUserId,
                  hint: const Text('Select Worker', style: TextStyle(color: AppTheme.textSecondary)),
                  dropdownColor: AppTheme.primaryWhite,
                  isExpanded: true,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                  underline: Container(height: 2, color: AppTheme.primaryColor),
                  icon: const Icon(Icons.person, color: AppTheme.primaryColor),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedUserId = newValue;
                      });
                    }
                  },
                  items: workerUsers.map<DropdownMenuItem<String>>((user) {
                    return DropdownMenuItem<String>(
                      value: user['id'],
                      child: Text(user['name'] ?? 'Unknown'),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _selectedFilter,
                dropdownColor: AppTheme.primaryWhite,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                underline: Container(height: 2, color: AppTheme.primaryColor),
                icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _updateDates(newValue);
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

  Widget _buildDashboard(Map<String, dynamic> data) {
    final double workerScore = (data['workerScore'] as num).toDouble();
    final bool isScoreNegative = workerScore < 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Score Hero Card
          Card(
            color: isScoreNegative ? AppTheme.danger : AppTheme.success,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Overall Performance Score',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    workerScore.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isScoreNegative ? 'Below Expectations' : 'Exceeding Expectations!',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Hours Tracking
          Card(
            color: AppTheme.primaryWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Time Tracking',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCol(
                          'Expected Hours',
                          '${data['expectedHours']} hrs',
                          Icons.schedule,
                          Colors.grey,
                        ),
                      ),
                      Container(width: 1, height: 60, color: Colors.grey.withOpacity(0.2)),
                      Expanded(
                        child: _buildMetricCol(
                          'Work Done',
                          '${data['totalWorkHours']} hrs',
                          Icons.work,
                          AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: data['expectedHours'] == 0 ? 0 : data['totalWorkHours'] / data['expectedHours'],
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    color: isScoreNegative ? AppTheme.danger : AppTheme.success,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Additional Metrics Grid
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildMetricCard('Task Score', '${data['taskScore']}', Icons.task_alt, Colors.orange),
              _buildMetricCard('Tasks Completed', '${data['completedTasks']} / ${data['totalTasks']}', Icons.checklist, Colors.blue),
              _buildMetricCard('Quantity Done', '${data['totalQuantity']} Pairs', Icons.inventory_2, Colors.purple),
              _buildMetricCard('Processes', '${(data['processBreakdown'] as List).length}', Icons.precision_manufacturing, Colors.teal),
            ],
          ),
          const SizedBox(height: 24),

          // Process Breakdown List
          const Text(
            'Time Spent per Process',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          ...(data['processBreakdown'] as List).map((p) {
            return Card(
              color: AppTheme.primaryWhite,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.bgLight,
                  child: Icon(Icons.build, color: AppTheme.primaryColor, size: 20),
                ),
                title: Text(p['process'], style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text('${(p['hours'] as num).toStringAsFixed(2)} hrs', style: const TextStyle(fontSize: 16)),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: AppTheme.primaryWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
