
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../presentation/views/dashboard_screen.dart';
import 'profile_form_screen.dart';
import '../services/profile_service.dart';
import '../l10n/app_localizations.dart';

import '../viewmodels/auth_view_model.dart';

class AuthChoiceScreen extends StatefulWidget {
  const AuthChoiceScreen({super.key});

  @override
  State<AuthChoiceScreen> createState() => _AuthChoiceScreenState();
}

class _AuthChoiceScreenState extends State<AuthChoiceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _authService = AuthService();
  final _emailViewModel = AuthViewModel(); // For Email Tab Logic
  bool _isLoading = false;

  // Form Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailViewModel.dispose();
    super.dispose();
  }

  // --- Unified Navigation Logic ---
  Future<void> _checkProfileAndNavigate(User user) async {
    final profileService = ProfileService();
    // Assuming getProfile returns null if no doc checks out
    final profile = await profileService.getProfile(user.uid);

    if (!mounted) return;
    
    if (profile != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileFormScreen()),
      );
    }
  }

  // --- Email Logic ---
  Future<void> _submitEmailForm({required bool isRegister}) async {
    final formKey = isRegister ? _registerFormKey : _loginFormKey;
    if (!formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    bool success;

    if (isRegister) {
      success = await _emailViewModel.registerWithEmail(email, password);
    } else {
      success = await _emailViewModel.loginWithEmail(email, password);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
       final user = FirebaseAuth.instance.currentUser;
       if (user != null) {
         await _checkProfileAndNavigate(user);
       }
    } else if (_emailViewModel.errorMessage != null) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(_emailViewModel.errorMessage!)),
       );
    }
  }

  // --- Social / Other Logic ---
  Future<void> _performGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (!mounted) return;
      if (user != null) {
        await _checkProfileAndNavigate(user);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInAnonymously();
      if (!mounted) return;
      if (user != null) {
         await _checkProfileAndNavigate(user);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: SafeArea(
        child: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              const SizedBox(height: 24),
              // Header
              Text(
                loc.translate('app_title'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Tabs
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: loc.translate('login')),
                  Tab(text: loc.translate('register')),
                ],
              ),
              
              // Tab Views (Forms)
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEmailForm(isRegister: false),
                    _buildEmailForm(isRegister: true),
                  ],
                ),
              ),

              // Alternative Options Logic
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(children: [
                        const Expanded(child: Divider()),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(loc.translate('or_divider'))),
                        const Expanded(child: Divider()),
                    ]),
                    const SizedBox(height: 16),
                    
                    // Buttons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [

                        _AltAuthButton(
                          icon: Icons.g_mobiledata, 
                          label: loc.translate('auth_google'), 
                          onTap: _performGoogleLogin,
                        ),
                         _AltAuthButton(
                          icon: Icons.person_outline, 
                          label: loc.translate('auth_guest'), 
                          onTap: _continueAsGuest,
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
      ),
    );
  }

  Widget _buildEmailForm({required bool isRegister}) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: isRegister ? _registerFormKey : _loginFormKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: loc.translate('email_label'), prefixIcon: const Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val != null && val.contains('@') ? null : loc.translate('invalid_email'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: loc.translate('password_label'), prefixIcon: const Icon(Icons.lock)),
                obscureText: true,
                validator: (val) => val != null && val.length >= 6 ? null : loc.translate('min_password_len'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _submitEmailForm(isRegister: isRegister),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(isRegister ? loc.translate('create_account') : loc.translate('login')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AltAuthButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AltAuthButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
             Icon(icon, size: 28, color: Theme.of(context).primaryColor),
             const SizedBox(height: 4),
             Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
