import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/task_repository_impl.dart';
import '../../../dashboard/presentation/screens/main_navigation_screen.dart';

class TodaysTasksScreen extends ConsumerStatefulWidget {
  const TodaysTasksScreen({super.key});

  @override
  ConsumerState<TodaysTasksScreen> createState() => _TodaysTasksScreenState();
}

class _TodaysTasksScreenState extends ConsumerState<TodaysTasksScreen> {
  List<dynamic> _tasks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final tasks = await ref.read(taskRepositoryProvider).getMyTasks();
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _markComplete(String taskId) async {
    try {
      await ref.read(taskRepositoryProvider).completeTask(taskId);
      if (!mounted) return;
      
      final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Task updated at $nowStr', style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _fetchTasks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: AppTheme.danger),
      );
    }
  }

  Color _getStatusColor(String status) {
    if (status.contains('Delayed')) return AppTheme.danger;
    if (status.contains('Early')) return Colors.teal;
    if (status.contains('time')) return Colors.green;
    return AppTheme.textSecondary;
  }
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low': return Colors.grey;
      case 'high': return Colors.orange;
      case 'urgent': return Colors.red;
      case 'normal':
      default:
        return Colors.blue;
    }
  }

  String _calculateDelayEarlyStatus(String? dueDateStr, String? endTimeStr) {
    if (dueDateStr == null) return "No target date";
    final dueDate = DateTime.parse(dueDateStr).toLocal();
    final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    final comparisonDate = endTimeStr != null ? DateTime.parse(endTimeStr).toLocal() : DateTime.now();
    final compDateOnly = DateTime(comparisonDate.year, comparisonDate.month, comparisonDate.day);
    
    final difference = compDateOnly.difference(dueDateOnly).inDays;
    
    if (difference > 0) {
      return "Delayed by $difference days";
    } else if (difference < 0) {
      return "Early by ${difference.abs()} days";
    } else {
      return "On time";
    }
  }
  


  @override
  Widget build(BuildContext context) {
    final pendingTasks = _tasks.where((t) => t['status'] != 'Completed').toList();
    final completedTasks = _tasks.where((t) => t['status'] == 'Completed').toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("My Delegations"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              ref.read(bottomNavIndexProvider.notifier).state = 0; // Go back to Home
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchTasks,
              tooltip: 'Refresh Delegations',
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(text: "Pending Delegations"),
              Tab(text: "Completed Delegations"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
                        const SizedBox(height: 16),
                        Text(_error!, style: const TextStyle(color: AppTheme.danger)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _fetchTasks, child: const Text('Retry'))
                      ],
                    ),
                  )
                : TabBarView(
                    children: [
                      _buildTaskList(pendingTasks, isPendingTab: true),
                      _buildTaskList(completedTasks, isPendingTab: false),
                    ],
                  ),
      ),
    );
  }

  Widget _buildTaskList(List<dynamic> tasks, {required bool isPendingTab}) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPendingTab ? Icons.task_outlined : Icons.check_circle_outline,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              isPendingTab ? 'No pending delegations!' : 'No completed delegations yet.',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: _fetchTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          final isCompleted = task['status'] == 'Completed';
          final priority = task['priority'] ?? 'Normal';
          
          final timingStatus = _calculateDelayEarlyStatus(task['dueDate'], task['endTime']);
          final timingColor = _getStatusColor(timingStatus);

          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            elevation: 2,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isCompleted ? AppTheme.success.withOpacity(0.5) : Colors.red.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        task['title'] ?? 'Delegation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Delegation Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppTheme.success.withOpacity(0.15)
                                : (task['status'] == 'Reopened' ? Colors.orange.withOpacity(0.15) : Colors.red.withOpacity(0.15)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isCompleted ? 'COMPLETED' : (task['status'] == 'Reopened' ? 'REOPENED' : 'PENDING'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isCompleted
                                  ? AppTheme.success
                                  : (task['status'] == 'Reopened' ? Colors.orange.shade700 : Colors.red.shade700),
                            ),
                          ),
                        ),
                        // Priority Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(priority).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            priority.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getPriorityColor(priority),
                            ),
                          ),
                        ),
                        // Timing Badge
                        if (task['dueDate'] != null)
                          Text(
                            timingStatus,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: timingColor),
                          ),
                      ],
                    ),
                  ],
                ),
                children: [
                  const Divider(color: AppTheme.borderLight),
                  const SizedBox(height: 12),
                  _buildTaskDetailRow(Icons.description, 'Description', task['description'] ?? 'N/A'),
                  _buildTaskDetailRow(Icons.person_pin_circle, 'Assigned By', task['createdBy']?['name'] ?? 'Unknown'),
                  _buildTaskDetailRow(
                    Icons.calendar_today, 
                    'Target Date', 
                    task['dueDate'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(task['dueDate'])) : 'No Date'
                  ),
                  if (isCompleted && task['endTime'] != null)
                    _buildTaskDetailRow(
                      Icons.check_circle, 
                      'Completed On', 
                      DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(task['endTime'])),
                      valueColor: AppTheme.success,
                    ),
                    
                  if (!isCompleted) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text(
                          'Mark as Complete',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: AppTheme.primaryWhite,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _markComplete(task['id'].toString()),
                      ),
                    )
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskDetailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.w600, color: valueColor ?? AppTheme.textSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
