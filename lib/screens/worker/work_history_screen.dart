import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:workpass/models/work_entry_model.dart';
import 'package:workpass/services/supabase_service.dart';
import 'package:workpass/services/mock_data_service.dart';
import 'package:workpass/theme/app_theme.dart';

class WorkHistoryScreen extends StatefulWidget {
  final String userId;
  final List<WorkEntryModel>? initialEntries;
  final Function(WorkEntryModel)? onEntryAdded;

  const WorkHistoryScreen({
    super.key,
    required this.userId,
    this.initialEntries,
    this.onEntryAdded,
  });

  @override
  State<WorkHistoryScreen> createState() => _WorkHistoryScreenState();
}

class _WorkHistoryScreenState extends State<WorkHistoryScreen> {
  List<WorkEntryModel> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialEntries != null && widget.initialEntries!.isNotEmpty) {
      _entries = List.from(widget.initialEntries!);
      _isLoading = false;
    } else {
      _loadEntries();
    }
  }

  @override
  void didUpdateWidget(WorkHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update entries if initialEntries changed
    if (widget.initialEntries != null) {
      // Check if the lists are different
      if (widget.initialEntries!.length != _entries.length ||
          (widget.initialEntries!.isNotEmpty && 
           widget.initialEntries![0].id != _entries[0].id)) {
        setState(() {
          _entries = List.from(widget.initialEntries!);
        });
      }
    }
  }

  Future<void> _loadEntries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<WorkEntryModel> entries = [];
      try {
        entries = await SupabaseService.getWorkEntries(widget.userId);
      } catch (e) {
        // Supabase not available, use mock data
      }

      // Use mock data if Supabase data is not available
      if (entries.isEmpty || MockDataService.shouldUseMockData(widget.userId)) {
        entries = MockDataService.getMockWorkEntries();
      }

      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      // Fallback to mock data
      setState(() {
        _entries = MockDataService.getMockWorkEntries();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEntry(String entryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.deleteWorkEntry(entryId);
        await SupabaseService.calculateAndUpdateWorkScore(widget.userId);
        _loadEntries();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entry deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Color _getVerificationColor(String type) {
    switch (type) {
      case 'verified':
        return AppTheme.successGreen;
      default:
        return AppTheme.darkGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground(),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  children: [
                    Text(
                      'Work History',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                      )
                    : _entries.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history, size: 64, color: AppTheme.darkGray),
                                const SizedBox(height: 16),
                                Text(
                                  'No work entries yet',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadEntries,
                            color: AppTheme.accentBlue,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(24),
                              itemCount: _entries.length,
                              itemBuilder: (context, index) {
                                final entry = _entries[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildPremiumEntryCard(entry),
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

  Widget _buildPremiumEntryCard(WorkEntryModel entry) {
    final verificationColor = _getVerificationColor(entry.verificationType);
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.glassmorphismCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.accentBlue, AppTheme.primaryBlue],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.business,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.platform,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, MMM dd, yyyy').format(entry.date),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.darkGray,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: verificationColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: verificationColor, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        entry.verificationType == 'verified' ? Icons.verified : Icons.info_outline,
                        size: 16,
                        color: verificationColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        entry.verificationType == 'verified' ? 'Verified' : 'Unverified',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: verificationColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPremiumInfoItem(
                    Icons.access_time,
                    '${entry.hoursWorked.toStringAsFixed(1)}',
                    'hours',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppTheme.mediumGray.withOpacity(0.3),
                  ),
                  _buildPremiumInfoItem(
                    Icons.currency_rupee,
                    '₹${NumberFormat('#,##,###').format(entry.amountEarned)}',
                    'earned',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _deleteEntry(entry.id),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorRed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.accentBlue, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.deepBlue,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.darkGray,
              ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.darkGray),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

