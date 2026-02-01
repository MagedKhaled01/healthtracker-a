import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/test_view_model.dart';
import '../../models/test_model.dart';
import 'add_test_screen.dart';
import 'test_details_screen.dart';
import '../../l10n/app_localizations.dart';

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
      child: Scaffold(
        appBar: widget.isTab ? null : AppBar(title: Text(loc.translate('my_tests'))),
        body: SafeArea(
          child: Column(
            children: [
              // Header & Search
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: loc.translate('search_test_hint'),
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      ),
                      onChanged: (val) => _viewModel.searchTests(val),
                    ),
                  ],
                ),
              ),
              
              // List
              Expanded(
                child: Consumer<TestViewModel>(
                  builder: (context, vm, child) {
                    if (vm.isLoading && vm.tests.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (vm.tests.isEmpty) {
                       return Center(
                         child: Column(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
                             const SizedBox(height: 16),
                             Text(
                               _searchController.text.isNotEmpty ? loc.translate('no_matches_found') : loc.translate('no_tests_yet'),
                               style: TextStyle(color: Colors.grey.shade600),
                             ),
                           ],
                         ),
                       );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: vm.tests.length,
                      itemBuilder: (context, index) {
                        final test = vm.tests[index];
                        return _buildTestCard(context, test);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddTestScreen()),
            ).then((_) => _viewModel.loadTests()); // Refresh if needed (though stream handles it)
          },
          label: Text(loc.translate('add_test')),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildTestCard(BuildContext context, TestModel test) {
    // Use device locale for formatting
    final locale = Localizations.localeOf(context).toString();
    final dateStr = DateFormat.yMMMd(locale).format(test.testDate);
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TestDetailsScreen(test: test)),
          );
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
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
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
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
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
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddTestScreen(testToEdit: test)),
                  ).then((_) => _viewModel.loadTests());
                },
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
