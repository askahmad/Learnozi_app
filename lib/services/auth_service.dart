import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_profile.dart';
import 'user_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  FirebaseAuth? _customAuth;
  FirebaseAuth get _auth {
    try {
      return _customAuth ?? FirebaseAuth.instance;
    } catch (_) {
      // Gracefully handles unit testing environments where Firebase is not initialized
      return _customAuth ?? FirebaseAuth.instance;
    }
  }

  GoogleSignIn? _customGoogleSignIn;
  GoogleSignIn get _googleSignIn => _customGoogleSignIn ?? GoogleSignIn();

  bool _isDemoActive = false;
  bool get isDemoActive => _isDemoActive;

  // Current User stream to listen to login/logout state changes
  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (_) {
      return const Stream.empty();
    }
  }

  // Get current logged-in user
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

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

      // Save user's display name and send official Firebase verification link
      if (credential.user != null) {
        await credential.user!.updateDisplayName(name.trim());
        try {
          await credential.user!.sendEmailVerification();
        } catch (e) {
          debugPrint('Verification email send error: $e');
        }
        await credential.user!.reload();
      }

      _isDemoActive = false;
      notifyListeners();
      return null; // Success (no error)
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'This email is already registered. Please sign in instead.';
        case 'invalid-email':
          return 'The email address format is invalid.';
        case 'weak-password':
          return 'The password is too weak. Please use at least 6 characters.';
        case 'network-request-failed':
          return 'Network error: Please check your internet connection.';
        default:
          return e.message ?? 'Registration failed. Please try again.';
      }
    } catch (e) {
      return 'An unexpected error occurred during registration.';
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
      _isDemoActive = false;
      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No registered account found with this email.';
        case 'wrong-password':
          return 'Incorrect password entered.';
        case 'invalid-credential':
          return 'Invalid email or password credentials.';
        case 'invalid-email':
          return 'Invalid email address format.';
        case 'user-disabled':
          return 'This student account has been disabled by administrator.';
        case 'network-request-failed':
          return 'Network error: Please check your internet connection.';
        default:
          return e.message ?? 'Login failed. Please try again.';
      }
    } catch (e) {
      return 'An unexpected error occurred during login.';
    }
  }

  // 3. Quick Student Demo Sign-In (Allows single-click student exploration)
  void loginAsDemoStudent({
    String? name,
    String? email,
    String? phoneNumber,
    EducationType? educationType,
    String? schoolGrade,
    String? schoolCourse,
    String? universityName,
    String? semester,
    String? program,
  }) {
    _isDemoActive = true;
    final finalEduType = educationType ?? EducationType.school;
    UserService().setNewProfile(
      name: name ?? 'Muhammad Ahmad',
      email: email ?? 'ahmad@learnozi.pk',
      phoneNumber: phoneNumber ?? '',
      educationType: finalEduType,
      schoolGrade: finalEduType == EducationType.school
          ? (schoolGrade ?? '11th (FSc Part 1)')
          : '',
      schoolCourse: finalEduType == EducationType.school
          ? (schoolCourse ?? 'Pre-Medical')
          : '',
      universityName: finalEduType == EducationType.university
          ? (universityName ?? 'Khwaja Fareed UEIT (KFUEIT), Rahim Yar Khan')
          : '',
      semester: finalEduType == EducationType.university
          ? (semester ?? '')
          : '',
      program: finalEduType == EducationType.university
          ? (program ?? 'BS Computer Science (BSCS)')
          : '',
      role: 'student',
    );
    notifyListeners();
  }

  void loginAsDemoAdmin() {
    _isDemoActive = true;
    UserService().updateProfile(
      name: 'Dr. Mutiullah (Supervisor / Admin)',
      email: 'admin@learnozi.pk',
      phoneNumber: '+92 300 9657618',
      educationType: EducationType.university,
      universityName: 'Learnozi University Admin Panel',
      program: 'Head of Computer Science',
      role: 'admin',
    );
    notifyListeners();
  }

  // 4. Password Reset (Method 1: Email Reset Link)
  Future<String?> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'invalid-email':
          return 'Invalid email address format.';
        default:
          return e.message ?? 'Failed to send password reset email.';
      }
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  // 4b. Resend Email Verification (Method 1: Official Verification Link)
  Future<String?> sendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        return null; // Sent successfully
      }
      return 'No active user found to verify.';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Failed to send verification email.';
    } catch (e) {
      return 'An unexpected error occurred sending verification link.';
    }
  }

  bool get isEmailVerified {
    try {
      return _auth.currentUser?.emailVerified ?? true;
    } catch (_) {
      return true;
    }
  }

  // 5. Authentic Sign in / Sign up with Google (Multi-platform: Web + Android/iOS)
  Future<String?> signInWithGoogle() async {
    try {
      // Platform check: Web uses Firebase Auth popup directly (No native plugin needed)
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        final UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
        final user = userCredential.user;

        if (user != null) {
          _isDemoActive = false;
          UserService().updateProfile(
            name: user.displayName ?? 'Student',
            email: user.email,
          );
          notifyListeners();
          return null;
        }
        return 'Unable to retrieve user credentials from Google.';
      }

      // Mobile (Android / iOS): Uses native Google Play Services Account Picker
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the Google sign-in prompt
        return null;
      }

      // 2. Obtain OAuth authentication details from Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Create Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Authenticate in Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        _isDemoActive = false;
        UserService().updateProfile(
          name: user.displayName ?? googleUser.displayName ?? 'Student',
          email: user.email ?? googleUser.email,
        );
        notifyListeners();
        return null;
      }
      return 'Unable to retrieve user credentials from Google.';
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'popup-closed-by-user':
          return null; // Silent cancel when user closes web popup
        case 'account-exists-with-different-credential':
          return 'An account already exists with a different sign-in method.';
        case 'invalid-credential':
          return 'Invalid Google credentials provided.';
        case 'network-request-failed':
          return 'Network error: Please check your internet connection.';
        default:
          return e.message ?? 'Google authentication failed (${e.code}).';
      }
    } catch (e) {
      final err = e.toString();
      if (err.contains('canceled') ||
          err.contains('cancelled') ||
          err.contains('sign_in_canceled') ||
          err.contains('popup_closed_by_user')) {
        return null;
      }
      if (err.contains('MissingPluginException')) {
        return 'Please restart the app (press Stop in VS Code and run again) so the new Google Sign-In plugin can link.';
      }
      if (err.contains('10') || err.contains('DEVELOPER_ERROR')) {
        return 'Google Sign-In configuration error: Please check Firebase Console SHA-1 fingerprint.';
      }
      return 'Google Sign-In error: $e';
    }
  }

  // 6. Sign Out
  Future<void> signOut() async {
    _isDemoActive = false;
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
    notifyListeners();
  }
}
