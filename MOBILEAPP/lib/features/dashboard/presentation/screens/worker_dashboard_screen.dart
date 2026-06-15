import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../admin/presentation/screens/admin_navigation_screen.dart';
import '../../../worklog/presentation/screens/daily_work_log_screen.dart';
import '../../../tasks/presentation/screens/assign_task_screen.dart';
import '../../../tasks/presentation/screens/assigned_tasks_list_screen.dart';
import '../../../checklists/presentation/screens/worker_checklist_screen.dart';
import '../../../qc/presentation/screens/qc_daily_log_screen.dart';
import 'main_navigation_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

final userDepartmentProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final userStr = prefs.getString('uptech_user');
  if (userStr != null) {
    try {
      final userData = jsonDecode(userStr);
      return userData['department']?.toString().toUpperCase() ?? '';
    } catch (e) {
      return '';
    }
  }
  return '';
});

class WorkerDashboardScreen extends ConsumerWidget {
  const WorkerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departmentAsync = ref.watch(userDepartmentProvider);
    final dept = departmentAsync.value?.toUpperCase() ?? '';
    final isQC = dept.contains('QC') || dept.contains('QUALITY');
    final isChecklistEligible = dept.contains('ACCOUNT') || dept.contains('HR') || dept.contains('PC') || dept.contains('PROCESS');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dashboard is up to date!'), duration: Duration(seconds: 1)),
              );
            },
            tooltip: 'Refresh Dashboard',
          ),
        ],
      ),
      body: Column(
        children: [
          // Professional Hero Button
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0),
            child: InkWell(
              onTap: () {
                if (isQC) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const QCDailyLogScreen()),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const DailyWorkLogScreen()),
                  );
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_task, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isQC ? 'Add QC Daily Log' : 'Add Daily Task',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isQC ? 'Update your quality control log' : 'Update your today\'s work log',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ),
          ),
          // My Checklists Hero Button
          if (isChecklistEligible)
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 12.0),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const WorkerChecklistScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0083B0).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.checklist_rtl, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Checklists',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Complete your recurring tasks',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _buildDashboardCard(
                    context,
                    icon: Icons.task_alt,
                    label: "Today's Tasks",
                    onTap: () {
                      ref.read(bottomNavIndexProvider.notifier).state = 1;
                    },
                  ),
                  _buildDashboardCard(
                    context, 
                    icon: Icons.pending_actions, 
                    label: "Pending Delegations",
                    onTap: () {
                      ref.read(bottomNavIndexProvider.notifier).state = 1;
                    },
                  ),
                  _buildDashboardCard(
                    context, 
                    icon: Icons.check_circle_outline, 
                    label: "Completed Delegations",
                    onTap: () {
                      ref.read(bottomNavIndexProvider.notifier).state = 1;
                    },
                  ),
                  _buildDashboardCard(
                    context, 
                    icon: Icons.assignment_add, 
                    label: "Delegations",
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const AssignedTasksListScreen()),
                      );
                    },
                  ),
                  _buildDashboardCard(context, icon: Icons.notifications_active, label: "Notifications"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, {required IconData icon, required String label, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
