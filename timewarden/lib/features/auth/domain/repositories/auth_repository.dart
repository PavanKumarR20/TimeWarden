import '../entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser?> getCurrentUser();
  Stream<AppUser?> get authStateChanges;
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<AppUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<void> signOut();
  Future<void> sendPasswordResetEmail({required String email});
}
