// lib/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';
import 'package:roofgrid_uk/widgets/bottom_nav_bar.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;
  final List<String> _pageTitles = ['Dashboard', 'Users', 'Tiles', 'Settings'];

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              // Router will handle navigation
            },
            tooltip: 'Sign out',
          ),
        ],
      ),
      drawer: const MainDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardPage(),
          _buildUsersPage(),
          _buildTilesPage(),
          _buildSettingsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavItem(
            label: 'Dashboard',
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            tooltip: 'Admin Dashboard',
          ),
          BottomNavItem(
            label: 'Users',
            icon: Icons.people_outlined,
            activeIcon: Icons.people,
            tooltip: 'Manage Users',
          ),
          BottomNavItem(
            label: 'Tiles',
            icon: Icons.grid_4x4_outlined,
            activeIcon: Icons.grid_4x4,
            tooltip: 'Manage Tiles',
          ),
          BottomNavItem(
            label: 'Settings',
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            tooltip: 'Admin Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.dashboard_customize, size: 80, color: Colors.blue),
          const SizedBox(height: 24),
          const Text(
            'Admin Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Welcome to the RoofGrid UK admin dashboard',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 48),
          _buildSummaryCard('Total Users', '0'),
          const SizedBox(height: 16),
          _buildSummaryCard('Total Tiles', '0'),
          const SizedBox(height: 16),
          _buildSummaryCard('Calculations', '0'),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersPage() {
    return const Center(
      child: Text(
        'User Management Coming Soon',
        style: TextStyle(fontSize: 20),
      ),
    );
  }

  Widget _buildTilesPage() {
    return const Center(
      child: Text(
        'Tile Management Coming Soon',
        style: TextStyle(fontSize: 20),
      ),
    );
  }

  Widget _buildSettingsPage() {
    return const Center(
      child: Text(
        'Settings Coming Soon',
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}
