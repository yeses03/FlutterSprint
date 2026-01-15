import 'package:flutter/material.dart';
import 'package:workpass/services/supabase_service.dart';
import 'package:workpass/theme/app_theme.dart';

class EmployerAiVerificationScreen extends StatefulWidget {
  const EmployerAiVerificationScreen({super.key});

  @override
  State<EmployerAiVerificationScreen> createState() => _EmployerAiVerificationScreenState();
}

class _EmployerAiVerificationScreenState extends State<EmployerAiVerificationScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use authenticated method (read-only, RLS enforced)
      final logs = await SupabaseService.getAiVerificationLogs();
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _logs = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Verification'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: AppTheme.subtleGradient(),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadLogs,
            color: AppTheme.primaryBlue,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryBlue, AppTheme.secondaryBlue],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'AI Verification',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'AI-powered applications coming soon',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  if (_isLoading)
                    Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                    )
                  else if (_logs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: AppTheme.glassmorphismCard(),
                      child: Column(
                        children: [
                          Icon(
                            Icons.construction,
                            size: 48,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Advanced AI verification tools are under development',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: AppTheme.glassmorphismCard(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verification Logs',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${_logs.length} verification logs found',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
