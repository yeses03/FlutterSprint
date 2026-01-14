import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:workpass/models/user_model.dart';
import 'package:workpass/models/work_score_model.dart';
import 'package:workpass/models/work_entry_model.dart';
import 'package:workpass/screens/worker/add_work_entry_screen.dart';
import 'package:workpass/screens/worker/work_history_screen.dart';
import 'package:workpass/screens/worker/work_score_screen.dart';
import 'package:workpass/screens/worker/profile_screen.dart';
import 'package:workpass/screens/worker/trust_score_breakdown_screen.dart';
import 'package:workpass/services/supabase_service.dart';
import 'package:workpass/services/mock_data_service.dart';
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
  List<WorkEntryModel> _workEntries = [];

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
      // Try to load from Supabase first
      UserModel? user;
      WorkScoreModel? score;
      List<WorkEntryModel> entries = [];

      try {
        user = await SupabaseService.getUser(widget.userId);
        score = await SupabaseService.getWorkScore(widget.userId);
        entries = await SupabaseService.getWorkEntries(widget.userId);
      } catch (e) {
        // Supabase not available, use mock data
      }

      // Use mock data if Supabase data is not available
      if (user == null || MockDataService.shouldUseMockData(widget.userId)) {
        user = MockDataService.getMockUser();
        entries = MockDataService.getMockWorkEntries();
        score = MockDataService.calculateMockWorkScore();
      }

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
        _workEntries = entries;
        _isLoading = false;
      });
    } catch (e) {
      // Fallback to mock data on any error
      final user = MockDataService.getMockUser();
      final entries = MockDataService.getMockWorkEntries();
      final score = MockDataService.calculateMockWorkScore();

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
        _workEntries = entries;
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
      _buildAddWorkScreen(),
      WorkHistoryScreen(
        userId: widget.userId,
        initialEntries: _workEntries.isNotEmpty ? _workEntries : null,
      ),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: AppTheme.premiumShadow(),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          height: 70,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: AppTheme.darkGray),
              selectedIcon: Icon(Icons.dashboard, color: AppTheme.accentBlue),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_circle_outline, color: AppTheme.darkGray),
              selectedIcon: Icon(Icons.add_circle, color: AppTheme.accentBlue),
              label: 'Add',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined, color: AppTheme.darkGray),
              selectedIcon: Icon(Icons.history, color: AppTheme.accentBlue),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, color: AppTheme.darkGray),
              selectedIcon: Icon(Icons.person, color: AppTheme.accentBlue),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeScreen() {
    return Container(
      decoration: AppTheme.gradientBackground(),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.darkGray,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _user?.name ?? 'User',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (_workScore != null) {
                              Navigator.of(context).push(
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                      TrustScoreBreakdownScreen(workScore: _workScore!),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return FadeTransition(opacity: animation, child: child);
                                  },
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: AppTheme.premiumShadow(),
                            ),
                            child: Icon(
                              Icons.notifications_outlined,
                              color: AppTheme.accentBlue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: _buildPremiumHeroCard(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Income',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _buildMonthlyIncomeCards(),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: _buildQuickActions(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: _buildUpiPlaceholder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeroCard() {
    final score = _workScore?.score ?? 0.0;
    final riskLevel = _workScore?.riskLevel ?? 'High Risk';
    final riskColor = _getRiskColor(riskLevel);
    
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: AppTheme.glassmorphismCard(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This Month',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.darkGray,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${NumberFormat('#,##,###').format(_currentMonthIncome)}',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.deepBlue,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: riskColor, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(riskLevel == 'Low Risk' ? Icons.check_circle : 
                         riskLevel == 'Medium Risk' ? Icons.warning : Icons.error,
                         size: 16, color: riskColor),
                    const SizedBox(width: 6),
                    Text(
                      riskLevel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: riskColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: AppTheme.mediumGray.withOpacity(0.3)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WorkScore',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.darkGray,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      score.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentBlue,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: AppTheme.mediumGray,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyIncomeCards() {
    final now = DateTime.now();
    final months = <Map<String, dynamic>>[];
    
    for (int i = 0; i < 4; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthEntries = _workEntries.where((e) {
        return e.date.year == month.year && e.date.month == month.month;
      }).toList();
      final total = monthEntries.map((e) => e.amountEarned).fold(0.0, (a, b) => a + b);
      months.add({
        'month': month,
        'total': total,
      });
    }
    
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: months.length,
        itemBuilder: (context, index) {
          final monthData = months[index];
          final month = monthData['month'] as DateTime;
          final total = monthData['total'] as double;
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.glassmorphismCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM').format(month),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.darkGray,
                      ),
                ),
                Text(
                  '₹${NumberFormat('#,##,###').format(total)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildPremiumActionButton(
            icon: Icons.add_circle,
            label: 'Add Work',
            color: AppTheme.accentBlue,
            onTap: () async {
              final result = await Navigator.of(context).push<WorkEntryModel>(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      AddWorkEntryScreen(userId: widget.userId),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    );
                  },
                ),
              );
              
              if (result != null) {
                setState(() {
                  _workEntries.insert(0, result);
                  final now = DateTime.now();
                  final currentMonthEntries = _workEntries.where((e) {
                    return e.date.year == now.year && e.date.month == now.month;
                  }).toList();
                  _currentMonthIncome = currentMonthEntries
                      .map((e) => e.amountEarned)
                      .fold(0.0, (a, b) => a + b);
                });
                _loadData();
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPremiumActionButton(
            icon: Icons.assessment,
            label: 'View Score',
            color: AppTheme.primaryBlue,
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      WorkScoreScreen(userId: widget.userId),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.premiumShadow(color: color),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpiPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassmorphismCard(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.account_balance_wallet, color: AppTheme.accentBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable payouts',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'UPI coming soon',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.darkGray,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddWorkScreen() {
    return Container(
      decoration: AppTheme.gradientBackground(),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: AppTheme.glassmorphismCard(),
                child: Column(
                  children: [
                    Icon(
                      Icons.add_circle,
                      size: 64,
                      color: AppTheme.accentBlue,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Add Work Entry',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap the button below to add a new work entry',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.darkGray,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.of(context).push<WorkEntryModel>(
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) =>
                                AddWorkEntryScreen(userId: widget.userId),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 1),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              );
                            },
                          ),
                        );
                        
                        if (result != null) {
                          setState(() {
                            _workEntries.insert(0, result);
                            final now = DateTime.now();
                            final currentMonthEntries = _workEntries.where((e) {
                              return e.date.year == now.year && e.date.month == now.month;
                            }).toList();
                            _currentMonthIncome = currentMonthEntries
                                .map((e) => e.amountEarned)
                                .fold(0.0, (a, b) => a + b);
                          });
                          _loadData();
                          setState(() {
                            _currentIndex = 0; // Go back to dashboard
                          });
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Work Entry'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

