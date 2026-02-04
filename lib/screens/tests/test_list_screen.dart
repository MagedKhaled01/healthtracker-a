import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/test_view_model.dart';
import '../../models/test_model.dart';
import 'add_test_screen.dart';
import 'test_details_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/auth_guard.dart';

class TestListScreen extends StatefulWidget {
  final bool isTab; // To adjust AppBar if needed
  
  const TestListScreen({super.key, this.isTab = false});

  @override
  State<TestListScreen> createState() => _TestListScreenState();
}

class _TestListScreenState extends State<TestListScreen> {
  final _viewModel = TestViewModel();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel.loadTests();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<TestViewModel>(
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
                  title: Text("$selectedCount ${loc.translate('selected')}", style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Seamless
                  iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
                  actions: [
                    if (selectedCount == 1)
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => AuthGuard.protect(context, () {
                           final id = vm.selectedIds.first;
                           final test = vm.tests.firstWhere((t) => t.id == id);
                           vm.clearSelection();
                           Navigator.push(
                             context,
                             MaterialPageRoute(builder: (_) => AddTestScreen(testToEdit: test)),
                           ).then((_) => vm.loadTests());
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
                              final test = vm.tests.firstWhere((t) => t.id == id, orElse: () => TestModel(id: '', userId: '', testName: '', testDate: DateTime.now(), createdAt: DateTime.now()));
                              if (test.id?.isNotEmpty == true) {
                                await vm.deleteTest(id, test.attachmentUrl);
                              }
                           }
                           vm.clearSelection();
                           vm.loadTests(); 
                         }
                      }),
                    ),
                  ],
                )
              : (widget.isTab ? null : AppBar(title: Text(loc.translate('my_tests')))),
            
            body: SafeArea(
              child: Column(
                children: [
                  // Header & Search
                  // Hide/Disable search in selection mode
                  if (!isSelection)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: loc.translate('search_test_hint'),
                              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                              prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                 borderRadius: BorderRadius.circular(30),
                                 borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                 borderRadius: BorderRadius.circular(30),
                                 borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            ),
                            onChanged: (val) => vm.searchTests(val),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // List
                  Expanded(
                    child: vm.isLoading && vm.tests.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : vm.tests.isEmpty
                        ? Center(
                             child: Column(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                 Icon(Icons.assignment_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                                 const SizedBox(height: 16),
                                 Text(
                                   _searchController.text.isNotEmpty ? loc.translate('no_matches_found') : loc.translate('no_tests_yet'),
                                   style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                 ),
                               ],
                             ),
                           )
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 500,
                              mainAxisExtent: 140, 
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: vm.tests.length,
                            itemBuilder: (context, index) {
                              final test = vm.tests[index];
                              return _buildTestCard(context, test, vm);
                            },
                          ),
                  ),
                ],
              ),
            ),
            floatingActionButton: isSelection 
              ? null 
              : FloatingActionButton(
                  shape: const CircleBorder(),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddTestScreen()),
                    ).then((_) => vm.loadTests()); 
                  },
                  child: const Icon(Icons.add),
                ),
          );
        },
      ),
    );
  }

  Widget _buildTestCard(BuildContext context, TestModel test, TestViewModel vm) {
    // Use device locale for formatting
    final locale = Localizations.localeOf(context).toString();
    final dateStr = DateFormat.yMMMd(locale).format(test.testDate);
    
    final isSelection = vm.isSelectionMode;
    // Check if test can be selected (has ID)
    final hasId = test.id != null;
    final isSelected = hasId && vm.isSelected(test.id!);

    return Card(
      elevation: isSelected ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), 
        side: isSelected 
          ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2) 
          : BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2))
      ),
      color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15) : Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (isSelection) {
            if (hasId) vm.toggleSelection(test.id!);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TestDetailsScreen(test: test)),
            );
          }
        },
        onLongPress: () {
          if (hasId) vm.toggleSelection(test.id!);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.science, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.testName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (test.result != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    test.result!,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              if (!isSelection) ...[
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ],
              if (isSelection && hasId)
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
                  size: 24,
                )
            ],
          ),
        ),
      ),
    );
  }
}
