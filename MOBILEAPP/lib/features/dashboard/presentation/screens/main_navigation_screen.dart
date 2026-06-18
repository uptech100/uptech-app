import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'worker_dashboard_screen.dart';
import '../../../tasks/presentation/screens/todays_tasks_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../worklog/presentation/screens/work_history_screen.dart';
import '../../../worklog/presentation/screens/daily_work_log_screen.dart';
import '../../../qc/presentation/screens/qc_daily_log_screen.dart';
import '../../../qc/presentation/screens/qc_history_screen.dart';
import '../../../../core/theme/app_theme.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class MainNavigationScreen extends ConsumerWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final departmentAsync = ref.watch(userDepartmentProvider);
    final dept = departmentAsync.value?.toUpperCase() ?? '';
    final isProduction = dept.contains('PRODUCTION') || dept.contains('PROD');
    final isQC = dept.contains('QC') || dept.contains('QUALITY');
    final showDailyLogs = isProduction || isQC;

    final List<Widget> screens = [
      const WorkerDashboardScreen(), // Home Tab
      const TodaysTasksScreen(),     // Tasks Tab
      if (showDailyLogs) isQC ? const QCDailyLogScreen() : const DailyWorkLogScreen(),    // Daily Log Tab
      if (showDailyLogs) isQC ? const QCHistoryScreen() : const WorkHistoryScreen(),     // History Tab
      const ProfileScreen(),         // Profile Tab
    ];

    final List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.task_alt_outlined),
        activeIcon: Icon(Icons.task_alt),
        label: 'Delegations',
      ),
      if (showDailyLogs)
        BottomNavigationBarItem(
          icon: const Icon(Icons.assignment_add),
          activeIcon: const Icon(Icons.assignment_turned_in),
          label: isQC ? 'QC Log' : 'Daily Log',
        ),
      if (showDailyLogs)
        const BottomNavigationBarItem(
          icon: Icon(Icons.history),
          activeIcon: Icon(Icons.history),
          label: 'History',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];

    final safeIndex = currentIndex >= screens.length ? 0 : currentIndex;

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: safeIndex,
          onTap: (index) {
            ref.read(bottomNavIndexProvider.notifier).state = index;
          },
          items: navItems,
          type: BottomNavigationBarType.fixed, // Ensure icons stay visible even with fewer tabs
        ),
      ),
    );
  }
}
