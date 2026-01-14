import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:workpass/models/work_entry_model.dart';
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
  XFile? _proofImage;
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
        _proofImage = image;
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
      final hoursWorked = double.parse(_hoursController.text);
      final amountEarned = double.parse(_amountController.text);
      final verificationType = _determineVerificationType();
      final trustWeight = _determineTrustWeight();

      // Create work entry in Supabase
      String entryId;
      try {
        entryId = await SupabaseService.createWorkEntry(
          userId: widget.userId,
          platform: _selectedPlatform,
          date: _selectedDate,
          hoursWorked: hoursWorked,
          amountEarned: amountEarned,
          verificationType: verificationType,
          trustWeight: trustWeight,
          proofImageUrl: null, // In production, upload to Supabase Storage first
        );

        // Recalculate work score
        try {
          await SupabaseService.calculateAndUpdateWorkScore(widget.userId);
        } catch (e) {
          // Score calculation failure shouldn't block the save
        }
      } catch (e) {
        // Supabase error - show friendly message
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not save. Please try again.'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
        return;
      }

      // Create WorkEntry object for immediate UI update
      final newEntry = WorkEntryModel(
        id: entryId,
        userId: widget.userId,
        platform: _selectedPlatform,
        date: _selectedDate,
        hoursWorked: hoursWorked,
        amountEarned: amountEarned,
        verificationType: verificationType,
        trustWeight: trustWeight,
        proofImageUrl: null,
        createdAt: DateTime.now(),
      );

      // Show success message and return the new entry
      if (mounted) {
        Navigator.of(context).pop(newEntry);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Successfully added'),
            backgroundColor: AppTheme.successGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Unexpected error
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save. Please try again.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
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
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: AppTheme.gradientBackground(),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Platform Selection - Pill Buttons
                        Text(
                          'Platform',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _platforms.map((platform) {
                            final isSelected = _selectedPlatform == platform;
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedPlatform = platform;
                                  });
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppTheme.accentBlue : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected ? AppTheme.accentBlue : AppTheme.mediumGray,
                                      width: 2,
                                    ),
                                    boxShadow: isSelected ? AppTheme.premiumShadow(color: AppTheme.accentBlue) : null,
                                  ),
                                  child: Text(
                                    platform,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: isSelected ? Colors.white : AppTheme.deepBlue,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                        // Date Selection
                        Text(
                          'Date',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _selectDate,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: AppTheme.glassmorphismCard(),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, color: AppTheme.accentBlue),
                                  const SizedBox(width: 16),
                                  Text(
                                    DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.darkGray),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Hours Worked - Slider
                        Text(
                          'Hours Worked',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: AppTheme.glassmorphismCard(),
                          child: Column(
                            children: [
                              Text(
                                _hoursController.text.isEmpty 
                                    ? '0.0' 
                                    : double.tryParse(_hoursController.text)?.toStringAsFixed(1) ?? '0.0',
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.accentBlue,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'hours',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.darkGray,
                                    ),
                              ),
                              const SizedBox(height: 24),
                              Slider(
                                value: _hoursController.text.isEmpty 
                                    ? 0.0 
                                    : (double.tryParse(_hoursController.text) ?? 0.0).clamp(0.0, 24.0),
                                min: 0,
                                max: 24,
                                divisions: 240,
                                activeColor: AppTheme.accentBlue,
                                onChanged: (value) {
                                  setState(() {
                                    _hoursController.text = value.toStringAsFixed(1);
                                  });
                                },
                              ),
                              TextFormField(
                                controller: _hoursController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Or enter manually',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                onChanged: (value) {
                                  setState(() {});
                                },
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Amount Earned - Big Number Display
                        Text(
                          'Amount Earned',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: AppTheme.gradientCard(),
                          child: Column(
                            children: [
                              Text(
                                _amountController.text.isEmpty 
                                    ? '₹0' 
                                    : '₹${NumberFormat('#,##,###').format(double.tryParse(_amountController.text) ?? 0)}',
                                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                decoration: InputDecoration(
                                  hintText: 'Enter amount',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.2),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: Colors.white, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                ),
                                onChanged: (value) {
                                  setState(() {});
                                },
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Proof Image (Optional)
                        Text(
                          'Proof Image (Optional)',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Proof optional for now — verification will be strengthened later',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.darkGray,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _pickImage,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              height: 200,
                              decoration: AppTheme.glassmorphismCard(),
                              child: _proofImage == null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: AppTheme.accentBlue.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.cloud_upload_outlined,
                                            size: 48,
                                            color: AppTheme.accentBlue,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Upload Proof Image',
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Optional',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: AppTheme.darkGray,
                                              ),
                                        ),
                                      ],
                                    )
                                  : FutureBuilder<Uint8List?>(
                                      future: _proofImage!.readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          return Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(20),
                                                child: Image.memory(
                                                  snapshot.data!,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: 200,
                                                ),
                                              ),
                                              Positioned(
                                                top: 12,
                                                right: 12,
                                                child: Material(
                                                  color: Colors.black54,
                                                  borderRadius: BorderRadius.circular(20),
                                                  child: InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        _proofImage = null;
                                                      });
                                                    },
                                                    borderRadius: BorderRadius.circular(20),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(8),
                                                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Save Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveEntry,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle, size: 24),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Save Work Entry',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                          child: Text(
                            'Cancel',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppTheme.darkGray,
                                ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

