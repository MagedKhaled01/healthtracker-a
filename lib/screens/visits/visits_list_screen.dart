import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../presentation/viewmodels/visits_view_model.dart';
import '../../models/visit_model.dart';
import 'add_visit_screen.dart';
import 'visit_details_screen.dart';
import '../../l10n/app_localizations.dart';

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
    // If it's a tab, we assume Global AppBar handles title, but we might need local controls (search).
    // Actually, keeping the structure similar to TestListScreen where search is part of the body.
    final loc = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: widget.isTab ? null : AppBar(title: Text(loc.translate('my_visits'))),
      body: Consumer<VisitsViewModel>(
        builder: (context, vm, child) {
          return Column(
            children: [
               // Search & Filter Header
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Search Bar
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
                    // Specialty Filters
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

              // List
              Expanded(
                child: vm.isLoading 
                  ? const Center(child: CircularProgressIndicator()) 
                  : vm.visits.isEmpty 
                    ? _buildEmptyState(context, vm, loc)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: vm.visits.length,
                        itemBuilder: (context, index) {
                          final visit = vm.visits[index];
                          return _buildVisitCard(context, visit);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddVisitScreen()),
          );
        },
        label: Text(loc.translate('add_visit')),
        icon: const Icon(Icons.add),
      ),
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

  Widget _buildVisitCard(BuildContext context, VisitModel visit) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
             context, 
             MaterialPageRoute(builder: (_) => VisitDetailsScreen(visit: visit))
          );
        },
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
              Column(
                children: [
                   IconButton(
                    icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                    onPressed: () {
                       Navigator.push(
                         context,
                         MaterialPageRoute(builder: (_) => AddVisitScreen(visitToEdit: visit)),
                       );
                    },
                   ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
