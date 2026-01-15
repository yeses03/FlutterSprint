import 'package:flutter/material.dart';
import 'package:workpass/screens/profile_setup_screen.dart';
import 'package:workpass/screens/bank/bank_dashboard_screen.dart';
import 'package:workpass/screens/bank/bank_profile_setup_screen.dart';
import 'package:workpass/screens/worker/worker_dashboard_screen.dart';
import 'package:workpass/screens/employer/employer_dashboard_screen.dart';
import 'package:workpass/screens/employer/employer_profile_setup_screen.dart';
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
    if (!_validateOtp()) return;

    _setLoading(true);
    await _simulateOtpVerification();

    try {
      await _handlePostOtpFlow();
    } finally {
      if (mounted) _setLoading(false);
    }
  }

  bool _validateOtp() {
    if (_otpController.text.isEmpty) {
      _showSnack('Please enter OTP');
      return false;
    }
    return true;
  }

  void _setLoading(bool value) {
    if (mounted) {
      setState(() => _isLoading = value);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _simulateOtpVerification() async {
    await Future.delayed(const Duration(milliseconds: 0));
  }

  Future<void> _handlePostOtpFlow() async {
    switch (widget.role) {
      case 'bank':
        await _handleBankLogin();
        break;

      case 'employer':
        await _handleEmployerLogin();
        break;

      default:
        await _handleWorkerLogin();
    }
  }

  Future<void> _handleBankLogin() async {
    final user = await _fetchUserSilently();

    if (!mounted) return;

    if (user == null) {
      // New bank officer - route to profile setup
      _navigateWithFade(
        BankProfileSetupScreen(phone: _phoneController.text),
      );
      return;
    }

    // Existing bank officer - route to dashboard
    _navigateWithFade(const BankDashboardScreen());
  }

  Future<void> _handleEmployerLogin() async {
    final employerProfile = await _fetchEmployerProfile();

    if (!mounted) return;

    if (employerProfile == null) {
      // New employer - route to profile setup
      _navigateWithFade(
        EmployerProfileSetupScreen(phone: _phoneController.text),
      );
      return;
    }

    // Existing employer - route to dashboard with phone
    _navigateWithFade(
        EmployerDashboardScreen(employerPhone: _phoneController.text));
  }

  Future<void> _handleWorkerLogin() async {
    final user = await _fetchUserSilently();

    if (!mounted) return;

    if (user == null) {
      _handleNewOrDemoWorker();
      return;
    }

    final userId = user['id'] as String? ?? '';
    if (userId.isEmpty) {
      _showSnack('Login failed');
      return;
    }

    _navigateWithFade(WorkerDashboardScreen(userId: userId));
  }

  void _handleNewOrDemoWorker() {
    final phone = _phoneController.text;

    if (phone.contains('9876543210') || phone.contains('98765')) {
      final mockUser = MockDataService.getMockUser();
      _navigateWithFade(
        WorkerDashboardScreen(userId: mockUser.id),
      );
    } else {
      _navigateWithFade(
        ProfileSetupScreen(phone: phone),
      );
    }
  }

  Future<Map<String, dynamic>?> _fetchUserSilently() async {
    try {
      final userModel =
          await SupabaseService.getUserByPhone(_phoneController.text);
      print('userModel Fetched ${userModel.toString()}');
      return userModel?.toJson();
    } catch (_) {
      // Demo / offline mode fallback
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchEmployerProfile() async {
    try {
      final employerProfile =
          await SupabaseService.getEmployerByPhone(_phoneController.text);
      return employerProfile;
    } catch (_) {
      // Demo / offline mode fallback
      return null;
    }
  }

  void _navigateWithFade(Widget page) {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => page,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
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
                      widget.role == 'bank'
                          ? 'Bank Officer Login'
                          : widget.role == 'employer'
                              ? 'Employer Login'
                              : 'Gig Worker Login',
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
                      maxLength: 10,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '+91 9876543210',
                        hintStyle:
                            TextStyle(color: Color.fromRGBO(54, 50, 50, 0.6)),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      enabled: !_showOtp,
                    ),
                    if (_showOtp) ...[
                      const SizedBox(height: 24),
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
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
