
import 'package:flutter/material.dart';
import '../viewmodels/profile_form_view_model.dart';
import '../presentation/views/dashboard_screen.dart';
import '../l10n/app_localizations.dart';

class ProfileFormScreen extends StatefulWidget {
  const ProfileFormScreen({super.key});

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final _viewModel = ProfileFormViewModel();
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onViewModelChange);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChange);
    _viewModel.dispose();
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _onViewModelChange() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await _viewModel.submitProfile(
      name: _nameController.text,
      height: _heightController.text,
      weight: _weightController.text,
      gender: _selectedGender,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
        (route) => false,
      );
    } else if (_viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_viewModel.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('complete_profile')),
        automaticallyImplyLeading: true, // Visible back arrow
      ),
      body: _viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      loc.translate('profile_description'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    
                    // Name (Required)
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: "${loc.translate('name')} *"),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return loc.translate('enter_name_error');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Height (Optional)
                    TextFormField(
                      controller: _heightController,
                      decoration: InputDecoration(labelText: loc.translate('height_optional')),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                           final h = double.tryParse(value);
                           if (h == null || h <= 0) return loc.translate('invalid_height');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Weight (Optional)
                    TextFormField(
                       controller: _weightController,
                       decoration: InputDecoration(labelText: loc.translate('weight_optional')),
                       keyboardType: TextInputType.number,
                       validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                             final w = double.tryParse(value);
                             if (w == null || w <= 0) return loc.translate('invalid_weight');
                          }
                          return null;
                       }
                    ),
                    const SizedBox(height: 16),

                    // Gender (Optional)
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: loc.translate('gender_optional')),
                      value: _selectedGender,
                      items: ['Male', 'Female', 'Other'].map((String val) {
                        return DropdownMenuItem(value: val, child: Text(loc.translate(val.toLowerCase()) == val.toLowerCase() ? val : loc.translate(val.toLowerCase()))); // Fallback or key logic
                      }).toList(),
                      onChanged: (val) {
                         setState(() => _selectedGender = val);
                      },
                    ),

                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                      child: Text(loc.translate('save_continue')),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
