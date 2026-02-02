import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/visit_model.dart';
import '../../presentation/viewmodels/visits_view_model.dart';
import 'add_visit_screen.dart';
import '../../l10n/app_localizations.dart';

class VisitDetailsScreen extends StatelessWidget {
  final VisitModel visit;

  const VisitDetailsScreen({super.key, required this.visit});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('visit_details')),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
               Navigator.pushReplacement(
                 context,
                 MaterialPageRoute(builder: (_) => AddVisitScreen(visitToEdit: visit)),
               );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
               final confirm = await showDialog<bool>(
                 context: context,
                 builder: (ctx) => AlertDialog(
                   title: Text(loc.translate('delete_visit')),
                   content: Text(loc.translate('cannot_be_undone')),
                   actions: [
                     TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.translate('cancel'))),
                     TextButton(
                       onPressed: () => Navigator.pop(ctx, true), 
                       style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                       child: Text(loc.translate('delete'))
                     ),
                   ],
                 ),
               );
               
               if (confirm == true && visit.id != null) {
                 if (context.mounted) {
                   await context.read<VisitsViewModel>().deleteVisit(visit.id!);
                   if (context.mounted) Navigator.pop(context);
                 }
               }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.local_hospital, size: 32, color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.doctorName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (visit.specialty != null)
                        Text(
                          visit.specialty!,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMMEEEEd(Localizations.localeOf(context).toString()).format(visit.visitDate),
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Clinic
            if (visit.clinicName != null) ...[
              _DetailItem(
                 label: loc.translate('clinic_hospital'),
                 content: visit.clinicName!,
                 icon: Icons.location_on,
              ),
              const SizedBox(height: 24),
            ],
            
            // Notes
             _DetailItem(
               label: loc.translate('notes'),
               content: visit.notes ?? loc.translate('no_notes'),
               icon: Icons.note,
               isMultiLine: true,
            ),
            const SizedBox(height: 24),
            
            // Attachment
            if (visit.attachmentUrl != null) ...[
               Text(loc.translate('attachment'), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant)),
               const SizedBox(height: 8),
               Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                   borderRadius: BorderRadius.circular(8),
                   color: Theme.of(context).colorScheme.surfaceContainerLow,
                 ),
                 child: Row(
                   children: [
                     Icon(Icons.attach_file, color: Theme.of(context).colorScheme.primary),
                     const SizedBox(width: 12),
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             visit.attachmentUrl!, // Just showing name/path placeholder
                             style: const TextStyle(fontWeight: FontWeight.bold),
                             overflow: TextOverflow.ellipsis,
                           ),
                           const SizedBox(height: 2),
                            Text(loc.translate('file_attachment'), style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                         ],
                       ),
                     ),
                   ],
                 ),
               ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String content;
  final IconData icon;
  final bool isMultiLine;

  const _DetailItem({
    required this.label,
    required this.content,
    required this.icon,
    this.isMultiLine = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                content, 
                style: const TextStyle(
                  fontSize: 16, 
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
