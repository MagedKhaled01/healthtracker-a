import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_view_model.dart';
import '../presentation/widgets/auth_bottom_sheet.dart';

class AuthGuard {
  static void protect(BuildContext context, VoidCallback action) {
    final vm = context.read<AuthViewModel>();
    
    // Check if user is null OR anonymous
    // Typically initialized user is not null if we are in dashboard.
    // If we handle "no user" as well, we should check `vm.user == null`.
    // But `isGuest` checks `currentUser?.isAnonymous`.
    // If not logged in at all, `currentUser` is null. `isGuest` returns false in my impl (?? false).
    // Wait, if `currentUser` is null, they definitely need to login.
    // So we should check `vm.user == null || vm.isGuest`.
    
    // However, Dashboard usually requires a user. If we allow "Guest", we have an anonymous user.
    // So `isGuest` should cover it.
    
    if (vm.isGuest) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => const AuthBottomSheet(allowGuest: false), // No "Continue as Guest" here, as we are upgrading
      );
    } else {
      action();
    }
  }
}
