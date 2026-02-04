import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/measurements_view_model.dart';
import '../../domain/entities/measurement.dart';
import '../../l10n/app_localizations.dart';

class AddMeasurementScreen extends StatefulWidget {
  final Measurement? measurementToEdit;
  
  // Optional pre-selected type if adding new
  final MeasurementType? initialType;

  const AddMeasurementScreen({super.key, this.measurementToEdit, this.initialType});

  @override
  State<AddMeasurementScreen> createState() => _AddMeasurementScreenState();
}

class _AddMeasurementScreenState extends State<AddMeasurementScreen> {
  final _formKey = GlobalKey<FormState>();

  late MeasurementType _selectedType;
  final _valueController = TextEditingController(); // Systolic or Main
  final _value2Controller = TextEditingController(); // Diastolic
  final _noteController = TextEditingController();
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.measurementToEdit != null) {
      final m = widget.measurementToEdit!;
      _selectedType = m.type;
      _valueController.text = m.value?.toString() ?? '';
      _value2Controller.text = m.value2?.toString() ?? '';
      _noteController.text = m.note ?? '';
      _selectedDate = m.date;
    } else {
      _selectedType = widget.initialType ?? MeasurementType.pressure;
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _value2Controller.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveMeasurement() async {
    final loc = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      final viewModel = context.read<MeasurementsViewModel>();
      final value = double.tryParse(_valueController.text);
      final value2 = _selectedType == MeasurementType.pressure 
          ? double.tryParse(_value2Controller.text) 
          : null;
      
      final note = _noteController.text.isNotEmpty ? _noteController.text : null;

      bool success;
      if (widget.measurementToEdit != null) {
        // Update
        final m = widget.measurementToEdit!;
        final updated = Measurement(
          id: m.id,
          userId: m.userId,
          type: _selectedType, // Should type be editable? Maybe.
          value: value,
          value2: value2,
          unit: m.unit, // Re-calculate unit if type changes? Handled in VM logic implicitly or we should re-derive
          date: _selectedDate,
          note: note,
        );
        // We probably should let VM handle unit logic on update too, but for now reuse
        success = await viewModel.updateMeasurement(updated);
      } else {
        // Add
        success = await viewModel.addMeasurement(
          type: _selectedType,
          value: value,
          value2: value2,
          date: _selectedDate,
          note: note,
        );
      }

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.measurementToEdit != null ? loc.translate('updated') : loc.translate('saved'))),
        );
        Navigator.pop(context);
      } else if (viewModel.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.translate('error')}: ${viewModel.errorMessage}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MeasurementsViewModel>();
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.measurementToEdit != null ? loc.translate('edit_measurement') : loc.translate('add_measurement')),
      ),
      body: viewModel.isLoading 
        ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5)) 
        : Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<MeasurementType>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: loc.translate('type'),
                  border: const OutlineInputBorder(),
                ),
                items: MeasurementType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(loc.translate(type.name) == type.name ? type.name.toUpperCase() : loc.translate(type.name)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                   Expanded(
                     child: TextFormField(
                        controller: _valueController,
                        decoration: InputDecoration(
                          labelText: _selectedType == MeasurementType.pressure ? '${loc.translate('systolic')} (120)' : loc.translate('value'),
                          border: const OutlineInputBorder(),
                          counterText: '', // Hide counter
                        ),
                        maxLength: _selectedType == MeasurementType.pressure ? 3 : null,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return loc.translate('required');
                          }
                          if (double.tryParse(value) == null) {
                            return loc.translate('invalid');
                          }
                          if (double.parse(value) <= 0) {
                             return '> 0';
                          }
                          return null;
                        },
                      ),
                   ),
                   if (_selectedType == MeasurementType.pressure) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _value2Controller,
                          decoration: InputDecoration(
                            labelText: '${loc.translate('diastolic')} (80)',
                            border: const OutlineInputBorder(),
                            counterText: '', // Hide counter
                          ),
                          maxLength: 2, // Strictly 2 digits as requested
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return loc.translate('required');
                            }
                            if (double.tryParse(value) == null) {
                              return loc.translate('invalid');
                            }
                            if (double.parse(value) <= 0) {
                               return '> 0';
                            }
                            return null;
                          },
                        ),
                      ),
                   ],
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: loc.translate('date'),
                    border: const OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${_selectedDate.toLocal()}".split(' ')[0]),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: loc.translate('note_optional'),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveMeasurement,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).brightness == Brightness.light ? Colors.black : null,
                    foregroundColor: Theme.of(context).brightness == Brightness.light ? Colors.white : null,
                  ),
                  child: Text(loc.translate('save')),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}
