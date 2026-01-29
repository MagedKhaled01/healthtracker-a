
import 'package:flutter/material.dart';
import '../viewmodels/auth_view_model.dart';
import '../presentation/views/dashboard_screen.dart';
import 'profile_form_screen.dart';
import '../services/profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _viewModel = AuthViewModel();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onViewModelChange);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChange);
    _viewModel.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onViewModelChange() {
    if (mounted) setState(() {});
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await _viewModel.loginWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      // Check for profile
      // To strictly follow MVVM without exposing _auth in ViewModel public API if not already there,
      // we might typically handle this in ViewModel, but the request says user logic here.
      // Re-reading rules: "Get current Firebase userId".
      
      // We need to instantiate ProfileService here or use a helper. 
      // Direct service usage in UI layer (or a helper function) seems implied by "Navigation Logic" step.
      if (!mounted) return;
      
      await _checkProfileAndNavigate(context);
    } else if (_viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_viewModel.errorMessage!)),
      );
    }
  }

  Future<void> _checkProfileAndNavigate(BuildContext context) async {
    // Ideally this logic should be in a ViewModel or a shared NavigationService, 
    // but per instructions to modify 'LoginScreen' directly:
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Show temporary loading or rely on the previous loading state if held?
    // We'll just run it.
    
    // Lazy import here to avoid messing up imports too much? No, better add imports at top.
    // For now we assume imports will be added via separate tool call if needed or I add them now.
    
    final profileService = ProfileService();
    final profile = await profileService.getProfile(user.uid);

    if (!mounted) return;

    if (profile != null) {
       Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
        (route) => false,
      );
    } else {
       Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const ProfileFormScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val != null && val.isNotEmpty ? null : 'Required',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (val) => val != null && val.length >= 6 ? null : 'Min 6 chars',
              ),
              const SizedBox(height: 24),
              _viewModel.isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      child: const Text('Login'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
