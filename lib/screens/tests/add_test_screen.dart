import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../viewmodels/test_view_model.dart';
import '../../models/test_model.dart';
import '../../l10n/app_localizations.dart';

class AddTestScreen extends StatefulWidget {
  final TestModel? testToEdit;
  
  const AddTestScreen({super.key, this.testToEdit});

  @override
  State<AddTestScreen> createState() => _AddTestScreenState();
}

class _AddTestScreenState extends State<AddTestScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _resultController = TextEditingController(); 
  final _notesController = TextEditingController(); 
  
  DateTime _testDate = DateTime.now();
  String? _selectedFilePath;
  String? _selectedFileName;

  final _viewModel = TestViewModel();

  @override
  void initState() {
    super.initState();
    if (widget.testToEdit != null) {
      final t = widget.testToEdit!;
      _nameController.text = t.testName;
      _testDate = t.testDate;
      if (t.result != null) _resultController.text = t.result!;
      if (t.notes != null) _notesController.text = t.notes!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _resultController.dispose();
    _notesController.dispose();
    // _viewModel.dispose(); // ViewModel created locally, but usually provided. 
    // Since we use ChangeNotifierProvider.value locally with a local instance, 
    // the provider might handle disposal or we can do it here if not passed to provider as create.
    // However, ChangeNotifierProvider(create:...) disposes automatically.
    // ChangeNotifierProvider.value does NOT dispose. 
    // Given the structure used below: ChangeNotifierProvider.value(value: _viewModel), we should dispose it.
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _testDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _testDate = picked);
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
         type: FileType.custom,
         allowedExtensions: ['jpg', 'png', 'pdf', 'jpeg'],
      );

      if (result != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      bool success;
      if (widget.testToEdit != null) {
        success = await _viewModel.updateTest(
          id: widget.testToEdit!.id!,
          testName: _nameController.text.trim(),
          testDate: _testDate,
          result: _resultController.text.trim(),
          notes: _notesController.text.trim(),
          attachmentUrl: widget.testToEdit!.attachmentUrl, 
          filePath: _selectedFilePath,
          createdAt: widget.testToEdit!.createdAt,
        );
      } else {
        success = await _viewModel.addTest(
          testName: _nameController.text.trim(),
          testDate: _testDate,
          result: _resultController.text.trim(),
          notes: _notesController.text.trim(),
          filePath: _selectedFilePath,
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.testToEdit != null ? loc.translate('edit_test') : loc.translate('add_test_result')),
      ),
      body: ChangeNotifierProvider.value(
        value: _viewModel,
        child: Consumer<TestViewModel>(
          builder: (context, vm, child) {
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
                      decoration: InputDecoration(
                        labelText: loc.translate('test_name_required'),
                        hintText: 'e.g., Blood Test',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.science_outlined),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? loc.translate('test_name_error') : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Date Picker
                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                           labelText: loc.translate('test_date'),
                           border: const OutlineInputBorder(),
                           prefixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat.yMMMd().format(_testDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Result (Optional)
                    TextFormField(
                      controller: _resultController,
                      decoration: InputDecoration(
                        labelText: loc.translate('result_optional'),
                        hintText: 'e.g., Normal',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.analytics_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notes (Optional)
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                       decoration: InputDecoration(
                        labelText: loc.translate('note_optional'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.note),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Attachment Picker
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
                                _selectedFileName ?? (widget.testToEdit?.attachmentUrl != null ? loc.translate('change_attachment') : loc.translate('attach_pdf_image')),
                                style: TextStyle(
                                  color: _selectedFileName == null ? Theme.of(context).hintColor : Theme.of(context).textTheme.bodyMedium?.color,
                                  fontWeight: _selectedFileName == null ? FontWeight.normal : FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_selectedFileName != null)
                               IconButton(
                                 icon: Icon(Icons.close, size: 18, color: Theme.of(context).colorScheme.error), 
                                 onPressed: () => setState(() {
                                   _selectedFilePath = null;
                                   _selectedFileName = null;
                                 }),
                                 constraints: const BoxConstraints(),
                                 padding: EdgeInsets.zero,
                               ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    // Submit
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: vm.isLoading ? null : _submit,
                        child: vm.isLoading 
                          ? const CircularProgressIndicator()
                          : Text(widget.testToEdit != null ? loc.translate('update_record') : loc.translate('save_record')),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
