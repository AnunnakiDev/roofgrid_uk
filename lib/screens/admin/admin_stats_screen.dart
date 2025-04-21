import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:roofgrid_uk/widgets/header_widget.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  int _totalUsers = 0;
  int _totalTiles = 0;
  int _totalCalculations = 0;
  int _onlineUsers = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoadingStats = true;
    });
    try {
      // Total Users
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      _totalUsers = usersSnapshot.docs.length;

      // Total Tiles (public and approved)
      final tilesSnapshot = await FirebaseFirestore.instance
          .collection('tiles')
          .where('isPublic', isEqualTo: true)
          .where('isApproved', isEqualTo: true)
          .get();
      _totalTiles = tilesSnapshot.docs.length;

      // Total Calculations (assumed 'calculations' collection)
      try {
        final calculationsSnapshot =
            await FirebaseFirestore.instance.collection('calculations').get();
        _totalCalculations = calculationsSnapshot.docs.length;
      } catch (e) {
        _totalCalculations = -1; // Indicate collection doesn't exist
      }

      // Current Online Users (assumed 'sessions' collection with TTL)
      try {
        final onlineSnapshot = await FirebaseFirestore.instance
            .collection('sessions')
            .where('lastActive',
                isGreaterThan: Timestamp.fromDate(
                    DateTime.now().subtract(const Duration(minutes: 5))))
            .get();
        _onlineUsers = onlineSnapshot.docs.length;
      } catch (e) {
        _onlineUsers = -1; // Indicate collection doesn't exist
      }

      setState(() {
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading stats: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;
    final padding =
        isLargeScreen ? const EdgeInsets.all(24.0) : const EdgeInsets.all(16.0);

    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    // Data for the bar chart
    final List<ChartData> chartData = [
      ChartData('Users', _totalUsers),
      ChartData('Tiles', _totalTiles),
      if (_totalCalculations != -1)
        ChartData('Calculations', _totalCalculations),
      if (_onlineUsers != -1) ChartData('Online', _onlineUsers),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detailed Statistics'),
      ),
      body: SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HeaderWidget(title: 'Admin Dashboard: Statistics'),
            const SizedBox(height: 16),
            // Responsive layout for summary cards
            isLargeScreen
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                            'Total Users', _totalUsers.toString()),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                            'Online Users',
                            _onlineUsers == -1
                                ? 'Not Available'
                                : _onlineUsers.toString()),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildSummaryCard('Total Users', _totalUsers.toString()),
                      const SizedBox(height: 12),
                      _buildSummaryCard(
                          'Online Users',
                          _onlineUsers == -1
                              ? 'Not Available'
                              : _onlineUsers.toString()),
                    ],
                  ),
            const SizedBox(height: 16),
            isLargeScreen
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                            'Total Tiles', _totalTiles.toString()),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                            'Total Calculations',
                            _totalCalculations == -1
                                ? 'Not Available'
                                : _totalCalculations.toString()),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildSummaryCard('Total Tiles', _totalTiles.toString()),
                      const SizedBox(height: 12),
                      _buildSummaryCard(
                          'Total Calculations',
                          _totalCalculations == -1
                              ? 'Not Available'
                              : _totalCalculations.toString()),
                    ],
                  ),
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
                      height: 200, // Fixed height for chart
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
          ],
        ),
      ),
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
