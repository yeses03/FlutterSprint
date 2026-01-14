import 'package:flutter/material.dart';
import 'package:workpass/screens/profile_setup_screen.dart';
import 'package:workpass/screens/bank/bank_dashboard_screen.dart';
import 'package:workpass/screens/worker/worker_dashboard_screen.dart';
import 'package:workpass/services/supabase_service.dart';
import 'package:workpass/services/mock_data_service.dart';
import 'package:workpass/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final String role;

  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _showOtp = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }

    setState(() {
      _showOtp = true;
    });
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter OTP')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Demo mode: Accept any OTP
    await Future.delayed(const Duration(milliseconds: 500));

    if (widget.role == 'bank') {
      // Auto-login for bank officer
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const BankDashboardScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    } else {
      // Check if user exists
      Map<String, dynamic>? user;
      try {
        final userModel = await SupabaseService.getUserByPhone(_phoneController.text);
        if (userModel != null) {
          user = userModel.toJson();
        }
      } catch (e) {
        // Supabase not available, use mock data for demo
      }
      
      if (mounted) {
        if (user == null) {
          // For demo: Use mock user if phone matches, otherwise new user
          if (_phoneController.text.contains('9876543210') || 
              _phoneController.text.contains('98765')) {
            // Demo user - use mock data
            final mockUser = MockDataService.getMockUser();
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    WorkerDashboardScreen(userId: mockUser.id),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            );
          } else {
            // New user - go to profile setup
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    ProfileSetupScreen(phone: _phoneController.text),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            );
          }
        } else {
          // Existing user - go to dashboard
          final userId = user?['id'] as String? ?? '';
          if (userId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Login failed')),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  WorkerDashboardScreen(userId: userId),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        }
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground(),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                           MediaQuery.of(context).padding.top - 
                           MediaQuery.of(context).padding.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      widget.role == 'bank' ? 'Bank Officer Login' : 'Gig Worker Login',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your phone number to continue',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 48),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '+91 9876543210',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      enabled: !_showOtp,
                    ),
                    if (_showOtp) ...[
                      const SizedBox(height: 24),
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'OTP',
                          hintText: 'Enter 6-digit OTP',
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                    if (!_showOtp)
                      ElevatedButton(
                        onPressed: _sendOtp,
                        child: const Text('Send OTP'),
                      )
                    else
                      ElevatedButton(
                        onPressed: _isLoading ? null : _verifyOtp,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Continue'),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

