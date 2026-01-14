import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workpass/models/user_model.dart';
import 'package:workpass/models/work_score_model.dart';
import 'package:workpass/models/work_entry_model.dart';
import 'package:workpass/theme/app_theme.dart';
import 'package:workpass/screens/bank/risk_view_screen.dart';

class WorkerProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const WorkerProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  UserModel? _user;
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
      final client = Supabase.instance.client;

      // Fetch user data
      final userResponse = await client
          .from('users')
          .select('*')
          .eq('id', widget.userId)
          .maybeSingle();

      UserModel? user;
      if (userResponse != null) {
        user = UserModel.fromJson(userResponse);
      }

      // Fetch work score
      final scoreResponse = await client
          .from('work_scores')
          .select('*')
          .eq('user_id', widget.userId)
          .maybeSingle();

      WorkScoreModel? score;
      if (scoreResponse != null) {
        score = WorkScoreModel.fromJson(scoreResponse);
      }

      // Fetch work entries
      final entriesResponse = await client
          .from('work_entries')
          .select('*')
          .eq('user_id', widget.userId)
          .order('date', ascending: false);

      final entries = <WorkEntryModel>[];
      for (var entryData in entriesResponse) {
        try {
          entries.add(WorkEntryModel.fromJson(entryData));
        } catch (e) {
          // Skip invalid entries
          continue;
        }
      }

      setState(() {
        _user = user;
        _workScore = score;
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
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
        appBar: AppBar(title: Text(widget.userName)),
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
        title: Text(widget.userName),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => RiskViewScreen(workScore: score),
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
                  _buildProfileCard(),
                  const SizedBox(height: 24),
                  _buildWorkScoreCard(score),
                  const SizedBox(height: 24),
                  _buildRiskBadge(score),
                  const SizedBox(height: 24),
                  _buildIncomeAnalytics(),
                  const SizedBox(height: 24),
                  _buildVerificationRatio(score),
                  const SizedBox(height: 24),
                  _buildWorkHistory(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassmorphismCard(),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _user?.name ?? 'Unknown',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.location_city, _user?.city ?? ''),
          const SizedBox(height: 4),
          _buildInfoRow(Icons.work, _user?.workType ?? ''),
          const SizedBox(height: 4),
          _buildInfoRow(Icons.phone, _user?.phone ?? ''),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: AppTheme.darkGray),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildWorkScoreCard(WorkScoreModel score) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.gradientCard(),
      child: Column(
        children: [
          Text(
            'WorkScore',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
          const SizedBox(height: 16),
          Text(
            score.score.toStringAsFixed(1),
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskBadge(WorkScoreModel score) {
    final riskColor = _getRiskColor(score.riskLevel);
    return Container(
      padding: const EdgeInsets.all(20),
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

  Widget _buildIncomeAnalytics() {
    final spots = _getMonthlyIncomeData();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassmorphismCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Income Analytics',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 24),
          if (spots.isEmpty)
            Center(
              child: Text(
                'No income data available',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
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

  Widget _buildVerificationRatio(WorkScoreModel score) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassmorphismCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verification Ratio',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 16),
          Text(
            '${(score.verifiedRatio * 100).toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppTheme.primaryBlue,
                ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: score.verifiedRatio,
            backgroundColor: AppTheme.lightBlue,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkHistory() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassmorphismCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Work History',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 16),
          if (_entries.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'No work entries yet',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          else
            ..._entries.take(5).map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.platform,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${entry.amountEarned.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                )),
          if (_entries.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '... and ${_entries.length - 5} more entries',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.darkGray,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

