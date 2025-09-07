import '../entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser?> getCurrentUser();
  AppUser? getCurrentUserSync(); // Quick synchronous check for immediate auth
  Stream<AppUser?> get authStateChanges;
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<AppUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<AppUser> signInWithGoogle();
  Future<void> signOut();
  Future<void> sendPasswordResetEmail({required String email});
}
