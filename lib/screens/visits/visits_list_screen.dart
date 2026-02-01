import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../presentation/viewmodels/visits_view_model.dart';
import '../../models/visit_model.dart';
import 'add_visit_screen.dart';
import 'visit_details_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/auth_guard.dart';

class VisitsListScreen extends StatefulWidget {
  final bool isTab;
  const VisitsListScreen({super.key, this.isTab = false});

  @override
  State<VisitsListScreen> createState() => _VisitsListScreenState();
}

class _VisitsListScreenState extends State<VisitsListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid provider issues during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VisitsViewModel>().loadVisits();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Consumer<VisitsViewModel>(
      builder: (context, vm, child) {
        final isSelection = vm.isSelectionMode;
        final selectedCount = vm.selectedCount;

        return Scaffold(
          appBar: isSelection
           ? AppBar(
               leading: IconButton(
                 icon: const Icon(Icons.close),
                 onPressed: () => vm.clearSelection(),
               ),
               title: Text("$selectedCount ${loc.translate('selected')}"),
               backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
               actions: [
                 if (selectedCount == 1)
                   IconButton(
                     icon: const Icon(Icons.edit),
                     onPressed: () => AuthGuard.protect(context, () {
                        final id = vm.selectedIds.first;
                        final visit = vm.visits.firstWhere((v) => v.id == id);
                        vm.clearSelection();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AddVisitScreen(visitToEdit: visit)),
                        ).then((_) => vm.loadVisits());
                     }),
                   ),
                 IconButton(
                   icon: const Icon(Icons.delete),
                   onPressed: () => AuthGuard.protect(context, () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(loc.translate('delete')),
                          content: Text(loc.translate('delete_record')),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.translate('cancel'))),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.translate('delete'))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        for (var id in vm.selectedIds.toList()) {
                           await vm.deleteVisit(id);
                        }
                        vm.clearSelection();
                        vm.loadVisits(); // Reload to refresh list
                      }
                   }),
                 ),
               ],
             )
           : (widget.isTab ? null : AppBar(title: Text(loc.translate('my_visits')))),
             
          body: Column(
            children: [
               if (!isSelection)
               Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: loc.translate('search_visit_hint'),
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      ),
                      onChanged: (val) => vm.searchVisits(val),
                    ),
                    const SizedBox(height: 12),
                    if (vm.availableSpecialties.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: vm.availableSpecialties.map((specialty) {
                            final isSelected = vm.selectedSpecialties.contains(specialty);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: FilterChip(
                                label: Text(specialty),
                                selected: isSelected,
                                onSelected: (_) => vm.toggleSpecialtyFilter(specialty),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),

              Expanded(
                child: vm.isLoading 
                  ? const Center(child: CircularProgressIndicator()) 
                  : vm.visits.isEmpty 
                    ? _buildEmptyState(context, vm, loc)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: vm.visits.length + (isSelection ? 0 : 40), // Padding
                        itemBuilder: (context, index) {
                          if (index >= vm.visits.length) return const SizedBox(height: 10);
                          final visit = vm.visits[index];
                          return _buildVisitCard(context, visit, vm);
                        },
                      ),
              ),
            ],
          ),
          
          floatingActionButton: isSelection
            ? null
            : FloatingActionButton.extended(
                onPressed: () => AuthGuard.protect(context, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddVisitScreen()),
                  ).then((_) => vm.loadVisits());
                }),
                label: Text(loc.translate('add_visit')),
                icon: const Icon(Icons.add),
              ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, VisitsViewModel vm, AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty ? loc.translate('no_visits_found') : loc.translate('no_visits_yet'),
            style: TextStyle(color: Colors.grey.shade600),
          ),
          if (vm.selectedSpecialties.isNotEmpty)
             TextButton(
               onPressed: () => vm.clearFilters(), 
               child: Text(loc.translate('clear_filters'))
             ),
        ],
      ),
    );
  }

  Widget _buildVisitCard(BuildContext context, VisitModel visit, VisitsViewModel vm) {
    final isSelection = vm.isSelectionMode;
    final isSelected = vm.isSelected(visit.id!);
    
    return Card(
      elevation: isSelected ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), 
        side: isSelected ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2) : BorderSide(color: Colors.grey.shade200)
      ),
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4) : null,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (isSelection) {
            vm.toggleSelection(visit.id!);
          } else {
            Navigator.push(
               context, 
               MaterialPageRoute(builder: (_) => VisitDetailsScreen(visit: visit))
            ).then((_) => vm.loadVisits());
          }
        },
        onLongPress: () => vm.toggleSelection(visit.id!),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat.d(Localizations.localeOf(context).toString()).format(visit.visitDate), 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 20, 
                        color: Theme.of(context).colorScheme.primary
                      )
                    ),
                    Text(
                      DateFormat.MMM(Localizations.localeOf(context).toString()).format(visit.visitDate).toUpperCase(),
                      style: TextStyle(
                         fontSize: 12,
                         fontWeight: FontWeight.bold,
                         color: Theme.of(context).colorScheme.primary
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visit.doctorName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (visit.specialty != null)
                      Text(
                        visit.specialty!,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    const SizedBox(height: 4),
                    if (visit.clinicName != null)
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              visit.clinicName!,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (isSelection)
                Checkbox(
                  value: isSelected,
                  onChanged: (v) => vm.toggleSelection(visit.id!),
                )
            ],
          ),
        ),
      ),
    );
  }
}
