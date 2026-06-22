import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/admin_providers.dart';
import 'role_management_screen.dart';
import 'checklist_management_screen.dart';
import 'aop_analysis_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const TabBar(
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'AOP Analysis', icon: Icon(Icons.analytics)),
          ],
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(context, ref),
            const AopAnalysisScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);

    return statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
              const SizedBox(height: 16),
              Text(err.toString(), style: const TextStyle(color: AppTheme.danger)),
            ],
          ),
        ),
        data: (stats) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overview',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 24),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard(
                      context,
                      title: 'Total Users',
                      value: stats['totalUsers'].toString(),
                      icon: Icons.people_outline,
                      color: Colors.blue,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Total Departments',
                      value: stats['totalDepartments'].toString(),
                      icon: Icons.domain,
                      color: Colors.purple,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Active Users',
                      value: stats['activeUsers'].toString(),
                      icon: Icons.check_circle_outline,
                      color: AppTheme.success,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Manage Roles',
                      value: 'Setup',
                      icon: Icons.security,
                      color: Colors.orange,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const RoleManagementScreen()),
                        );
                      },
                    ),
                    _buildStatCard(
                      context,
                      title: 'Manage Checklists',
                      value: 'Tasks',
                      icon: Icons.checklist,
                      color: Colors.teal,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const ChecklistManagementScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
  }

  Widget _buildStatCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
