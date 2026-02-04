import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/dashboard_view_model.dart';
import '../../viewmodels/medication_view_model.dart';
import '../../presentation/viewmodels/visits_view_model.dart'; // Import Visits VM
import '../../data/repositories/profile_repository_impl.dart';
import '../../data/repositories/measurement_repository_impl.dart';
import 'measurements_screen.dart';
import '../../screens/medications_screen.dart';
import '../../screens/profile_screen.dart';
import '../../services/notification_service.dart';
import '../../screens/tests/test_list_screen.dart';
import '../../screens/visits/visits_list_screen.dart'; // Import Visits Screen
import '../../l10n/app_localizations.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load dashboard data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardViewModel>().loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const _DashboardShell();
  }
}

class _DashboardShell extends StatefulWidget {
  const _DashboardShell();

  @override
  State<_DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<_DashboardShell> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // Pages
  // 0: Home (Dashboard)
  // 1: Medications
  // 2: Tests (Replaces Visits)
  // 3: Measurements
  // 4: Profile

  @override
  void initState() {
    super.initState();
    // Request notification permissions after login/dashboard load
    WidgetsBinding.instance.addPostFrameCallback((_) {
       NotificationService.instance.requestPermissions();
    });
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    if (index == 0) {
      context.read<DashboardViewModel>().loadDashboardData();
    }
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    if (index == 0) {
      context.read<DashboardViewModel>().loadDashboardData();
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    // 0: Home, 1: Meds, 2: Visits, 3: Tests, 4: Measure
    final loc = AppLocalizations.of(context)!;
    
    String getTitle(int index) {
      switch (index) {
        case 0: return loc.translate('app_title');
        case 1: return loc.translate('meds');
        case 2: return loc.translate('visits');
        case 3: return loc.translate('tests');
        case 4: return loc.translate('measure');
        default: return loc.translate('app_title');
      }
    }

    final dashboardVM = context.watch<DashboardViewModel>();

    return Scaffold(
       appBar: AppBar(
        title: _currentIndex == 0 
           ? Text('${loc.translate('hello')}, ${dashboardVM.profile?.name ?? loc.translate('guest')}')
           : Text(getTitle(_currentIndex)),
        actions: [
          // Profile Icon (Global)
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (_) => const ProfileScreen(isTab: false)), // Not a tab anymore
               );
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        // Default physics enables swiping
        children: const [
          _DashboardHomeTab(),
          MedicationsScreen(isTab: true), 
          VisitsListScreen(isTab: true), 
          TestListScreen(isTab: true), 
          MeasurementsScreen(isTab: true), 
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onBottomNavTapped,
        indicatorColor: Colors.transparent, 
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 64,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            selectedIcon: const Icon(Icons.grid_view),
            label: loc.translate('home'), // Reverted to localized
          ),
          NavigationDestination(
            icon: const Icon(Icons.medication_outlined),
            selectedIcon: const Icon(Icons.medication),
            label: loc.translate('meds'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.medical_services_outlined),
            selectedIcon: const Icon(Icons.medical_services),
            label: loc.translate('visits'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.assignment_outlined),
            selectedIcon: const Icon(Icons.assignment),
            label: loc.translate('nav_tests'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.monitor_heart_outlined),
            selectedIcon: const Icon(Icons.monitor_heart),
            label: loc.translate('nav_measure'),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// HOME TAB (Original Dashboard Content Logic)
// -----------------------------------------------------------------------------

class _DashboardHomeTab extends StatefulWidget {
  const _DashboardHomeTab();

  @override
  State<_DashboardHomeTab> createState() => _DashboardHomeTabState();
}

class _DashboardHomeTabState extends State<_DashboardHomeTab> {
  final _medViewModel = MedicationViewModel(); // Local instance for this tab

  @override
  void initState() {
    super.initState();
    _medViewModel.loadMedications();
  }

  @override
  void dispose() {
    _medViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardVM = context.watch<DashboardViewModel>();
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      // AppBar removed here, handled by Shell
      body: dashboardVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  // Tablet/Desktop Layout (Wide)
                  return RefreshIndicator(
                    onRefresh: () async {
                       dashboardVM.loadDashboardData();
                       _medViewModel.loadMedications();
                    },
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32.0),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column: Pending Medications (Priority)
                          Expanded(
                            flex: 3,
                            child: _buildPendingMedicationsSection(context, colorScheme, loc),
                          ),
                          const SizedBox(width: 32),
                          // Right Column: Summary Cards
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                Text(
                                  loc.translate('overview'), // Or similar header
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                _buildSummaryGrid(dashboardVM, loc),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Mobile Layout
                return RefreshIndicator(
                  onRefresh: () async {
                     dashboardVM.loadDashboardData();
                     _medViewModel.loadMedications();
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                       // 1. Pending Medications (Priority)
                      _buildPendingMedicationsSection(context, colorScheme, loc),
                      
                      const SizedBox(height: 24),

                      // 2. Summary Cards
                      _buildSummaryGrid(dashboardVM, loc),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildPendingMedicationsSection(BuildContext context, ColorScheme colorScheme, AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.translate('todays_medications'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MedicationsScreen()),
                ).then((_) => _medViewModel.loadMedications());
              },
              child: Text(loc.translate('manage')),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _medViewModel,
          builder: (context, child) {
            if (_medViewModel.isLoading) {
              return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
            }
            
            final pending = _medViewModel.pendingMedicationsForToday;

            if (pending.isEmpty) {
              return Card(
                 elevation: 0,
                 color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                 margin: EdgeInsets.zero,
                 child: Padding(
                   padding: const EdgeInsets.all(24.0),
                   child: Center(
                     child: Column(
                       children: [
                         const Icon(Icons.check_circle, color: Colors.green, size: 48),
                         const SizedBox(height: 8),
                         Text(loc.translate('all_caught_up'), style: const TextStyle(fontWeight: FontWeight.bold)),
                       ],
                     ),
                   ),
                 ),
              );
            }

            return Column(
              children: pending.take(2).map((entry) {
                 final med = entry['med'] as dynamic; 
                 final slot = entry['slot'] as String;
                 
                 return Dismissible(
                    key: Key('${med.id}_$slot'),
                    background: Container(
                      color: Colors.green,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          const Icon(Icons.check, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(loc.translate('taken'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    direction: DismissDirection.startToEnd,
                    onDismissed: (direction) {
                      _medViewModel.logIntake(med.id!, slot, true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${med.name} ${loc.translate('marked_as_taken')}')),
                      );
                    },
                    child: Card(
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5), // Semi-transparent Slate
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)), // Teal border
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                          child: Icon(Icons.medication, color: colorScheme.primary),
                        ),
                        title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('$slot ${med.dosage != null ? "• ${med.dosage}" : ""}'),
                      ),
                    ),
                  );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummaryGrid(DashboardViewModel viewModel, AppLocalizations loc) {
    String pressureValue = '--';
    if (viewModel.latestPressure?.value != null) {
      pressureValue = viewModel.latestPressure!.value!.toStringAsFixed(0);
      if (viewModel.latestPressure?.value2 != null) {
        pressureValue += '/${viewModel.latestPressure!.value2!.toStringAsFixed(0)}';
      }
    }

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: [
        _SummaryCard(
          title: loc.translate('weight'),
          value: viewModel.currentWeight?.toStringAsFixed(1) ?? '--',
          unit: 'kg',
          icon: Icons.monitor_weight,
          accentColor: const Color(0xFF00BCD4), // Teal/Cyan for Weight
        ),
        _SummaryCard(
          title: loc.translate('bmi'),
          value: viewModel.bmi?.toStringAsFixed(1) ?? '--',
          unit: '',
          icon: Icons.accessibility_new,
          accentColor: Colors.purple.shade300,
        ),
        _SummaryCard(
          title: loc.translate('pressure'),
          value: pressureValue,
          unit: 'mmHg',
          icon: Icons.favorite,
          accentColor: const Color(0xFF009688), // Teal/Green for Pressure (as in image)
        ),
        _SummaryCard(
          title: loc.translate('sugar'),
          value: viewModel.latestSugar?.value?.toStringAsFixed(0) ?? '--',
          unit: 'mg/dL',
          icon: Icons.bloodtype,
          accentColor: Colors.orange, // Orange for Sugar
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color accentColor;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    if (!isDark) {
      // Light Mode (Pastel Style)
      return Card(
        color: accentColor.withValues(alpha: 0.1),
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
                   Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                   Icon(icon, size: 20, color: Colors.black54),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
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

    // Dark Mode (High Contrast Style)
    // Structure:
    // [Icon in box]
    // [Title]
    // [Colored Value] [Unit]
    
    return Card(
      color: Theme.of(context).colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)), // Subtle Teal border
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon in colored box
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: accentColor),
            ),
            const Spacer(),
            Text(
              title, 
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              )
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold, 
                    color: accentColor // Colored Value
                  ),
                ),
                if (unit.isNotEmpty) ...[
                   const SizedBox(width: 4),
                   Text(
                    unit, 
                    style: TextStyle(
                      fontSize: 12, 
                      color: colorScheme.onSurfaceVariant
                    )
                  ),
                ]
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
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
