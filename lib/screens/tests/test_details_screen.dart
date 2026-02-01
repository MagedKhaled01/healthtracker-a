import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/test_model.dart';
import '../../viewmodels/test_view_model.dart';
import 'add_test_screen.dart';
import '../../l10n/app_localizations.dart';

class TestDetailsScreen extends StatelessWidget {
  final TestModel test;
  
  const TestDetailsScreen({super.key, required this.test});

  @override
  Widget build(BuildContext context) {
    // We create a viewmodel just for the delete action
    final viewModel = TestViewModel();
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('test_details')),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
               Navigator.pushReplacement(
                 context,
                 MaterialPageRoute(builder: (_) => AddTestScreen(testToEdit: test)),
               );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
               final confirm = await showDialog<bool>(
                 context: context,
                 builder: (ctx) => AlertDialog(
                   title: Text(loc.translate('delete_record')),
                   content: Text(loc.translate('cannot_be_undone')),
                   actions: [
                     TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.translate('cancel'))),
                     TextButton(
                       onPressed: () => Navigator.pop(ctx, true), 
                       style: TextButton.styleFrom(foregroundColor: Colors.red),
                       child: Text(loc.translate('delete'))
                     ),
                   ],
                 ),
               );
               
               if (confirm == true) {
                 await viewModel.deleteTest(test.id!, test.attachmentUrl);
                 if (context.mounted) Navigator.pop(context);
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.science, size: 32, color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        test.testName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMMEEEEd(Localizations.localeOf(context).toString()).format(test.testDate),
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Result
            _DetailItem(
               label: loc.translate('result'),
               content: test.result ?? loc.translate('not_recorded'),
               icon: Icons.analytics,
               isHighlight: test.result != null,
            ),
            const SizedBox(height: 24),
            
            // Notes
             _DetailItem(
               label: loc.translate('notes'),
               content: test.notes ?? loc.translate('no_notes'),
               icon: Icons.note,
               isMultiLine: true,
            ),
            const SizedBox(height: 24),
            
            // Attachment
            if (test.attachmentUrl != null) ...[
               Text(loc.translate('attachment'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
               const SizedBox(height: 8),
               InkWell(
                 onTap: () async {
                   final uri = Uri.parse(test.attachmentUrl!);
                   if (await canLaunchUrl(uri)) {
                     await launchUrl(uri, mode: LaunchMode.externalApplication);
                   } else {
                     if (context.mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text(loc.translate('could_not_open'))),
                       );
                     }
                   }
                 },
                 borderRadius: BorderRadius.circular(8),
                 child: Container(
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                     border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                     borderRadius: BorderRadius.circular(8),
                     color: Theme.of(context).colorScheme.surfaceContainerLow,
                   ),
                   child: Row(
                     children: [
                       Icon(Icons.file_present, color: Theme.of(context).colorScheme.primary),
                       const SizedBox(width: 12),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               loc.translate('view_attachment'),
                               style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                             ),
                             const SizedBox(height: 2),
                             Text(loc.translate('tap_to_open'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                           ],
                         ),
                       ),
                       const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
                     ],
                   ),
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
  final bool isHighlight;
  final bool isMultiLine;

  const _DetailItem({
    required this.label,
    required this.content,
    required this.icon,
    this.isHighlight = false,
    this.isMultiLine = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                content, 
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
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
