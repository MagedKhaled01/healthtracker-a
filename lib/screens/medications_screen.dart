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
    
    Widget content = AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        if (_viewModel.isLoading && _viewModel.medications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_viewModel.medications.isEmpty) {
          return Center(child: Text(loc.translate('no_medications')));
        }

        final meds = _viewModel.medications;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: meds.length,
          itemBuilder: (context, index) {
            final med = meds[index];
            return Dismissible(
              key: Key(med.id!),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(loc.translate('delete_medication')),
                    content: Text(loc.translate('delete_medication_confirm')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.translate('cancel'))),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.translate('delete'))),
                    ],
                  ),
                );
              },
              onDismissed: (direction) {
                _viewModel.deleteMedication(med.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.translate('medication_deleted'))),
                );
              },
              child: Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.medication),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                if (med.dosage != null)
                                  Text(med.dosage!, style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddMedicationScreen(medicationToEdit: med),
                                ),
                              ).then((_) => _viewModel.loadMedications());
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.grey),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                 context: context,
                                 builder: (ctx) => AlertDialog(
                                   title: Text(loc.translate('delete_medication')),
                                   content: Text(loc.translate('delete_medication_confirm')),
                                   actions: [
                                     TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.translate('cancel'))),
                                     TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.translate('delete'))),
                                   ],
                                 ),
                               );
                               if (confirm == true) _viewModel.deleteMedication(med.id!);
                            },
                          ),
                        ],
                      ),
                      // COUNTDOWN WIDGET using nextDoseAt
                      if (med.nextDoseAt != null && med.nextDoseAt!.isAfter(DateTime.now()))
                         Padding(
                           padding: const EdgeInsets.symmetric(vertical: 4.0),
                           child: StreamBuilder( // Use a simple periodic stream later or just rebuild
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
                      Wrap(
                        spacing: 8,
                        children: med.doseTimes.map((time) {
                           final isTaken = med.isTaken(DateTime.now(), time);
                           return ActionChip(
                             label: Text(time),
                             avatar: Icon(isTaken ? Icons.check_circle : Icons.circle_outlined, size: 16, color: isTaken ? Colors.white : Theme.of(context).colorScheme.primary),
                             backgroundColor: isTaken ? Colors.green : null,
                             labelStyle: TextStyle(color: isTaken ? Colors.white : null),
                             onPressed: () {
                               _viewModel.logIntake(med.id!, time, !isTaken);
                             },
                           );
                        }).toList(),
                      ),
                      if (med.doseTimes.isEmpty && med.frequency == 'PRN')
                         Padding(
                           padding: const EdgeInsets.symmetric(vertical: 8.0),
                           child: Text(loc.translate('prn'), style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                         ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    return Scaffold(
      appBar: widget.isTab ? null : AppBar(title: Text(loc.translate('my_medications'))),
      body: widget.isTab
        ? SafeArea(
            child: content,
          )
        : content,
      floatingActionButton: FloatingActionButton(
        onPressed: () => AuthGuard.protect(context, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
          );
        }),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSection(String title, List<Medication> meds, {bool isPrn = false}) {
     // Deprecated logic
     return const SizedBox.shrink();
  }
}
