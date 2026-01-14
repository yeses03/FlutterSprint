import 'package:flutter/material.dart';
import 'package:workpass/screens/worker/worker_dashboard_screen.dart';
import 'package:workpass/services/supabase_service.dart';
import 'package:workpass/theme/app_theme.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String phone;

  const ProfileSetupScreen({super.key, required this.phone});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final Set<String> _selectedWorkTypes = {};
  bool _isLoading = false;

  final List<String> _workTypes = [
    'Food Delivery',
    'Ride Share',
    'Courier',
    'Hotel Staff',
    'Housekeeping',
    'Warehouse',
    'Retail',
    'Security',
    'Freelance',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedWorkTypes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one work type')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final workTypeString = _selectedWorkTypes.join(' + ');

      final userId = await SupabaseService.createUser(
        name: _nameController.text,
        phone: widget.phone,
        city: _cityController.text,
        workType: workTypeString,
      );

      if (mounted) {
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
                    Text(
                      'Complete Your Profile',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Help us understand your work better',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
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
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your city';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Work Type (Select all that apply)',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _workTypes.map((type) {
                        final isSelected = _selectedWorkTypes.contains(type);
                        return FilterChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedWorkTypes.add(type);
                              } else {
                                _selectedWorkTypes.remove(type);
                              }
                            });
                          },
                          selectedColor: AppTheme.lightBlue,
                          checkmarkColor: AppTheme.primaryBlue,
                          labelStyle: TextStyle(
                            color: isSelected ? AppTheme.primaryBlue : AppTheme.darkGray,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                    if (_selectedWorkTypes.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Please select at least one work type',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.errorRed,
                              ),
                        ),
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

