import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'log_service.dart';
import '../utils/performance_utils.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Auth getters
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;

  // Current user
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  // Auth stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await PerformanceUtils.timeOperation(
      'auth_sign_in',
      () async {
        LogService.info('Attempting sign in for user: $email');
        try {
          final result = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          LogService.info('Sign in successful for user: ${result.user?.uid}');
          return result;
        } catch (e) {
          LogService.error('Sign in failed', error: e);
          rethrow;
        }
      },
    );
  }

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      LogService.firebase('Attempting to create user with email: $email');
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      LogService.firebase('User created successfully: ${result.user?.uid}');
      return result;
    } catch (e) {
      LogService.firebase('Error creating user', error: e);
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle({
    required String accessToken,
    required String idToken,
  }) async {
    try {
      // Create a credential
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      // Sign in to Firebase with the credential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      LogService.firebase('Error signing in with Google', error: e);
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Password reset
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Get user document reference
  DocumentReference getUserDoc(String userId) {
    // Security check: ensure current user can only access their own data
    if (currentUserId == null || currentUserId != userId) {
      throw Exception('Unauthorized access: User can only access their own data');
    }
    return _firestore.collection('users').doc(userId);
  }

  // Get user habits collection
  CollectionReference getUserHabits(String userId) {
    // Security check: ensure current user can only access their own data
    if (currentUserId == null || currentUserId != userId) {
      throw Exception('Unauthorized access: User can only access their own habits');
    }
    return _firestore.collection('users').doc(userId).collection('habits');
  }

  // Get user journal collection
  CollectionReference getUserJournal(String userId) {
    // Security check: ensure current user can only access their own data
    if (currentUserId == null || currentUserId != userId) {
      throw Exception('Unauthorized access: User can only access their own journal');
    }
    return _firestore.collection('users').doc(userId).collection('journal');
  }

  // Get user pomodoro sessions collection
  CollectionReference getUserPomodoroSessions(String userId) {
    // Security check: ensure current user can only access their own data
    if (currentUserId == null || currentUserId != userId) {
      throw Exception('Unauthorized access: User can only access their own pomodoro sessions');
    }
    return _firestore.collection('users').doc(userId).collection('pomodoros');
  }

  // Get user streaks collection
  CollectionReference getUserStreaks(String userId) {
    // Security check: ensure current user can only access their own data
    if (currentUserId == null || currentUserId != userId) {
      throw Exception('Unauthorized access: User can only access their own streaks');
    }
    return _firestore.collection('users').doc(userId).collection('streaks');
  }
}
