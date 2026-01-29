import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  User? get currentUser => _auth.currentUser;

  bool get isGuest => _auth.currentUser?.isAnonymous ?? true;

  Future<User?> signInAnonymously() async {
    final result = await _auth.signInAnonymously();
    return result.user;
  }

  Future<User?> signInWithGoogle() async {
    // 1. Trigger Google Sign In flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // User canceled

    // 2. Obtain auth details
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // 3. Create credential
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 4. Check if we should link or sign in
    final currentUser = _auth.currentUser;

    if (currentUser != null && currentUser.isAnonymous) {
      try {
        // Try to link to the existing anonymous user
        final result = await currentUser.linkWithCredential(credential);
        return result.user;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use') {
          // The Google account is already linked to another user.
          // Fallback: Sign in differently (switch account).
          final result = await _auth.signInWithCredential(credential);
          return result.user;
        } else {
          rethrow;
        }
      }
    } else {
      // Normal sign in
      final result = await _auth.signInWithCredential(credential);
      return result.user;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut(); // Ensure Google sign out too
    await _auth.signOut();
  }
}
