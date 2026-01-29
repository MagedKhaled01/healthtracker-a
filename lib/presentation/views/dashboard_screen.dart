
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/dashboard_view_model.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../data/repositories/measurement_repository_impl.dart';
import 'measurements_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardViewModel(
        profileRepository: ProfileRepositoryImpl(),
        measurementRepository: MeasurementRepositoryImpl(),
      )..loadDashboardData(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hello, ${viewModel.profile?.name ?? "Guest"}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => viewModel.loadDashboardData(),
          ),
        ],
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => viewModel.loadDashboardData(),
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Summary Cards Grid
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.4,
                    children: [
                      _SummaryCard(
                        title: 'BMI',
                        value: viewModel.bmi?.toStringAsFixed(1) ?? '--',
                        unit: '',
                        icon: Icons.accessibility_new,
                        color: Colors.purple.shade100,
                      ),
                      _SummaryCard(
                        title: 'Weight',
                        value: viewModel.currentWeight?.toStringAsFixed(1) ?? '--',
                        unit: 'kg',
                        icon: Icons.monitor_weight,
                        color: Colors.blue.shade100,
                      ),
                      _SummaryCard(
                        title: 'Pressure',
                        value: viewModel.latestPressure?.value?.toStringAsFixed(0) ?? '--',
                        unit: 'mmHg',
                        icon: Icons.favorite,
                        color: Colors.red.shade100,
                      ),
                      _SummaryCard(
                        title: 'Sugar',
                        value: viewModel.latestSugar?.value?.toStringAsFixed(0) ?? '--',
                        unit: 'mg/dL',
                        icon: Icons.bloodtype,
                        color: Colors.orange.shade100,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Today's Medications (Mock)
                  Text(
                    "Today",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHighest,
                    child: const ListTile(
                      leading: Icon(Icons.medication),
                      title: Text('Vitamin D'),
                      subtitle: Text('10:00 AM - Take 1 pill'),
                      trailing: Icon(Icons.check_circle_outline),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Actions Grid
                  Text(
                    "Actions",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 3, // Smaller cards for actions
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _ActionCard(
                        title: 'Measurements',
                        icon: Icons.add_chart,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MeasurementsScreen()),
                          ).then((_) => viewModel.loadDashboardData()); // Refresh on return
                        },
                      ),
                      _ActionCard(
                        title: 'Medications',
                        icon: Icons.medication_liquid,
                        onTap: () {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming Soon')));
                        },
                      ),
                      _ActionCard(
                        title: 'Tests',
                        icon: Icons.science,
                         onTap: () {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming Soon')));
                        },
                      ),
                       _ActionCard(
                        title: 'Visits',
                        icon: Icons.local_hospital,
                         onTap: () {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming Soon')));
                        },
                      ),
                       _ActionCard(
                        title: 'History',
                        icon: Icons.history,
                         onTap: () {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming Soon')));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Icon(icon, size: 20, color: Colors.black54),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                if (unit.isNotEmpty)
                  Text(unit, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
