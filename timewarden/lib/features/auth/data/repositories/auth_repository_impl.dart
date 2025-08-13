import '../../../../core/services/firebase_service.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseService _firebaseService;

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
  Future<void> signOut() async {
    await _firebaseService.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _firebaseService.sendPasswordResetEmail(email: email);
  }
}
