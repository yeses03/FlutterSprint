import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:workpass/services/supabase_service.dart';
import 'package:workpass/theme/app_theme.dart';

class AddWorkEntryScreen extends StatefulWidget {
  final String userId;

  const AddWorkEntryScreen({super.key, required this.userId});

  @override
  State<AddWorkEntryScreen> createState() => _AddWorkEntryScreenState();
}

class _AddWorkEntryScreenState extends State<AddWorkEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hoursController = TextEditingController();
  final _amountController = TextEditingController();
  
  String _selectedPlatform = 'Swiggy';
  DateTime _selectedDate = DateTime.now();
  File? _proofImage;
  bool _isLoading = false;

  final List<String> _platforms = [
    'Swiggy',
    'Zomato',
    'Ola',
    'Zepto',
    'OYO',
  ];

  @override
  void dispose() {
    _hoursController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _proofImage = File(image.path);
      });
    }
  }

  String _determineVerificationType() {
    if (_proofImage != null) {
      return 'verified';
    }
    return 'unverified';
  }

  double _determineTrustWeight() {
    if (_proofImage != null) {
      return 1.0;
    }
    return 0.5;
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await SupabaseService.createWorkEntry(
        userId: widget.userId,
        platform: _selectedPlatform,
        date: _selectedDate,
        hoursWorked: double.parse(_hoursController.text),
        amountEarned: double.parse(_amountController.text),
        verificationType: _determineVerificationType(),
        trustWeight: _determineTrustWeight(),
        proofImageUrl: null, // In production, upload to Supabase Storage
      );

      // Recalculate work score
      await SupabaseService.calculateAndUpdateWorkScore(widget.userId);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Work entry added successfully!')),
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Work Entry'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.lightBlue, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedPlatform,
                  decoration: const InputDecoration(
                    labelText: 'Platform',
                    prefixIcon: Icon(Icons.business),
                  ),
                  items: _platforms.map((platform) {
                    return DropdownMenuItem(
                      value: platform,
                      child: Text(platform),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPlatform = value!;
                    });
                  },
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _hoursController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Hours Worked',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter hours worked';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount Earned (₹)',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter amount earned';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: _proofImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload_outlined,
                                  size: 48, color: AppTheme.grey),
                              const SizedBox(height: 8),
                              Text(
                                'Upload Proof Image',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          )
                        : Image.file(_proofImage!, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveEntry,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

