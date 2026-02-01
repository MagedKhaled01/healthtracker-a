import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/profile_view_model.dart';
import '../viewmodels/auth_view_model.dart';
import 'settings_screen.dart';
import 'auth_choice_screen.dart';
import '../utils/auth_guard.dart'; // Import AuthGuard
import '../l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  final bool isTab;
  const ProfileScreen({super.key, this.isTab = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Use a local controller for editing state if needed, but VM handles data.
  // For this clean UI, we will just show data and have an 'Edit' dialog or bottom sheet,
  // Or just inline editing enabled by a toggle. Let's do inline editing for simplicity.
  
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _nameController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    
    // Load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ProfileViewModel>();
      vm.loadProfile().then((_) => _syncControllers(vm));
    });
  }

  void _syncControllers(ProfileViewModel vm) {
    _nameController.text = vm.name;
    _heightController.text = vm.height;
    _weightController.text = vm.weight;
    setState(() {
      _selectedGender = vm.gender;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Cancelled edit, reset
        _syncControllers(context.read<ProfileViewModel>());
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final vm = context.read<ProfileViewModel>();
    vm.setName(_nameController.text);
    vm.setHeight(_heightController.text);
    vm.setWeight(_weightController.text);
    vm.setGender(_selectedGender);

    final success = await vm.saveProfile();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated')));
      setState(() => _isEditing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    // final theme = Theme.of(context); // Already defined? checking context
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('profile')),
        automaticallyImplyLeading: !widget.isTab,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const SettingsScreen())
              );
            },
          ),
        ],
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                   // ... Avatar ...
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            vm.name.isNotEmpty ? vm.name[0].toUpperCase() : '?',
                            style: theme.textTheme.displayMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                          ),
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: theme.colorScheme.primary,
                              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Name (Display or Edit)
                  if (_isEditing)
                     Form(
                       key: _formKey,
                       child: Column(
                         children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(labelText: loc.translate('full_name'), prefixIcon: const Icon(Icons.person)),
                              validator: (v) => v!.isEmpty ? loc.translate('required') : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _heightController,
                                    decoration: InputDecoration(labelText: loc.translate('height_cm'), prefixIcon: const Icon(Icons.height)),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _weightController,
                                    decoration: InputDecoration(labelText: loc.translate('weight_kg'), prefixIcon: const Icon(Icons.fitness_center)),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _selectedGender,
                              decoration: InputDecoration(labelText: loc.translate('gender'), prefixIcon: const Icon(Icons.people)),
                              items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(loc.translate(g.toLowerCase())))).toList(),
                              onChanged: (val) => setState(() => _selectedGender = val),
                            ),
                         ],
                       ),
                     )
                   else
                     Column(
                       children: [
                         Text(vm.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                         Text(loc.translate('health_enthusiast'), style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                         const SizedBox(height: 24),
                         // Stats Row
                         Row(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             _StatCard(label: loc.translate('height'), value: '${vm.height} cm', icon: Icons.height),
                             const SizedBox(width: 16),
                             _StatCard(label: loc.translate('weight'), value: '${vm.weight} kg', icon: Icons.line_weight),
                             const SizedBox(width: 16),
                             _StatCard(label: loc.translate('gender'), value: vm.gender ?? '-', icon: Icons.wc),
                           ],
                         ),
                       ],
                     ),
                  
                  const SizedBox(height: 32),
                  
                  // Action Buttons
                  if (_isEditing)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton(onPressed: _toggleEdit, child: Text(loc.translate('cancel'))),
                        FilledButton.icon(
                          onPressed: _save, 
                          icon: const Icon(Icons.save), 
                          label: Text(loc.translate('save_changes'))
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => AuthGuard.protect(context, _toggleEdit),
                        icon: const Icon(Icons.edit),
                        label: Text(loc.translate('edit_profile')),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Logout Button
                  TextButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(loc.translate('logout')),
                          content: Text(loc.translate('logout_confirm')),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.translate('cancel'))),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true), 
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: Text(loc.translate('yes'))
                            ),
                          ],
                        ),
                      );
                      
                      if (confirm == true && context.mounted) {
                        await context.read<AuthViewModel>().signOut();
                        if (context.mounted) {
                           Navigator.of(context).pushAndRemoveUntil(
                             MaterialPageRoute(builder: (_) => const AuthChoiceScreen()),
                             (route) => false,
                           );
                        }
                      }
                    },
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: Text(loc.translate('logout'), style: const TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
