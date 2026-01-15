import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:workpass/services/supabase_service.dart';
import 'package:workpass/models/user_model.dart';
import 'package:workpass/theme/app_theme.dart';

class EmployerWorkerDetailScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const EmployerWorkerDetailScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<EmployerWorkerDetailScreen> createState() => _EmployerWorkerDetailScreenState();
}

class _EmployerWorkerDetailScreenState extends State<EmployerWorkerDetailScreen> {
  UserModel? _user;
  List<Map<String, dynamic>> _workHistory = [];
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
      // Fetch user data
      final user = await SupabaseService.getUser(widget.userId);

      // Fetch work history using authenticated method (RLS enforced)
      final workHistory = await SupabaseService.getWorkerWorkHistory(widget.userId);

      setState(() {
        _user = user;
        _workHistory = workHistory;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _approveEntry(Map<String, dynamic> entry) async {
    try {
      final entryId = entry['id'] as String;
      
      // Use authenticated method that updates work_history and creates audit record
      await SupabaseService.verifyWorkHistoryEntry(
        entryId: entryId,
        verificationStatus: 'verified',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Entry approved successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to approve entry'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _rejectEntry(Map<String, dynamic> entry) async {
    final reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason for rejection...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      try {
        final entryId = entry['id'] as String;
        
        // Use authenticated method that updates work_history and creates audit record
        await SupabaseService.verifyWorkHistoryEntry(
          entryId: entryId,
          verificationStatus: 'rejected',
          rejectionReason: reasonController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Entry rejected'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to reject entry'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    }
  }

  Color _getVerificationColor(String? verificationStatus) {
    switch (verificationStatus) {
      case 'verified':
        return AppTheme.successGreen;
      case 'rejected':
        return AppTheme.errorRed;
      default:
        return AppTheme.warningAmber;
    }
  }

  String _getVerificationStatus(String? verificationStatus) {
    switch (verificationStatus) {
      case 'verified':
        return 'Verified';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: AppTheme.subtleGradient(),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: AppTheme.primaryBlue,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 24),
                  Text(
                    'Work History',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  if (_workHistory.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.work_outline, size: 64, color: AppTheme.textTertiary),
                          const SizedBox(height: 16),
                          Text(
                            'No work history found',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    )
                  else
                    ..._workHistory.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildEntryCard(entry),
                      );
                    }),
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
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _user?.name ?? widget.userName,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          if (_user != null) ...[
            _buildInfoRow(Icons.location_city, _user!.city),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.work, _user!.workType),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.phone, _user!.phone),
          ],
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

  Widget _buildEntryCard(Map<String, dynamic> entry) {
    final verificationStatus = entry['verification_status'] as String?;
    final verificationColor = _getVerificationColor(verificationStatus);
    final statusText = _getVerificationStatus(verificationStatus);
    
    final platform = entry['role'] as String? ?? entry['platform'] as String? ?? 'Unknown';
    final dateStr = entry['date'] as String? ?? '';
    DateTime? date;
    if (dateStr.isNotEmpty) {
      try {
        date = DateTime.parse(dateStr);
      } catch (e) {
        date = null;
      }
    }
    
    final hours = (entry['hours_worked'] as num?)?.toDouble() ?? 
                  (entry['duration'] as num?)?.toDouble() ?? 0.0;
    final amount = (entry['amount_earned'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassmorphismCard(),
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
                      platform,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    if (date != null)
                      Text(
                        DateFormat('MMM dd, yyyy').format(date),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: verificationColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: verificationColor, width: 1.5),
                ),
                child: Text(
                  statusText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: verificationColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.access_time,
                  '${hours.toStringAsFixed(1)} hours',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.currency_rupee,
                  '₹${NumberFormat('#,##,###').format(amount)}',
                ),
              ),
            ],
          ),
          if (verificationStatus != 'verified' && verificationStatus != 'rejected') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _approveEntry(entry),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.successGreen,
                      side: BorderSide(color: AppTheme.successGreen),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectEntry(entry),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorRed,
                      side: BorderSide(color: AppTheme.errorRed),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textTertiary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
