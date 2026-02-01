import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../l10n/app_localizations.dart';

class AuthBottomSheet extends StatefulWidget {
  // allowGuest: If true, shows "Continue as Guest" option. 
  // Useful for the initial login screen, but disabled when upgrading from Guest.
  
  final bool allowGuest;

  const AuthBottomSheet({super.key, this.allowGuest = false});

  @override
  State<AuthBottomSheet> createState() => _AuthBottomSheetState();
}

class _AuthBottomSheetState extends State<AuthBottomSheet> {
  bool _isLogin = true; // Toggle between Login and Register for Email
  bool _showEmailForm = false;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final vm = context.watch<AuthViewModel>();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, 
        right: 16, 
        top: 24
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle for bottom sheet
            Center(
              child: Container(
                width: 40, 
                height: 4, 
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              _showEmailForm 
                ? (_isLogin ? loc.translate('login') : loc.translate('register'))
                : loc.translate('login_required'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (!_showEmailForm)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 24),
                child: Text(
                  loc.translate('login_required_msg'),
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 24),

            if (_showEmailForm) ...[
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: loc.translate('email_hint'),
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => v!.contains('@') ? null : loc.translate('invalid'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: loc.translate('password_hint'),
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      obscureText: true,
                      validator: (v) => v!.length >= 6 ? null : loc.translate('invalid'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: vm.isLoading ? null : () async {
                   if (_formKey.currentState!.validate()) {
                     bool success;
                     if (_isLogin) {
                       success = await vm.loginWithEmail(_emailController.text, _passwordController.text);
                     } else {
                       success = await vm.registerWithEmail(_emailController.text, _passwordController.text);
                     }
                     
                     if (success && mounted) {
                       Navigator.pop(context); // Close sheet on success
                     } else if (mounted && vm.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.errorMessage!)));
                     }
                   }
                },
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: vm.isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isLogin ? loc.translate('login') : loc.translate('register')),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _isLogin = !_isLogin);
                },
                child: Text(_isLogin ? loc.translate('dont_have_account') : loc.translate('already_have_account')),
              ),
              TextButton(
                onPressed: () => setState(() => _showEmailForm = false),
                child: Text(loc.translate('cancel')),
              ),
            ] else ...[
              // Providers List
              _AuthButton(
                icon: Icons.g_mobiledata, // Or a custom asset for Google
                label: loc.translate('continue_google'),
                onTap: () async {
                   final success = await vm.signInWithGoogle();
                   if (success && mounted) Navigator.pop(context);
                },
                color: Colors.white,
                textColor: Colors.black,
                borderColor: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              _AuthButton(
                icon: Icons.email_outlined,
                label: loc.translate('continue_email'),
                onTap: () => setState(() => _showEmailForm = true),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                textColor: Theme.of(context).colorScheme.onSurface,
              ),
              
              if (widget.allowGuest) ...[
                const SizedBox(height: 12),
                 const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("OR", style: TextStyle(fontSize: 10))), Expanded(child: Divider())]),
                 const SizedBox(height: 12),
                _AuthButton(
                  icon: Icons.person_outline,
                  label: loc.translate('continue_guest'),
                  onTap: () async {
                     final success = await vm.signInAnonymously();
                     if (success && mounted) Navigator.pop(context);
                  },
                  color: Colors.transparent,
                  textColor: Colors.grey,
                  isOutlined: true,
                ),
              ],
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;
  final Color? borderColor;
  final bool isOutlined;

  const _AuthButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    required this.textColor,
    this.borderColor,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
       return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: textColor),
        label: Text(label, style: TextStyle(color: textColor)),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          side: BorderSide(color: Colors.grey.shade400),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: textColor),
      label: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(12),
           side: borderColor != null ? BorderSide(color: borderColor!) : BorderSide.none,
        ),
        elevation: 0,
      ),
    );
  }
}
