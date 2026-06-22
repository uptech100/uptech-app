import 'package:flutter/material.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/department_management_screen.dart';
import '../screens/user_management_screen.dart';
import '../screens/process_management_screen.dart';
import '../screens/product_management_screen.dart';
import '../../../ratings/presentation/screens/admin_ratings_screen.dart';
import '../screens/mis_reports_screen.dart';
import '../screens/worker_mis_screen.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/l10n/app_localizations.dart';

class AdminNavigationScreen extends StatefulWidget {
  const AdminNavigationScreen({super.key});

  @override
  State<AdminNavigationScreen> createState() => _AdminNavigationScreenState();
}

class _AdminNavigationScreenState extends State<AdminNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const DepartmentManagementScreen(),
    const UserManagementScreen(),
    const ProcessManagementScreen(),
    const ProductManagementScreen(),
    const AdminRatingsScreen(),
    const MisReportsScreen(),
    const WorkerMisScreen(),
  ];

  List<String> _getTitles(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.adminDashboard,
      l10n.departments,
      l10n.users,
      l10n.processes,
      l10n.products,
      l10n.peerRatings,
      l10n.misReports,
      l10n.workerMis,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titles = _getTitles(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        leading: const BackButton(color: Colors.white),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_outlined),
              activeIcon: const Icon(Icons.dashboard),
              label: l10n.dashboard,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.domain_outlined),
              activeIcon: const Icon(Icons.domain),
              label: l10n.departments,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.people_outline),
              activeIcon: const Icon(Icons.people),
              label: l10n.users,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.precision_manufacturing_outlined),
              activeIcon: const Icon(Icons.precision_manufacturing),
              label: l10n.processes,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.inventory_2_outlined),
              activeIcon: const Icon(Icons.inventory_2),
              label: l10n.products,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.star_half_outlined),
              activeIcon: const Icon(Icons.star),
              label: l10n.ratings,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.analytics_outlined),
              activeIcon: const Icon(Icons.analytics),
              label: l10n.misReports,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.insights_outlined),
              activeIcon: const Icon(Icons.insights),
              label: l10n.workerMis,
            ),
          ],
        ),
      ),
    );
  }
}
