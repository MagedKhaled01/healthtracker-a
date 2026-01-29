import 'package:flutter/material.dart';
import '../viewmodels/profile_view_model.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ProfileViewModel _viewModel;

  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel();
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.loadProfile();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (!mounted) return;
    
    if (_viewModel.errorMessage != null) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${_viewModel.errorMessage}')),
      );
    }

    if (_nameController.text.isEmpty && _viewModel.name.isNotEmpty) {
      _nameController.text = _viewModel.name;
    }
    if (_heightController.text.isEmpty && _viewModel.height.isNotEmpty) {
      _heightController.text = _viewModel.height;
    }
    if (_weightController.text.isEmpty && _viewModel.weight.isNotEmpty) {
      _weightController.text = _viewModel.weight;
    }
    if (_selectedGender == null && _viewModel.gender != null) {
      _selectedGender = _viewModel.gender;
    }
    
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    _viewModel.setName(_nameController.text);
    _viewModel.setHeight(_heightController.text);
    _viewModel.setWeight(_weightController.text);
    _viewModel.setGender(_selectedGender);

    final success = await _viewModel.saveProfile();
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name *'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _heightController,
                      decoration: const InputDecoration(labelText: 'Height (cm)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                           final h = double.tryParse(value);
                           if (h == null || h <= 0) return 'Invalid height';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(labelText: 'Weight (kg)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                           final w = double.tryParse(value);
                           if (w == null || w <= 0) return 'Invalid weight';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Gender'),
                      value: _selectedGender,
                      items: ['Male', 'Female', 'Other'].map((String val) {
                        return DropdownMenuItem(value: val, child: Text(val));
                      }).toList(),
                      onChanged: (val) {
                         setState(() => _selectedGender = val);
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _save,
                      child: const Text('Save Profile'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
