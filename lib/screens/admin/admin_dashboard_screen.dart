import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/widgets/developer_mode_panel.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _totalUsers = 0;
  int _totalTiles = 0;
  int _pendingApprovals = 0;
  int _expiringSubs = 0;
  bool _isLoadingStats = true;
  String? _statsError;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoadingStats = true;
      _statsError = null;
    });

    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isNotEqualTo: 'admin')
          .get();
      _totalUsers = usersSnapshot.docs.length;

      final now = DateTime.now();
      _expiringSubs = usersSnapshot.docs.where((doc) {
        final data = doc.data();
        final endDate = data['subscriptionEndDate'];
        if (endDate == null) return false;
        final expiry = (endDate as Timestamp).toDate();
        if (!expiry.isAfter(now)) return false;
        final days = expiry.difference(now).inDays;
        final role = data['role'] as String? ?? 'free';
        return (role == 'pro' || role == 'admin') && days <= 30 && days >= 0;
      }).length;

      final tilesSnapshot = await FirebaseFirestore.instance
          .collection('tiles')
          .where('isPublic', isEqualTo: true)
          .where('isApproved', isEqualTo: true)
          .get();
      _totalTiles = tilesSnapshot.docs.length;

      final proPersonalTilesSnapshot = await FirebaseFirestore.instance
          .collectionGroup('tiles')
          .where('isPublic', isEqualTo: false)
          .get();
      _pendingApprovals = proPersonalTilesSnapshot.docs.length;

      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
          _statsError = e.toString();
        });
      }
    }
  }

  int _gridColumns(double width) {
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;
    final padding =
        isLargeScreen ? const EdgeInsets.all(24.0) : const EdgeInsets.all(16.0);
    final columns = _gridColumns(screenWidth);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admin Dashboard'),
            if (user?.email != null)
              Text(
                user!.email!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.go('/profile'),
            tooltip: 'My Profile',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoadingStats ? null : _fetchStats,
            tooltip: 'Refresh stats',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
            },
            tooltip: 'Sign out',
          ),
        ],
      ),
      drawer: const MainDrawer(),
      body: RefreshIndicator(
        onRefresh: _fetchStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_statsError != null) ...[
                MaterialBanner(
                  content: Text('Could not load all stats: $_statsError'),
                  actions: [
                    TextButton(
                      onPressed: _fetchStats,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'Overview',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isLargeScreen ? 1.4 : 1.2,
                children: [
                  _buildStatCard(
                    title: 'Total Users',
                    value: _isLoadingStats ? null : _totalUsers.toString(),
                    icon: Icons.people,
                    onTap: () => context.go('/admin/users'),
                  ),
                  _buildStatCard(
                    title: 'Public Tiles',
                    value: _isLoadingStats ? null : _totalTiles.toString(),
                    icon: Icons.grid_view,
                    onTap: () => context.go('/admin/tiles'),
                  ),
                  _buildStatCard(
                    title: 'Pro Personal Tiles',
                    value:
                        _isLoadingStats ? null : _pendingApprovals.toString(),
                    icon: Icons.person_pin,
                    highlight: _pendingApprovals > 0,
                    onTap: () => context.go('/admin/tiles?tab=pro'),
                  ),
                  _buildStatCard(
                    title: 'Expiring Subs',
                    value: _isLoadingStats ? null : _expiringSubs.toString(),
                    icon: Icons.schedule,
                    highlight: _expiringSubs > 0,
                    onTap: () => context.go('/admin/users?filter=expiring'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _buildActionTile(
                icon: Icons.people,
                label: 'Manage Users',
                subtitle: 'Search, upgrade, and manage accounts',
                onTap: () => context.go('/admin/users'),
              ),
              _buildActionTile(
                icon: Icons.grid_view,
                label: 'Manage Tiles',
                subtitle: 'Edit default tile database',
                onTap: () => context.go('/admin/tiles'),
              ),
              _buildActionTile(
                icon: Icons.person_pin,
                label: 'Browse Pro Tiles',
                subtitle: _pendingApprovals > 0
                    ? '$_pendingApprovals pro personal tile(s) to review'
                    : 'No pro personal tiles yet',
                badge: _pendingApprovals > 0 ? _pendingApprovals : null,
                onTap: () => context.go('/admin/tiles?tab=pro'),
              ),
              _buildActionTile(
                icon: Icons.bar_chart,
                label: 'Analytics',
                subtitle: 'View platform statistics',
                onTap: () => context.go('/admin/stats'),
              ),
              if (user != null) ...[
                const SizedBox(height: 24),
                ExpansionTile(
                  initiallyExpanded: false,
                  leading:
                      const Icon(Icons.developer_mode, color: Colors.orange),
                  title: const Text(
                    'Developer Mode',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Local-only testing tools'),
                  children: [
                    DeveloperModePanel(user: user),
                  ],
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    final isLoading = value == null;
    final borderColor = highlight
        ? Colors.orange
        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3);

    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: isLoading
              ? _buildSkeleton()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: Theme.of(context).colorScheme.primary),
                    Text(
                      value,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                    ),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const Spacer(),
        Container(
          width: 48,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    int? badge,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: badge != null
            ? CircleAvatar(
                radius: 14,
                backgroundColor: Colors.orange,
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : const Icon(Icons.chevron_right),
        onTap: onTap,
        minVerticalPadding: 12,
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}