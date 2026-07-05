import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/navigation/home_back_button.dart';
import 'package:roofgrid_uk/utils/admin_analytics_utils.dart';
import 'package:roofgrid_uk/widgets/header_widget.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  int _totalUsers = 0;
  int _totalTiles = 0;
  int _savedResults = 0;
  int _legacyCalculations = 0;
  int _onlineUsers = 0;
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
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final users = usersSnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
      _totalUsers = countNonAdminUsers(users);

      final tilesSnapshot = await FirebaseFirestore.instance
          .collection('tiles')
          .where('isPublic', isEqualTo: true)
          .where('isApproved', isEqualTo: true)
          .get();
      _totalTiles = tilesSnapshot.docs.length;

      final savedResultsSnapshot = await FirebaseFirestore.instance
          .collectionGroup('saved_results')
          .get();
      _savedResults = savedResultsSnapshot.docs.length;

      try {
        final calculationsSnapshot =
            await FirebaseFirestore.instance.collection('calculations').get();
        _legacyCalculations = calculationsSnapshot.docs.length;
      } catch (_) {
        _legacyCalculations = 0;
      }

      final onlineSnapshot = await FirebaseFirestore.instance
          .collection('sessions')
          .where(
            'lastActive',
            isGreaterThan: Timestamp.fromDate(
              DateTime.now().subtract(const Duration(minutes: 5)),
            ),
          )
          .get();
      _onlineUsers = onlineSnapshot.docs.length;

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

  Future<void> _openFirebaseAnalyticsConsole() async {
    final uri = Uri.parse(firebaseAnalyticsConsoleUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Firebase Analytics console'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;
    final padding =
        isLargeScreen ? const EdgeInsets.all(24.0) : const EdgeInsets.all(16.0);

    final chartData = <ChartData>[
      ChartData('Users', _totalUsers),
      ChartData('Tiles', _totalTiles),
      ChartData('Saved Jobs', _savedResults),
      ChartData('Online', _onlineUsers),
      if (_legacyCalculations > 0)
        ChartData('Legacy Calcs', _legacyCalculations),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detailed Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoadingStats ? null : _fetchStats,
            tooltip: 'Refresh stats',
          ),
          const HomeBackButton(),
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
              const HeaderWidget(title: 'Admin Dashboard: Statistics'),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.analytics_outlined,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  title: const Text(
                    'Firebase Analytics Console',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'View event streams, retention, and acquisition in Firebase',
                  ),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: _openFirebaseAnalyticsConsole,
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoadingStats)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                _buildSummaryGrid(isLargeScreen),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        const Text(
                          'Usage Overview',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 220,
                          child: SfCartesianChart(
                            primaryXAxis: const CategoryAxis(),
                            series: <CartesianSeries<ChartData, String>>[
                              ColumnSeries<ChartData, String>(
                                dataSource: chartData,
                                xValueMapper: (ChartData data, _) => data.label,
                                yValueMapper: (ChartData data, _) => data.value,
                                color: Theme.of(context).colorScheme.primary,
                                dataLabelSettings: const DataLabelSettings(
                                  isVisible: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_legacyCalculations > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Legacy calculations collection: $_legacyCalculations '
                    '(historical; saved jobs use saved_results)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(bool isLargeScreen) {
    final cards = [
      _buildSummaryCard('Total Users', _totalUsers.toString()),
      _buildSummaryCard('Online Users (5 min)', _onlineUsers.toString()),
      _buildSummaryCard('Public Tiles', _totalTiles.toString()),
      _buildSummaryCard('Saved Jobs', _savedResults.toString()),
    ];

    if (isLargeScreen) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 12),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          cards[i],
        ],
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartData {
  ChartData(this.label, this.value);
  final String label;
  final int value;
}