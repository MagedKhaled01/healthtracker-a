import 'package:flutter/material.dart';
import '../viewmodels/medication_view_model.dart';
import '../models/medication_model.dart';
import 'add_medication_screen.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

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
    return Scaffold(
      appBar: AppBar(title: const Text('My Medications')),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, child) {
          if (_viewModel.isLoading && _viewModel.medications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_viewModel.medications.isEmpty) {
            return const Center(child: Text('No medications added yet.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection('Morning', _viewModel.morningMedications),
              _buildSection('Afternoon', _viewModel.afternoonMedications),
              _buildSection('Evening', _viewModel.eveningMedications),
              _buildSection('As Needed (PRN)', _viewModel.prnMedications, isPrn: true),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSection(String title, List<Medication> meds, {bool isPrn = false}) {
    if (meds.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            title, 
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold
            )
          ),
        ),
        ...meds.map((med) {
           final isTaken = isPrn ? false : med.isTaken(DateTime.now(), title);
           if (isTaken) {
             // Request: "When user marks as taken, it should be removed immediately from Pending list... 
             // ... Instead allow swipe right to delete from main list".
             // Interpretation: The main list (this screen) shows ALL medications (Schedule).
             // Pending list is on Dashboard.
             // Wait, user said: "When the user marks a medication as “Taken”, it should: Be removed immediately from the Today/Pending list. Remove the circular check icon."
             // This suggests that on THIS screen, we might just show standard list items, and "Pending" is a dashboard concept?
             // OR "Today / Pending list" refers to a section on THIS screen?
             // Usually "Medications Screen" is the "Manage" screen. "Dashboard" is the "Action" screen.
             // User said: "Swipe right should permanently remove the medication".
             // So this screen is likely the "Manage / Full List" screen.
           }
           
           // We will show all configured medications here.
           // User asked to "Remove the circular check icon".
           // User asked to "Allow swipe right to delete".
           
           return Dismissible(
             key: Key('${med.id}_$title'), // Unique key per slot entry if possible, or just med.id
             direction: DismissDirection.startToEnd, // Swipe Right
             background: Container(
               color: Colors.red,
               alignment: Alignment.centerLeft,
               padding: const EdgeInsets.only(left: 20),
               child: const Icon(Icons.delete, color: Colors.white),
             ),
             confirmDismiss: (direction) async {
               return await showDialog(
                 context: context,
                 builder: (ctx) => AlertDialog(
                   title: const Text('Delete Medication?'),
                   content: const Text('This will permanently remove this medication schedule.'),
                   actions: [
                     TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                     TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                   ],
                 ),
               );
             },
             onDismissed: (direction) {
               _viewModel.deleteMedication(med.id!);
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Medication deleted')),
               );
             },
             child: Card(
               margin: const EdgeInsets.only(bottom: 8),
               child: ListTile(
                 leading: const Icon(Icons.medication),
                 title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                 subtitle: Text(
                   med.dosage != null && med.dosage!.isNotEmpty 
                     ? '${med.dosage} • ${med.intakeRule.replaceAll('_', ' ')}'
                     : med.intakeRule.replaceAll('_', ' '),
                 ),
                 // No trailing check icon as requested.
                 // This screen is for managing the list.
                 // Adherence is done on Dashboard? Or maybe tap to take?
                 // User said: "Remove the circular check icon." and "Taken medications should never appear again on the Dashboard".
                 // This implies THIS screen is for management (CRUD), Dashboard is for adherence.
                 // But wait, "When the user marks a medication as “Taken”..." - WHERE do they mark it?
                 // Possibly on the Dashboard Action Cards?
                 // Or maybe we keep a "Take" button here but separate from "Check icon"?
                 // Let's assume Dashboard is the primary place for "Taking" today's meds, 
                 // and this screen is "My Schedule".
                 // However, "Tap to Take" is useful. I'll add a simple trailing "Take" text button if not taken?
                 // Or just leave it as management only. The prompt says "Remove the circular check icon... instead allow swipe right to delete". 
                 // So "Delete" replaces "Check" in terms of gesture/visuals here.
                 // Taking is likely done on Dashboard.
                 // I will add a modest "Take" action just in case, or rely on Dashboard.
                 // Given "Dashboard should only show pending...", that is the place to take.
               ),
             ),
           );
        }),
      ],
    );
  }
}
