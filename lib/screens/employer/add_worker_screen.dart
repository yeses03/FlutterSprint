import 'package:flutter/material.dart';
import 'package:workpass/services/supabase_service.dart';
import 'package:workpass/theme/app_theme.dart';

class AddWorkerScreen extends StatefulWidget {
  final String employerPhone;

  const AddWorkerScreen({super.key, required this.employerPhone});

  @override
  State<AddWorkerScreen> createState() => _AddWorkerScreenState();
}

class _AddWorkerScreenState extends State<AddWorkerScreen> {
  List<Map<String, dynamic>> _workers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _employerId;

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
      // Get employer_id
      _employerId = await SupabaseService.getEmployerIdByPhone(widget.employerPhone);
      
      // Get all workers
      final workers = await SupabaseService.getAllWorkers();
      
      // Filter out workers already associated with this employer
      if (_employerId != null) {
        final existingWorkers = await SupabaseService.getEmployerWorkers(_employerId!);
        final existingWorkerIds = existingWorkers.map((w) => w['id'] as String).toSet();
        
        setState(() {
          _workers = workers.where((worker) {
            final workerId = worker['id'] as String? ?? '';
            return !existingWorkerIds.contains(workerId);
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _workers = workers;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _workers = [];
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading workers: $e')),
        );
      }
    }
  }

  Future<void> _addWorker(String workerId) async {
    if (_employerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employer profile not found')),
      );
      return;
    }

    try {
      await SupabaseService.addWorkerToEmployer(
        employerId: _employerId!,
        workerId: workerId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Worker added successfully')),
        );
        // Remove the worker from the list
        setState(() {
          _workers = _workers.where((w) => w['id'] != workerId).toList();
        });
        // Return true to indicate success (for parent screen to refresh)
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredWorkers {
    if (_searchQuery.isEmpty) return _workers;
    
    final queryLower = _searchQuery.toLowerCase();
    return _workers.where((worker) {
      final name = (worker['name'] as String? ?? '').toLowerCase();
      final workType = (worker['work_type'] as String? ?? '').toLowerCase();
      return name.contains(queryLower) || workType.contains(queryLower);
    }).toList();
  }

  String _getFirstName(String fullName) {
    final parts = fullName.trim().split(' ');
    return parts.isNotEmpty ? parts[0] : fullName;
  }

  String _getLastName(String fullName) {
    final parts = fullName.trim().split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Worker'),
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
                      hintText: 'Search by name or work type...',
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
                    : _filteredWorkers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: AppTheme.textTertiary),
                                const SizedBox(height: 16),
                                Text(
                                  _workers.isEmpty 
                                      ? 'No workers available' 
                                      : 'No workers found',
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
                              itemCount: _filteredWorkers.length,
                              itemBuilder: (context, index) {
                                final worker = _filteredWorkers[index];
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
    final fullName = worker['name'] as String? ?? 'Unknown';
    final firstName = _getFirstName(fullName);
    final lastName = _getLastName(fullName);
    final workType = worker['work_type'] as String? ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _addWorker(workerId),
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
                  Icons.person_add,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (lastName.isNotEmpty) ...[
                      Text(
                        firstName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lastName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ] else
                      Text(
                        fullName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      workType,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.add_circle_outline,
                color: AppTheme.primaryBlue,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
