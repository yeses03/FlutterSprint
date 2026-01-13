import 'package:flutter/material.dart';
import 'package:workpass/models/work_score_model.dart';
import 'package:workpass/models/user_model.dart';
import 'package:workpass/services/supabase_service.dart';
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
      final scores = await SupabaseService.getAllWorkScores();
      final userIds = scores.map((s) => s.userId).toSet();
      
      final users = <String, UserModel>{};
      for (var userId in userIds) {
        final user = await SupabaseService.getUser(userId);
        if (user != null) {
          users[userId] = user;
        }
      }

      setState(() {
        _scores = scores;
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
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
        return AppTheme.successGreen;
      case 'Medium Risk':
        return AppTheme.warningOrange;
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
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.lightBlue, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name or phone...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
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
                                Icon(Icons.people_outline, size: 64, color: AppTheme.grey),
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
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredScores.length,
                              itemBuilder: (context, index) {
                                final score = _filteredScores[index];
                                final user = _users[score.userId];
                                if (user == null) return const SizedBox.shrink();
                                return _buildWorkerCard(score, user);
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

  Widget _buildWorkerCard(WorkScoreModel score, UserModel user) {
    final riskColor = _getRiskColor(score.riskLevel);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => WorkerProfileScreen(
                userId: user.id,
                userName: user.name,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: AppTheme.primaryBlue,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.workType,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: riskColor, width: 1),
                    ),
                    child: Text(
                      score.riskLevel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: riskColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Score: ${score.score.toStringAsFixed(1)}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
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

