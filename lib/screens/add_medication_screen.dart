import 'package:flutter/material.dart';
import '../viewmodels/medication_view_model.dart';
import 'package:intl/intl.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController(); // Optional now
  final _viewModel = MedicationViewModel(); // Local instance

  String _frequency = '1x'; // 1x, 2x, 3x, PRN
  List<String> _timeSlots = ['Morning']; 
  String _intakeRule = 'none';
  DateTime _startDate = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _updateSlots() {
    setState(() {
      if (_frequency == '1x') {
        if (_timeSlots.length != 1) _timeSlots = ['Morning'];
      } else if (_frequency == '2x') {
        _timeSlots = ['Morning', 'Evening'];
      } else if (_frequency == '3x') {
        _timeSlots = ['Morning', 'Afternoon', 'Evening'];
      } else if (_frequency == 'PRN') {
        _timeSlots = [];
      }
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await _viewModel.addMedication(
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim().isEmpty ? null : _dosageController.text.trim(),
        frequency: _frequency,
        timeSlots: _timeSlots,
        startDate: _startDate,
        intakeRule: _intakeRule,
      );

      if (success && mounted) {
        Navigator.pop(context);
      } else if (_viewModel.errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_viewModel.errorMessage!)),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Medication')),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Medication Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Dosage (Optional)
                  TextFormField(
                    controller: _dosageController,
                    decoration: const InputDecoration(
                      labelText: 'Dosage (Optional)',
                      hintText: 'e.g. 500mg',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Start Date
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(DateFormat.yMMMd().format(_startDate)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Frequency
                  Text('Frequency', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    children: ['1x', '2x', '3x', 'PRN'].map((freq) {
                      return ChoiceChip(
                        label: Text(freq == 'PRN' ? 'As Needed' : freq),
                        selected: _frequency == freq,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _frequency = freq;
                              _updateSlots();
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Time Slots (If 1x)
                  if (_frequency == '1x') ...[
                    Text('Time of Day', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        FilterChip(
                          label: const Text('Morning'),
                          selected: _timeSlots.contains('Morning'),
                          onSelected: (selected) => setState(() => _timeSlots = ['Morning']),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Afternoon'),
                          selected: _timeSlots.contains('Afternoon'),
                          onSelected: (selected) => setState(() => _timeSlots = ['Afternoon']),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Evening'),
                          selected: _timeSlots.contains('Evening'),
                          onSelected: (selected) => setState(() => _timeSlots = ['Evening']),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Informational text for >1x
                  if (_frequency == '2x') ...[
                     const Text('Schedule: Morning & Evening', style: TextStyle(color: Colors.grey)),
                     const SizedBox(height: 16),
                  ],
                   if (_frequency == '3x') ...[
                     const Text('Schedule: Morning, Afternoon, Evening', style: TextStyle(color: Colors.grey)),
                     const SizedBox(height: 16),
                  ],

                  // Intake Rule
                  Text('Instructions', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _intakeRule,
                    items: const [
                      DropdownMenuItem(value: 'none', child: Text('None')),
                      DropdownMenuItem(value: 'before_food', child: Text('Before Food')),
                      DropdownMenuItem(value: 'after_food', child: Text('After Food')),
                      DropdownMenuItem(value: 'empty_stomach', child: Text('On Empty Stomach')),
                    ],
                    onChanged: (val) => setState(() => _intakeRule = val!),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _viewModel.isLoading ? null : _submit,
                      child: _viewModel.isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Save Medication'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
