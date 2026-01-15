import 'package:flutter/material.dart';
import 'package:workpass/screens/employer/employer_dashboard_screen.dart';
import 'package:workpass/services/supabase_service.dart';
import 'package:workpass/theme/app_theme.dart';

class EmployerProfileSetupScreen extends StatefulWidget {
  final String phone;

  const EmployerProfileSetupScreen({super.key, required this.phone});

  @override
  State<EmployerProfileSetupScreen> createState() => _EmployerProfileSetupScreenState();
}

class _EmployerProfileSetupScreenState extends State<EmployerProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _industryController = TextEditingController();
  bool _isLoading = false;

  final List<String> _industries = [
    'Technology',
    'Healthcare',
    'Finance',
    'Retail',
    'Hospitality',
    'Manufacturing',
    'Construction',
    'Education',
    'Transportation',
    'Food & Beverage',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _companyNameController.dispose();
    _industryController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await SupabaseService.createEmployerProfile(
        name: _nameController.text,
        phone: widget.phone,
        companyName: _companyNameController.text,
        industry: _industryController.text.isNotEmpty 
            ? _industryController.text 
            : null,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                EmployerDashboardScreen(employerPhone: widget.phone),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground(),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Complete Your Employer Profile',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Help us set up your company profile',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Your Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _companyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Company Name *',
                        prefixIcon: Icon(Icons.business),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your company name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _industryController.text.isNotEmpty 
                          ? _industryController.text 
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Industry',
                        prefixIcon: Icon(Icons.work_outline),
                      ),
                      items: _industries.map((industry) {
                        return DropdownMenuItem(
                          value: industry,
                          child: Text(industry),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _industryController.text = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
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
