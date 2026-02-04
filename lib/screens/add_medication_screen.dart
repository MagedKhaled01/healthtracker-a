import 'package:flutter/material.dart';
import '../viewmodels/medication_view_model.dart';
import '../models/medication_model.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';

class AddMedicationScreen extends StatefulWidget {
  final Medication? medicationToEdit;

  const AddMedicationScreen({super.key, this.medicationToEdit});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController(); 
  final _durationController = TextEditingController(); // Numeric input for days

  final _viewModel = MedicationViewModel(); 

  late TabController _tabController;
  
  // Shared state
  DateTime _startDate = DateTime.now();
  String _intakeRule = 'none';
  bool _isOngoing = false;

  // Quick Add State
  String _frequency = '1x'; 
  TimeOfDay _firstDoseTime = const TimeOfDay(hour: 8, minute: 0);

  // Advanced Add State
  List<TimeOfDay> _advancedDoseTimes = [const TimeOfDay(hour: 8, minute: 0)];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    if (widget.medicationToEdit != null) {
      final med = widget.medicationToEdit!;
      _nameController.text = med.name;
      _dosageController.text = med.dosage ?? '';
      _startDate = med.startDate;
      _intakeRule = med.intakeRule;
      _frequency = med.frequency;
      
      if (med.endDate == null) {
        _isOngoing = true;
      } else {
        _isOngoing = false;
        final days = med.endDate!.difference(med.startDate).inDays;
        _durationController.text = days.toString();
      }

      if (med.timeMode == 'advanced') {
        _tabController.index = 1;
        _advancedDoseTimes = med.doseTimes.map((t) {
           final parts = t.split(':');
           return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }).toList();
      } else {
        _tabController.index = 0;
        // Try to infer first dose time from the list (if exists)
        if (med.doseTimes.isNotEmpty) {
           final parts = med.doseTimes.first.split(':');
           _firstDoseTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _durationController.dispose();
    _tabController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final isQuick = _tabController.index == 0;
      
      List<TimeOfDay> finalDoseTimes = [];
      if (isQuick) {
        finalDoseTimes = [_firstDoseTime]; 
      } else {
        finalDoseTimes = _advancedDoseTimes;
      }

      int? durationDays;
      if (!_isOngoing && _durationController.text.isNotEmpty) {
        durationDays = int.tryParse(_durationController.text);
      }

      bool success;
      if (widget.medicationToEdit != null) {
        success = await _viewModel.updateMedication(
          id: widget.medicationToEdit!.id!,
          previousDoseTimes: widget.medicationToEdit!.doseTimes,
          name: _nameController.text.trim(),
          dosage: _dosageController.text.trim().isEmpty ? null : _dosageController.text.trim(),
          frequency: isQuick ? _frequency : 'Custom',
          doseTimes: finalDoseTimes,
          timeMode: isQuick ? 'simple' : 'advanced',
          startDate: _startDate,
          intakeRule: _intakeRule,
          durationDays: durationDays,
          createdAt: widget.medicationToEdit!.createdAt,
        );
      } else {
        success = await _viewModel.addMedication(
          name: _nameController.text.trim(),
          dosage: _dosageController.text.trim().isEmpty ? null : _dosageController.text.trim(),
          frequency: isQuick ? _frequency : 'Custom',
          doseTimes: finalDoseTimes,
          timeMode: isQuick ? 'simple' : 'advanced',
          startDate: _startDate,
          intakeRule: _intakeRule,
          durationDays: durationDays,
        );
      }

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

  Future<void> _pickTime(ValueChanged<TimeOfDay> onPicked, TimeOfDay initial) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medicationToEdit != null ? loc.translate('edit_medication') : loc.translate('add_medication')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: loc.translate('quick_add')),
            Tab(text: loc.translate('advanced')),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, child) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24.0),
                  children: [
                // Shared Fields
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: loc.translate('medication_name'), border: const OutlineInputBorder()),
                  validator: (val) => val == null || val.trim().isEmpty ? loc.translate('required') : null,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _dosageController,
                  decoration: InputDecoration(labelText: loc.translate('dosage_optional'), hintText: loc.translate('dosage_hint'), border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: InputDecoration(labelText: loc.translate('start_date'), border: const OutlineInputBorder(), suffixIcon: const Icon(Icons.calendar_today)),
                          child: Text(DateFormat.yMMMd().format(_startDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InputDecorator(
                         decoration: InputDecoration(labelText: loc.translate('duration'), border: const OutlineInputBorder()),
                         child: Row(
                           children: [
                             Checkbox(
                               value: _isOngoing, 
                               onChanged: (v) => setState(() => _isOngoing = v!),
                             ),
                             Text(loc.translate('ongoing')),
                           ],
                         ),
                      ),
                    ),
                  ],
                ),
                if (!_isOngoing) ...[
                   const SizedBox(height: 16),
                   TextFormField(
                     controller: _durationController,
                     keyboardType: TextInputType.number,
                     decoration: InputDecoration(labelText: loc.translate('duration_days'), hintText: loc.translate('duration_hint'), border: const OutlineInputBorder()),
                     validator: (val) => !_isOngoing && (val == null || val.isEmpty) ? loc.translate('required') : null,
                   ),
                ],

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Tab Specific Content
                SizedBox(
                  height: 400, // Fixed height for tab content area or use constrained box
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildQuickAdd(loc),
                      _buildAdvancedAdd(loc),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _viewModel.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).brightness == Brightness.light ? Colors.black : null,
                      foregroundColor: Theme.of(context).brightness == Brightness.light ? Colors.white : null,
                    ),
                    child: _viewModel.isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : Text(widget.medicationToEdit != null ? loc.translate('update_medication') : loc.translate('save_medication')),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
        },
      ),
    );
  }

  Widget _buildQuickAdd(AppLocalizations loc) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(loc.translate('frequency'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            children: ['1x', '2x', '3x', 'PRN'].map((freq) {
              return ChoiceChip(
                label: Text(freq == 'PRN' ? loc.translate('as_needed') : freq),
                selected: _frequency == freq,
                onSelected: (selected) {
                  if (selected) setState(() => _frequency = freq);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          
          if (_frequency != 'PRN') ...[
            Text(loc.translate('first_dose_time'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ListTile(
               title: Text(_firstDoseTime.format(context)),
               trailing: const Icon(Icons.access_time),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.grey)),
               onTap: () => _pickTime((t) => setState(() => _firstDoseTime = t), _firstDoseTime),
            ),
            const SizedBox(height: 8),
            Text(
              _frequency == '1x' ? loc.translate('reminder_daily') : 
              _frequency == '2x' ? loc.translate('reminder_2x') : 
              _frequency == '3x' ? loc.translate('reminder_3x') : '',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
          
          const SizedBox(height: 24),
          _buildIntakeRule(loc),
        ],
      ),
    );
  }

  Widget _buildAdvancedAdd(AppLocalizations loc) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(loc.translate('dose_times'), style: Theme.of(context).textTheme.titleMedium),
              IconButton(onPressed: () => setState(() => _advancedDoseTimes.add(const TimeOfDay(hour: 8, minute: 0))), icon: const Icon(Icons.add_circle)),
            ],
          ),
          ..._advancedDoseTimes.asMap().entries.map((entry) {
             final index = entry.key;
             final time = entry.value;
             return ListTile(
               title: Text(time.format(context)),
               trailing: IconButton(
                 icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                 onPressed: () => setState(() => _advancedDoseTimes.removeAt(index)),
               ),
               onTap: () => _pickTime((t) => setState(() => _advancedDoseTimes[index] = t), time),
             );
          }),
           const SizedBox(height: 24),
          _buildIntakeRule(loc),
        ],
      ),
    );
  }

  Widget _buildIntakeRule(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.translate('instructions_optional'), style: Theme.of(context).textTheme.titleMedium),
        DropdownButtonFormField<String>(
          value: _intakeRule,
          items: [
            DropdownMenuItem(value: 'none', child: Text(loc.translate('instruction_none'))),
            DropdownMenuItem(value: 'before_food', child: Text(loc.translate('instruction_before_food'))),
            DropdownMenuItem(value: 'after_food', child: Text(loc.translate('instruction_after_food'))),
          ],
          onChanged: (val) => setState(() => _intakeRule = val!),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ],
    );
  }
}
