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
  String _selectedWorkType = 'Delivery';
  bool _isLoading = false;

  final List<String> _workTypes = [
    'Delivery',
    'Ride',
    'Hotel',
    'Freelance',
    'Other',
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
      final userId = await SupabaseService.createUser(
        name: _nameController.text,
        phone: widget.phone,
        city: _cityController.text,
        workType: _selectedWorkType,
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.lightBlue, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  DropdownButtonFormField<String>(
                    value: _selectedWorkType,
                    decoration: const InputDecoration(
                      labelText: 'Work Type',
                      prefixIcon: Icon(Icons.work),
                    ),
                    items: _workTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedWorkType = value!;
                      });
                    },
                  ),
                  const Spacer(),
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
    );
  }
}

