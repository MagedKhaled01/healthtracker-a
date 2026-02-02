import 'package:flutter/material.dart';
import '../viewmodels/medication_view_model.dart';
import '../models/medication_model.dart';
import 'add_medication_screen.dart';
import '../utils/auth_guard.dart'; // Import AuthGuard
import '../l10n/app_localizations.dart';

class MedicationsScreen extends StatefulWidget {
  final bool isTab;
  const MedicationsScreen({super.key, this.isTab = false});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  final _viewModel = MedicationViewModel(); // Local instance

  @override
  void initState() {
    super.initState();
    _viewModel.loadMedications();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        final isSelection = _viewModel.isSelectionMode;
        final selectedCount = _viewModel.selectedCount;

        return Scaffold(
          appBar: isSelection
            ? AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _viewModel.clearSelection(),
                ),
                title: Text("$selectedCount ${loc.translate('selected')}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Seamless
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  if (selectedCount == 1)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => AuthGuard.protect(context, () {
                         final id = _viewModel.selectedIds.first;
                         final med = _viewModel.medications.firstWhere((m) => m.id == id);
                         _viewModel.clearSelection();
                         Navigator.push(
                           context,
                           MaterialPageRoute(builder: (_) => AddMedicationScreen(medicationToEdit: med)),
                         ).then((_) => _viewModel.loadMedications());
                      }),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => AuthGuard.protect(context, () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(loc.translate('delete')),
                          content: Text(loc.translate('delete_medication_confirm')),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.translate('cancel'))),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.translate('delete'))),
                          ],
                        ),
                      );
                      
                      if (confirm == true) {
                        for (var id in _viewModel.selectedIds.toList()) {
                           await _viewModel.deleteMedication(id);
                        }
                        _viewModel.clearSelection();
                        if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('medication_deleted'))));
                        }
                      }
                    }),
                  ),
                ],
              )
            : (widget.isTab ? null : AppBar(title: Text(loc.translate('my_medications')))),
            
          body: _viewModel.isLoading && _viewModel.medications.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _viewModel.medications.isEmpty
              ? Center(child: Text(loc.translate('no_medications')))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _viewModel.medications.length + 8, // Padding at bottom for FAB
                  itemBuilder: (context, index) {
                    if (index >= _viewModel.medications.length) return const SizedBox(height: 10);
                    
                    final med = _viewModel.medications[index];
                    final isSelected = _viewModel.isSelected(med.id!);
                    
                    return Card(
                      elevation: isSelected ? 4 : 2,
                      color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15) : Theme.of(context).colorScheme.surface, // Cleaner highlight
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isSelected ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2) : BorderSide.none,
                      ),
                      child: InkWell(
                        onTap: () {
                          if (isSelection) {
                            _viewModel.toggleSelection(med.id!);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => AddMedicationScreen(medicationToEdit: med)),
                            ).then((_) => _viewModel.loadMedications());
                          }
                        },
                        onLongPress: () => _viewModel.toggleSelection(med.id!),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.medication, color: isSelected ? Theme.of(context).colorScheme.primary : null),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        if (med.dosage != null)
                                          Text(med.dosage!, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                      ],
                                    ),
                                  ),
                                  if (isSelection)
                                    Icon(
                                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                                      color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
                                      size: 24,
                                    )
                                ],
                              ),
                              
                              if (med.nextDoseAt != null && med.nextDoseAt!.isAfter(DateTime.now()))
                                 Padding(
                                   padding: const EdgeInsets.symmetric(vertical: 4.0),
                                   child: StreamBuilder(
                                     stream: Stream.periodic(const Duration(seconds: 1)),
                                     builder: (context, snapshot) {
                                       final diff = med.nextDoseAt!.difference(DateTime.now());
                                       if (diff.isNegative) return const SizedBox.shrink();
                                       final hours = diff.inHours.toString().padLeft(2, '0');
                                       final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
                                       final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
                                       return Text(
                                         "${loc.translate('next_dose_in')} $hours:$minutes:$seconds", 
                                         style: TextStyle(
                                           color: Theme.of(context).colorScheme.primary,
                                           fontWeight: FontWeight.bold,
                                           fontSize: 12
                                         )
                                       );
                                     }
                                   ),
                                 ),
                              const Divider(),
                              AbsorbPointer(
                                absorbing: isSelection, // Disable interaction in selection mode
                                child: Wrap(
                                  spacing: 8,
                                  children: med.doseTimes.map((time) {
                                     final isTaken = med.isTaken(DateTime.now(), time);
                                     return ActionChip(
                                       label: Text(time),
                                       avatar: Icon(
                                         isTaken ? Icons.check_circle : Icons.circle_outlined, 
                                         size: 16, 
                                         color: isTaken ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.primary
                                       ),
                                       backgroundColor: isTaken ? Theme.of(context).colorScheme.primary : null,
                                       labelStyle: TextStyle(color: isTaken ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface),
                                       side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                                       onPressed: () {
                                         AuthGuard.protect(context, () {
                                            _viewModel.logIntake(med.id!, time, !isTaken);
                                         });
                                       },
                                     );
                                  }).toList(),
                                ),
                              ),
                              if (med.doseTimes.isEmpty && med.frequency == 'PRN')
                                 Padding(
                                   padding: const EdgeInsets.symmetric(vertical: 8.0),
                                   child: Text(loc.translate('prn'), style: TextStyle(fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                 ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          
          floatingActionButton: isSelection
            ? null 
            : FloatingActionButton(
                shape: const CircleBorder(),
                onPressed: () => AuthGuard.protect(context, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
                  ).then((_) => _viewModel.loadMedications());
                }),
                child: const Icon(Icons.add),
              ),
        );
      },
    );
  }
}
