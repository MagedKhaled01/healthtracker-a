
// Import Material package for UI components.
import 'package:flutter/material.dart';
// Import Provider package for state management.
import 'package:provider/provider.dart';
// Import the ViewModel and Repository implementation.
import '../viewmodels/measurements_view_model.dart';
import '../../data/repositories/measurement_repository_impl.dart';
import '../../domain/entities/measurement.dart';

// Define the main screen widget as a Stateless Widget.
// It sets up the Provider for the ViewModel.
class MeasurementsScreen extends StatelessWidget {
  const MeasurementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ChangeNotifierProvider creates an instance of MeasurementsViewModel.
    // It makes the ViewModel available to the widget tree below it.
    return ChangeNotifierProvider(
      create: (_) => MeasurementsViewModel(
        repository: MeasurementRepositoryImpl(), // Inject the repository implementation
      ),
      child: const _MeasurementsView(), // The actual UI widget
    );
  }
}

// Define the UI widget as a StatefulWidget because it has local state (text controllers).
class _MeasurementsView extends StatefulWidget {
  const _MeasurementsView();

  @override
  State<_MeasurementsView> createState() => _MeasurementsViewState();
}

class _MeasurementsViewState extends State<_MeasurementsView> {
  // Key to identify the form and validate it.
  final _formKey = GlobalKey<FormState>();

  // Local state variables for form inputs.
  MeasurementType _selectedType = MeasurementType.pressure;
  final _valueController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  // Dispose controllers when the widget is removed to free resources.
  @override
  void dispose() {
    _valueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // Function to show the date picker dialog and update the selected date.
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000), // Earliest allowed date
      lastDate: DateTime.now(), // Latest allowed date (today)
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked; // Update state with new date
      });
    }
  }

  // Function handling the save button press.
  Future<void> _saveMeasurement() async {
    // Validate the form fields.
    if (_formKey.currentState!.validate()) {
        // Access the ViewModel using 'read' (one-time access, doesn't listen for updates).
        final viewModel = context.read<MeasurementsViewModel>();
        
        // Parse the value from text to double.
        final value = _valueController.text.isNotEmpty
            ? double.tryParse(_valueController.text)
            : null;

        // Call the addMeasurement method in the ViewModel.
        // NOTE: 'unit' is no longer passed; it is handled automatically by the ViewModel.
        final success = await viewModel.addMeasurement(
          type: _selectedType,
          value: value,
          date: _selectedDate,
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
        );

        // Check if the widget is still in the tree before using context.
        if (!mounted) return;

        if (success) {
          // Show success message.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Measurement Saved')),
          );
          // Go back to the previous screen.
          Navigator.pop(context);
        } else if (viewModel.errorMessage != null) {
           // Show error message from ViewModel.
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${viewModel.errorMessage}')),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the ViewModel to rebuild when notifyListeners is called.
    final viewModel = context.watch<MeasurementsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Measurement'),
      ),
      // specific deprecated_member_use fix was requested by analyze result
      body: viewModel.isLoading 
        ? const Center(child: CircularProgressIndicator()) // Show loader if saving
        : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dropdown for selecting measurement type.
              DropdownButtonFormField<MeasurementType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: MeasurementType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()), // Display name
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
              // Text field for Value.
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: 'Value (Required)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a value';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                     return 'Value must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Custom ink well for Date picking.
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
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
              // Text field for Note.
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              // Save button.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveMeasurement,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
