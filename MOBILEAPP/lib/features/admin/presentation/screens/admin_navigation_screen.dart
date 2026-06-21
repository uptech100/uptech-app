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

  final List<String> _titles = [
    'Admin Dashboard',
    'Departments',
    'Users',
    'Processes',
    'Products',
    'Peer Ratings',
    'MIS Reports',
    'Worker MIS',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.domain_outlined),
              activeIcon: Icon(Icons.domain),
              label: 'Departments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.precision_manufacturing_outlined),
              activeIcon: Icon(Icons.precision_manufacturing),
              label: 'Processes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Products',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.star_half_outlined),
              activeIcon: Icon(Icons.star),
              label: 'Ratings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Gen. MIS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insights_outlined),
              activeIcon: Icon(Icons.insights),
              label: 'Worker MIS',
            ),
          ],
        ),
      ),
    );
  }
}
