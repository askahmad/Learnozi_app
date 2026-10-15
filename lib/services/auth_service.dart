import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current User stream to listen to login/logout state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current logged-in user
  User? get currentUser => _auth.currentUser;

  // 1. User Registration (Sign Up)
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      // Save user's display name
      if (credential.user != null) {
        await credential.user!.updateDisplayName(name.trim());
        await credential.user!.reload();
      }

      return null; // Success (no error)
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'This mail is already regesterd.';
        case 'invalid-email':
          return 'This email format is wrong.';
        case 'weak-password':
          return 'Weak Password.';
        case 'network-request-failed':
          return 'Check your Internet connection.';
        default:
          return e.message ?? 'Registration fail.';
      }
    } catch (e) {
      return 'Unknown problem.';
    }
  }

  // 2. User Login (Sign In)
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Wrong password entered.';
        case 'invalid-credential':
          return 'Invalid email or password.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'user-disabled':
          return 'This account is disabled.';
        case 'network-request-failed':
          return 'Check your Internet connection.';
        default:
          return e.message ?? 'Login fail.';
      }
    } catch (e) {
      return 'Unknown problem.';
    }
  }

  // 3. Password Reset
  Future<String?> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'invalid-email':
          return 'Invalid email address.';
        default:
          return e.message ?? 'Failed to send password reset email.';
      }
    } catch (e) {
      return 'Unknown error occurred.';
    }
  }

  // 4. User Logout (Sign Out)
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
