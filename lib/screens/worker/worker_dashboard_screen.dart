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
import 'package:workpass/widgets/greeting_header.dart';
import 'package:workpass/widgets/animated_counter.dart';
import 'package:workpass/widgets/status_chip.dart';
import 'package:workpass/widgets/premium_card.dart';
import 'package:workpass/widgets/skeleton_loader.dart';

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
        body: Container(
          decoration: AppTheme.subtleGradient(),
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const SkeletonLoader(width: 200, height: 24, borderRadius: BorderRadius.all(Radius.circular(4))),
                        const SizedBox(height: 20),
                        const SkeletonLoader(width: double.infinity, height: 180, borderRadius: BorderRadius.all(Radius.circular(20))),
                        const SizedBox(height: 20),
                        const SkeletonLoader(width: 150, height: 20, borderRadius: BorderRadius.all(Radius.circular(4))),
                        const SizedBox(height: 12),
                        const SkeletonCard(),
                        const SkeletonCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
          color: AppTheme.surfaceWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_rounded,
                  activeIcon: Icons.home,
                  label: 'Home',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.add_circle_outline_rounded,
                  activeIcon: Icons.add_circle,
                  label: 'Add',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.history_rounded,
                  activeIcon: Icons.history,
                  label: 'History',
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  index: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeScreen() {
    return Container(
      decoration: AppTheme.subtleGradient(),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.primaryBlue,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header with greeting and status
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GreetingHeader(
                          userName: _user?.name ?? 'User',
                        ),
                      ),
                      Row(
                        children: [
                          StatusChip(isActive: true),
                          const SizedBox(width: 12),
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
                                        return SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0, 0.1),
                                            end: Offset.zero,
                                          ).animate(CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOutCubic,
                                          )),
                                          child: FadeTransition(opacity: animation, child: child),
                                        );
                                      },
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceWhite,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: AppTheme.cardShadow(),
                                ),
                            child: Icon(
                              Icons.insights_outlined,
                              color: AppTheme.primaryBlue,
                            ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Animated earnings card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _buildAnimatedEarningsCard(),
                ),
              ),
              // Quick stats horizontal scroll
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'This Month',
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
              // Quick actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _buildQuickActions(),
                ),
              ),
              // Recent activity
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _buildRecentActivity(),
                ),
              ),
              // Bottom spacing for navigation bar
              SliverToBoxAdapter(
                child: SizedBox(height: 70 + MediaQuery.of(context).padding.bottom),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedEarningsCard() {
    final score = _workScore?.score ?? 0.0;
    
    return PremiumCard(
      padding: const EdgeInsets.all(24),
      backgroundColor: AppTheme.surfaceWhite,
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'This Month\'s Earnings',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedCounter(
                      targetValue: _currentMonthIncome,
                      prefix: '₹',
                      textStyle: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                      decimalPlaces: 0,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.secondaryBlue],
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
                child: const Icon(
                  Icons.currency_rupee,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accentBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'WorkScore',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        score.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 6,
                    backgroundColor: AppTheme.dividerGray,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                  ),
                ),
              ],
            ),
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
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: months.length,
        itemBuilder: (context, index) {
          final monthData = months[index];
          final month = monthData['month'] as DateTime;
          final total = monthData['total'] as double;
          final isCurrentMonth = month.year == now.year && month.month == now.month;
          
          return Container(
            width: 110,
            margin: EdgeInsets.only(
              left: index == 0 ? 0 : 12,
              right: index == months.length - 1 ? 0 : 0,
            ),
            child: PremiumCard(
              padding: const EdgeInsets.all(16),
              backgroundColor: isCurrentMonth 
                  ? AppTheme.accentBlue 
                  : AppTheme.surfaceWhite,
              borderRadius: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('MMM').format(month),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${NumberFormat('#,##,###').format(total)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isCurrentMonth ? AppTheme.primaryBlue : AppTheme.textPrimary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.add_circle_rounded,
                label: 'Add Work',
                color: AppTheme.primaryBlue,
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
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          )),
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
              child: _buildActionCard(
                icon: Icons.insights_rounded,
                label: 'View Score',
                color: AppTheme.primaryBlue,
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          WorkScoreScreen(userId: widget.userId),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          )),
                          child: FadeTransition(opacity: animation, child: child),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
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
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 20,
          ),
          decoration: BoxDecoration(
            color: AppTheme.accentBlue,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    if (_workEntries.isEmpty) {
      return PremiumCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.work_outline,
              size: 48,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'No recent activity',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first work entry to get started!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ..._workEntries.take(3).map((entry) {
          return PremiumCard(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            onTap: () {
              setState(() {
                _currentIndex = 2; // Go to history tab
              });
            },
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.work_outline,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.platform,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy').format(entry.date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '₹${NumberFormat('#,##,###').format(entry.amountEarned)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentIndex = index;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            height: 42,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppTheme.accentBlue 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isSelected ? activeIcon : icon,
                      color: isSelected ? AppTheme.primaryBlue : AppTheme.textTertiary,
                      size: 24,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected ? AppTheme.primaryBlue : AppTheme.textTertiary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 11,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildAddWorkScreen() {
    return Container(
      decoration: AppTheme.gradientBackground(),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                         MediaQuery.of(context).padding.top - 
                         MediaQuery.of(context).padding.bottom - 
                         70, // Bottom nav height
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: AppTheme.glassmorphismCard(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_circle,
                        size: 64,
                        color: AppTheme.primaryBlue,
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
                              color: AppTheme.textSecondary,
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}

