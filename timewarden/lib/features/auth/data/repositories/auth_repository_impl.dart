import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/services/firebase_service.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseService _firebaseService;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Web client ID from Firebase Console for OAuth
    serverClientId:
        '623746770431-noalp88sed3c6s77o0lf6lefoav2arsd.apps.googleusercontent.com',
  );

  AuthRepositoryImpl(this._firebaseService) {
    print('🔧 AuthRepositoryImpl initialized');
    print('🔧 GoogleSignIn instance created');
  }

  /// Quick synchronous check for immediate Firebase user (no Google Sign-In check)
  AppUser? getCurrentUserSync() {
    final user = _firebaseService.currentUser;
    if (user != null) {
      print('🚀 Sync check: Firebase user found immediately: ${user.uid}');
      return AppUser.fromFirebaseUser(user);
    }
    print('🚀 Sync check: No immediate Firebase user');
    return null;
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    print('=== getCurrentUser() called ===');

    // First check Firebase user (synchronous check - fastest)
    final user = _firebaseService.currentUser;
    if (user != null) {
      print('✅ Firebase user found immediately: ${user.uid} (${user.email})');
      return AppUser.fromFirebaseUser(user);
    }

    print('No Firebase user found, checking Google Sign-In...');

    // Check if Google user is signed in silently
    try {
      print('Calling _googleSignIn.signInSilently()...');

      // Try to get the current Google user first
      final currentGoogleUser = _googleSignIn.currentUser;
      if (currentGoogleUser != null) {
        print('✅ Current Google user found: ${currentGoogleUser.email}');

        // Get fresh authentication tokens
        final googleAuth = await currentGoogleUser.authentication;

        if (googleAuth.accessToken != null && googleAuth.idToken != null) {
          print('✅ Google tokens obtained, signing into Firebase...');
          final credential = await _firebaseService.signInWithGoogle(
            accessToken: googleAuth.accessToken!,
            idToken: googleAuth.idToken!,
          );

          if (credential?.user != null) {
            print(
                '✅ Firebase user created from current Google user: ${credential!.user!.uid}');
            return AppUser.fromFirebaseUser(credential.user!);
          }
        }
      }

      // If no current user, try silent sign-in
      print('No current Google user, trying silent sign-in...');
      final googleUser = await _googleSignIn.signInSilently();

      if (googleUser != null) {
        print('✅ Google user found silently: ${googleUser.email}');
        print('Getting Google authentication tokens...');

        // Re-authenticate with Firebase using the existing Google credentials
        final googleAuth = await googleUser.authentication;

        if (googleAuth.accessToken != null && googleAuth.idToken != null) {
          print('✅ Google tokens obtained, signing into Firebase...');
          final credential = await _firebaseService.signInWithGoogle(
            accessToken: googleAuth.accessToken!,
            idToken: googleAuth.idToken!,
          );

          if (credential?.user != null) {
            print(
                '✅ Firebase user created from Google credentials: ${credential!.user!.uid}');
            return AppUser.fromFirebaseUser(credential.user!);
          } else {
            print('❌ Failed to create Firebase user from Google credentials');
          }
        } else {
          print('❌ Google authentication tokens are null');
        }
      } else {
        print('❌ No Google user found silently');
      }
    } catch (e) {
      print('❌ Silent Google sign-in failed: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: ${StackTrace.current}');
    }

    print('❌ No user found, returning null');
    return null;
  }

  @override
  Stream<AppUser?> get authStateChanges {
    return _firebaseService.authStateChanges.map((user) {
      return user != null ? AppUser.fromFirebaseUser(user) : null;
    });
  }

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final userCredential = await _firebaseService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (userCredential?.user == null) {
      throw Exception('Sign in failed');
    }

    return AppUser.fromFirebaseUser(userCredential!.user!);
  }

  @override
  Future<AppUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final userCredential = await _firebaseService.signUpWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (userCredential?.user == null) {
      throw Exception('Sign up failed');
    }

    return AppUser.fromFirebaseUser(userCredential!.user!);
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = await _firebaseService.signInWithGoogle(
        accessToken: googleAuth.accessToken!,
        idToken: googleAuth.idToken!,
      );

      if (credential?.user == null) {
        throw Exception('Google sign in failed');
      }

      return AppUser.fromFirebaseUser(credential!.user!);
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseService.signOut();
    await _googleSignIn.signOut(); // Also sign out from Google
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _firebaseService.sendPasswordResetEmail(email: email);
  }
}
