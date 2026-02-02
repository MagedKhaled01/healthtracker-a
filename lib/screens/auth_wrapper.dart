import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/profile_service.dart';
import '../presentation/views/dashboard_screen.dart';
import 'auth_choice_screen.dart';
import 'profile_form_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the connection state is waiting, show a loading indicator
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If we have a user, check for their profile
        if (snapshot.hasData && snapshot.data != null) {
          return const _ProfileCheckWrapper();
        }

        // Otherwise, show the auth choice screen
        return const AuthChoiceScreen();
      },
    );
  }
}

class _ProfileCheckWrapper extends StatefulWidget {
  const _ProfileCheckWrapper();

  @override
  State<_ProfileCheckWrapper> createState() => _ProfileCheckWrapperState();
}

class _ProfileCheckWrapperState extends State<_ProfileCheckWrapper> {
  Future<bool>? _profileCheckFuture;

  @override
  void initState() {
    super.initState();
    _profileCheckFuture = _checkProfile();
  }

  Future<bool> _checkProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final profileService = ProfileService();
      final profile = await profileService.getProfile(user.uid);
      return profile != null;
    } catch (e) {
      // In case of error (connectivity etc.), we might want to default to dashboard 
      // or show error. For now, assuming if we cant find profile, we might need to create one
      // OR if it's a network error, maybe just let them in (Dashboard handles missing data?)
      // Let's stick to the logic: No profile -> Form. 
      return false; 
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _profileCheckFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final profileExists = snapshot.data ?? false;

        if (profileExists) {
          return const DashboardScreen();
        } else {
          return const ProfileFormScreen();
        }
      },
    );
  }
}
