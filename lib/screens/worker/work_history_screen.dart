import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:workpass/models/work_entry_model.dart';
import 'package:workpass/services/supabase_service.dart';
import 'package:workpass/theme/app_theme.dart';

class WorkHistoryScreen extends StatefulWidget {
  final String userId;

  const WorkHistoryScreen({super.key, required this.userId});

  @override
  State<WorkHistoryScreen> createState() => _WorkHistoryScreenState();
}

class _WorkHistoryScreenState extends State<WorkHistoryScreen> {
  List<WorkEntryModel> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final entries = await SupabaseService.getWorkEntries(widget.userId);
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
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
        return AppTheme.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Text(
                      'Work History',
                      style: Theme.of(context).textTheme.displayMedium,
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
                                Icon(Icons.history, size: 64, color: AppTheme.grey),
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
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              itemCount: _entries.length,
                              itemBuilder: (context, index) {
                                final entry = _entries[index];
                                return _buildEntryCard(entry);
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

  Widget _buildEntryCard(WorkEntryModel entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.platform,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy').format(entry.date),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getVerificationColor(entry.verificationType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getVerificationColor(entry.verificationType),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    entry.verificationType == 'verified' ? 'Verified' : 'Unverified',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getVerificationColor(entry.verificationType),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(
                  Icons.access_time,
                  '${entry.hoursWorked.toStringAsFixed(1)} hrs',
                ),
                _buildInfoItem(
                  Icons.currency_rupee,
                  '₹${NumberFormat('#,##,###').format(entry.amountEarned)}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _deleteEntry(entry.id),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.errorRed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.grey),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

