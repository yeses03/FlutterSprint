import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:workpass/models/user_model.dart';
import 'package:workpass/models/work_score_model.dart';
import 'package:workpass/screens/worker/add_work_entry_screen.dart';
import 'package:workpass/screens/worker/work_history_screen.dart';
import 'package:workpass/screens/worker/work_score_screen.dart';
import 'package:workpass/screens/worker/profile_screen.dart';
import 'package:workpass/services/supabase_service.dart';
import 'package:workpass/theme/app_theme.dart';
import 'package:workpass/widgets/workpass_assistant.dart';

class WorkerDashboardScreen extends StatefulWidget {
  final String userId;

  const WorkerDashboardScreen({super.key, required this.userId});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  int _currentIndex = 0;
  UserModel? _user;
  WorkScoreModel? _workScore;
  double _currentMonthIncome = 0;
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
      final user = await SupabaseService.getUser(widget.userId);
      final score = await SupabaseService.getWorkScore(widget.userId);
      final entries = await SupabaseService.getWorkEntries(widget.userId);

      final now = DateTime.now();
      final currentMonthEntries = entries.where((e) {
        return e.date.year == now.year && e.date.month == now.month;
      }).toList();

      final currentMonthTotal = currentMonthEntries
          .map((e) => e.amountEarned)
          .fold(0.0, (a, b) => a + b);

      setState(() {
        _user = user;
        _workScore = score;
        _currentMonthIncome = currentMonthTotal;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
        ),
      );
    }

    final screens = [
      _buildHomeScreen(),
      WorkHistoryScreen(userId: widget.userId),
      ProfileScreen(userId: widget.userId),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          WorkPassAssistant(userId: widget.userId),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.lightBlue, Colors.white],
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          _user?.name ?? 'User',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildIncomeCard(),
                const SizedBox(height: 20),
                _buildWorkScoreCard(),
                const SizedBox(height: 20),
                _buildRiskBadge(),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.add_circle_outline,
                        label: 'Add Work',
                        color: AppTheme.primaryBlue,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddWorkEntryScreen(userId: widget.userId),
                            ),
                          );
                          _loadData();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.assessment_outlined,
                        label: 'View Score',
                        color: AppTheme.deepBlue,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => WorkScoreScreen(userId: widget.userId),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  icon: Icons.history,
                  label: 'View History',
                  color: AppTheme.grey,
                  onTap: () {
                    setState(() {
                      _currentIndex = 1;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.gradientCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Month Income',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${NumberFormat('#,##,###').format(_currentMonthIncome)}',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkScoreCard() {
    final score = _workScore?.score ?? 0.0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassmorphismCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WorkScore',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              Text(
                score.toStringAsFixed(1),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: score / 100,
            backgroundColor: AppTheme.lightBlue,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskBadge() {
    final riskLevel = _workScore?.riskLevel ?? 'High Risk';
    final riskColor = _getRiskColor(riskLevel);
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
              const SizedBox(height: 4),
              Text(
                riskLevel,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: riskColor,
                    ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: riskColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: riskColor, width: 2),
            ),
            child: Icon(
              riskLevel == 'Low Risk'
                  ? Icons.check_circle
                  : riskLevel == 'Medium Risk'
                      ? Icons.warning
                      : Icons.error,
              color: riskColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

