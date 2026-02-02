import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../presentation/viewmodels/visits_view_model.dart';
import '../../models/visit_model.dart';
import '../../l10n/app_localizations.dart';

class AddVisitScreen extends StatefulWidget {
  final VisitModel? visitToEdit;

  const AddVisitScreen({super.key, this.visitToEdit});

  @override
  State<AddVisitScreen> createState() => _AddVisitScreenState();
}

class _AddVisitScreenState extends State<AddVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _doctorController = TextEditingController();
  final _clinicController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  String? _attachmentPath; // Placeholder for file path/name

  @override
  void initState() {
    super.initState();
    if (widget.visitToEdit != null) {
      final v = widget.visitToEdit!;
      _doctorController.text = v.doctorName;
      _clinicController.text = v.clinicName ?? '';
      _specialtyController.text = v.specialty ?? '';
      _notesController.text = v.notes ?? '';
      _selectedDate = v.visitDate;
      _attachmentPath = v.attachmentUrl; 
    }
  }

  @override
  void dispose() {
    _doctorController.dispose();
    _clinicController.dispose();
    _specialtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)), // Future visits allowed
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'pdf', 'png', 'jpeg'],
    );

    if (result != null) {
      setState(() {
        _attachmentPath = result.files.single.name; 
        // In real app, we would upload file here or get path to upload on save
      });
    }
  }

  Future<void> _saveVisit() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<VisitsViewModel>();
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User not found")));
      return;
    }

    final newVisit = VisitModel(
      id: widget.visitToEdit?.id,
      userId: user.uid,
      doctorName: _doctorController.text,
      visitDate: _selectedDate,
      clinicName: _clinicController.text.isNotEmpty ? _clinicController.text : null,
      specialty: _specialtyController.text.isNotEmpty ? _specialtyController.text : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      attachmentUrl: _attachmentPath, 
      createdAt: widget.visitToEdit?.createdAt ?? DateTime.now(),
    );

    try {
      if (widget.visitToEdit != null) {
        await viewModel.updateVisit(newVisit);
      } else {
        await viewModel.addVisit(newVisit);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<VisitsViewModel>(); // Watch VM for loading state
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.visitToEdit != null ? loc.translate('edit_visit') : loc.translate('add_visit')),
      ),
      body: viewModel.isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Doctor *
                  TextFormField(
                    controller: _doctorController,
                    decoration: InputDecoration(
                      labelText: loc.translate('doctor_name'),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    validator: (v) => v == null || v.isEmpty ? loc.translate('required') : null,
                  ),
                  const SizedBox(height: 16),

                  // Specialty
                  TextFormField(
                    controller: _specialtyController,
                    decoration: InputDecoration(
                      labelText: loc.translate('specialty_hint'),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.category),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Clinic
                  TextFormField(
                    controller: _clinicController,
                    decoration: InputDecoration(
                      labelText: loc.translate('clinic_hint'),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.local_hospital),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: loc.translate('visit_date'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      child: Text(DateFormat.yMMMMEEEEd().format(_selectedDate)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: loc.translate('notes'),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.note),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Attachment
                  InkWell(
                    onTap: _pickFile,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: loc.translate('attachment'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.attach_file),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _attachmentPath ?? loc.translate('attach_file'),
                              style: TextStyle(
                                color: _attachmentPath == null ? Theme.of(context).hintColor : Theme.of(context).textTheme.bodyMedium?.color,
                                fontWeight: _attachmentPath == null ? FontWeight.normal : FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_attachmentPath != null)
                             IconButton(
                               icon: Icon(Icons.close, size: 18, color: Theme.of(context).colorScheme.error), 
                               onPressed: () => setState(() => _attachmentPath = null),
                               constraints: const BoxConstraints(),
                               padding: EdgeInsets.zero,
                             ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveVisit,
                      icon: const Icon(Icons.save),
                      label: Text(loc.translate('save_visit')),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
