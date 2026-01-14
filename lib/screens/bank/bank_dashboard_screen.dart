import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workpass/models/work_score_model.dart';
import 'package:workpass/models/user_model.dart';
import 'package:workpass/models/work_entry_model.dart';
import 'package:workpass/theme/app_theme.dart';
import 'package:workpass/screens/bank/worker_profile_screen.dart';

class BankDashboardScreen extends StatefulWidget {
  const BankDashboardScreen({super.key});

  @override
  State<BankDashboardScreen> createState() => _BankDashboardScreenState();
}

class _BankDashboardScreenState extends State<BankDashboardScreen> {
  List<WorkScoreModel> _scores = [];
  Map<String, UserModel> _users = {};
  bool _isLoading = true;
  String _searchQuery = '';

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

      // Fetch all users
      final usersResponse = await client.from('users').select('*');
      final users = <String, UserModel>{};
      for (var userData in usersResponse) {
        try {
          final user = UserModel.fromJson(userData);
          users[user.id] = user;
        } catch (e) {
          // Skip invalid user data
          continue;
        }
      }

      // Fetch all work scores
      final scoresResponse = await client.from('work_scores').select('*');
      final scores = <WorkScoreModel>[];
      for (var scoreData in scoresResponse) {
        try {
          final score = WorkScoreModel.fromJson(scoreData);
          // Only include scores for users that exist
          if (users.containsKey(score.userId)) {
            scores.add(score);
          }
        } catch (e) {
          // Skip invalid score data
          continue;
        }
      }

      setState(() {
        _scores = scores;
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      // If Supabase fails, show empty state
      setState(() {
        _scores = [];
        _users = {};
        _isLoading = false;
      });
    }
  }

  List<WorkScoreModel> get _filteredScores {
    if (_searchQuery.isEmpty) return _scores;
    
    return _scores.where((score) {
      final user = _users[score.userId];
      if (user == null) return false;
      return user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             user.phone.contains(_searchQuery);
    }).toList();
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'Low Risk':
        return AppTheme.accentGreen;
      case 'Medium Risk':
        return AppTheme.warningAmber;
      default:
        return AppTheme.errorRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Dashboard'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: AppTheme.subtleGradient(),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow(),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name or phone...',
                      prefixIcon: Icon(Icons.search, color: AppTheme.primaryBlue),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                      )
                    : _filteredScores.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: AppTheme.textTertiary),
                                const SizedBox(height: 16),
                                Text(
                                  'No workers found',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            color: AppTheme.primaryBlue,
                            child: GridView.builder(
                              padding: const EdgeInsets.all(24),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.85,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _filteredScores.length,
                              itemBuilder: (context, index) {
                                final score = _filteredScores[index];
                                final user = _users[score.userId];
                                if (user == null) return const SizedBox.shrink();
                                return _buildPremiumWorkerCard(score, user);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumWorkerCard(WorkScoreModel score, UserModel user) {
    final riskColor = _getRiskColor(score.riskLevel);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  WorkerProfileScreen(
                    userId: user.id,
                    userName: user.name,
                  ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.7)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: riskColor, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          score.riskLevel == 'Low Risk'
                              ? Icons.check_circle
                              : score.riskLevel == 'Medium Risk'
                                  ? Icons.warning
                                  : Icons.error,
                          size: 14,
                          color: riskColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          score.riskLevel.split(' ')[0],
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: riskColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                user.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                user.city,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                user.workType,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Divider(color: AppTheme.mediumGray.withOpacity(0.3)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Score',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textTertiary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        score.score.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Income',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textTertiary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${NumberFormat('#,##,###').format(score.avgMonthlyIncome)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

