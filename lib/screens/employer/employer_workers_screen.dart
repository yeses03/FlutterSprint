import 'package:flutter/material.dart';
import 'package:workpass/services/supabase_service.dart';
import 'package:workpass/theme/app_theme.dart';
import 'package:workpass/screens/employer/employer_worker_detail_screen.dart';
import 'package:workpass/screens/employer/add_worker_screen.dart';

class EmployerWorkersScreen extends StatefulWidget {
  final String? employerPhone;
  final VoidCallback? onTabSelected;

  const EmployerWorkersScreen({super.key, this.employerPhone, this.onTabSelected});

  @override
  State<EmployerWorkersScreen> createState() => _EmployerWorkersScreenState();
}

class _EmployerWorkersScreenState extends State<EmployerWorkersScreen> {
  List<Map<String, dynamic>> _workers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _employerId;
  String? _employerPhone;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    _employerPhone = widget.employerPhone;
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data each time the screen becomes visible (when dependencies change)
    // This ensures fresh data when navigating back to this tab
    if (_hasLoaded && !_isLoading) {
      _loadData();
    }
  }

  @override
  void didUpdateWidget(EmployerWorkersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if employer phone changed
    if (oldWidget.employerPhone != widget.employerPhone) {
      _employerPhone = widget.employerPhone;
      _loadData();
    }
  }

  // Public method to reload data (can be called from parent)
  void reloadData() {
    if (!_isLoading) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get employer phone if not provided
      if (_employerPhone == null) {
        // Try to get from current user context
        // For now, we'll need to pass it from the dashboard
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get employer_id
      _employerId = await SupabaseService.getEmployerIdByPhone(_employerPhone!);
      
      if (_employerId == null) {
        setState(() {
          _workers = [];
          _isLoading = false;
        });
        return;
      }

      // Fetch workers from employer_worker table
      final workers = await SupabaseService.getEmployerWorkers(_employerId!);

      // Apply search filter
      var filteredWorkers = workers;
      if (_searchQuery.isNotEmpty) {
        final queryLower = _searchQuery.toLowerCase();
        filteredWorkers = workers.where((worker) {
          final name = (worker['name'] as String? ?? '').toLowerCase();
          final phone = (worker['phone'] as String? ?? '').toLowerCase();
          final city = (worker['city'] as String? ?? '').toLowerCase();
          final workType = (worker['work_type'] as String? ?? '').toLowerCase();
          return name.contains(queryLower) ||
              phone.contains(queryLower) ||
              city.contains(queryLower) ||
              workType.contains(queryLower);
        }).toList();
      }

      setState(() {
        _workers = filteredWorkers;
        _isLoading = false;
        _hasLoaded = true;
      });
    } catch (e) {
      setState(() {
        _workers = [];
        _isLoading = false;
        _hasLoaded = true;
      });
    }
  }

  Future<void> _navigateToAddWorker() async {
    if (_employerPhone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employer phone not available')),
      );
      return;
    }

    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AddWorkerScreen(employerPhone: _employerPhone!),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    // Reload data after returning from add worker screen
    if (result == true || mounted) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workers'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _navigateToAddWorker,
            tooltip: 'Add Worker',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddWorker,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Worker'),
        backgroundColor: AppTheme.primaryBlue,
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
                      hintText: 'Search by name, phone, or city...',
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
                      _loadData();
                    },
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                      )
                    : _workers.isEmpty
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
                            child: ListView.builder(
                              padding: const EdgeInsets.all(24),
                              itemCount: _workers.length,
                              itemBuilder: (context, index) {
                                final worker = _workers[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildWorkerCard(worker),
                                );
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

  Widget _buildWorkerCard(Map<String, dynamic> worker) {
    final workerId = worker['id'] as String? ?? '';
    final workerName = worker['name'] as String? ?? 'Unknown';
    final workerCity = worker['city'] as String? ?? '';
    final workType = worker['work_type'] as String? ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  EmployerWorkerDetailScreen(
                    userId: workerId,
                    userName: workerName,
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
          decoration: AppTheme.glassmorphismCard(),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.7)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workerName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      workerCity,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      workType,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textTertiary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.primaryBlue,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
