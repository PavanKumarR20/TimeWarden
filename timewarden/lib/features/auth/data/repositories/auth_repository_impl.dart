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

  AuthRepositoryImpl(this._firebaseService);

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = _firebaseService.currentUser;
    return user != null ? AppUser.fromFirebaseUser(user) : null;
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
