import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:workpass/models/work_score_model.dart';
import 'package:workpass/models/work_entry_model.dart';
import 'package:workpass/services/supabase_service.dart';
import 'package:workpass/services/mock_data_service.dart';
import 'package:workpass/theme/app_theme.dart';
import 'package:workpass/screens/worker/transparency_screen.dart';

class WorkScoreScreen extends StatefulWidget {
  final String userId;

  const WorkScoreScreen({super.key, required this.userId});

  @override
  State<WorkScoreScreen> createState() => _WorkScoreScreenState();
}

class _WorkScoreScreenState extends State<WorkScoreScreen> {
  WorkScoreModel? _workScore;
  List<WorkEntryModel> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      WorkScoreModel? score;
      List<WorkEntryModel> entries = [];

      try {
        score = await SupabaseService.getWorkScore(widget.userId);
        entries = await SupabaseService.getWorkEntries(widget.userId);
      } catch (e) {
        // Supabase not available, use mock data
      }

      // Use mock data if Supabase data is not available
      if (score == null || entries.isEmpty || MockDataService.shouldUseMockData(widget.userId)) {
        entries = MockDataService.getMockWorkEntries();
        score = MockDataService.calculateMockWorkScore();
      }

      setState(() {
        _workScore = score;
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      // Fallback to mock data
      setState(() {
        _entries = MockDataService.getMockWorkEntries();
        _workScore = MockDataService.calculateMockWorkScore();
        _isLoading = false;
      });
    }
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'Low Risk':
        return AppTheme.successGreen;
      case 'Medium Risk':
        return AppTheme.warningOrange;
      default:
        return AppTheme.errorRed;
    }
  }

  List<FlSpot> _getMonthlyIncomeData() {
    final monthMap = <String, double>{};
    for (var entry in _entries) {
      final monthKey = '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}';
      monthMap[monthKey] = (monthMap[monthKey] ?? 0) + entry.amountEarned;
    }

    final sortedMonths = monthMap.keys.toList()..sort();
    return sortedMonths.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), monthMap[e.value]!);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
        ),
      );
    }

    final score = _workScore ?? WorkScoreModel(
      userId: widget.userId,
      avgMonthlyIncome: 0,
      monthsActive: 0,
      verifiedRatio: 0,
      score: 0,
      riskLevel: 'High Risk',
      updatedAt: DateTime.now(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('WorkScore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TransparencyScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground(),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildScoreCard(score),
                  const SizedBox(height: 24),
                  _buildRiskBadge(score),
                  const SizedBox(height: 24),
                  _buildMetricsCard(score),
                  const SizedBox(height: 24),
                  _buildIncomeChart(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(WorkScoreModel score) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.gradientCard(),
      child: Column(
        children: [
          Text(
            'Your WorkScore',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
          const SizedBox(height: 16),
          Text(
            score.score.toStringAsFixed(1),
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: score.score / 100,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskBadge(WorkScoreModel score) {
    final riskColor = _getRiskColor(score.riskLevel);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassmorphismCard(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Risk Level',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                score.riskLevel,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: riskColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: riskColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: riskColor, width: 3),
            ),
            child: Icon(
              score.riskLevel == 'Low Risk'
                  ? Icons.check_circle
                  : score.riskLevel == 'Medium Risk'
                      ? Icons.warning
                      : Icons.error,
              color: riskColor,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCard(WorkScoreModel score) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassmorphismCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score Breakdown',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 24),
          _buildMetricRow(
            'Avg Monthly Income',
            '₹${NumberFormat('#,##,###').format(score.avgMonthlyIncome)}',
            Icons.currency_rupee,
          ),
          const Divider(),
          _buildMetricRow(
            'Months Active',
            '${score.monthsActive} months',
            Icons.calendar_today,
          ),
          const Divider(),
          _buildMetricRow(
            'Verification Ratio',
            '${(score.verifiedRatio * 100).toStringAsFixed(1)}%',
            Icons.verified,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeChart() {
    final spots = _getMonthlyIncomeData();
    if (spots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.glassmorphismCard(),
        child: Center(
          child: Text(
            'No income data available',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassmorphismCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Income Trend',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.primaryBlue,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

