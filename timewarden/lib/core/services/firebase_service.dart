import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'log_service.dart';
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
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
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
    return _firestore.collection('users').doc(userId);
  }

  // Get user habits collection
  CollectionReference getUserHabits(String userId) {
    return _firestore.collection('users').doc(userId).collection('habits');
  }

  // Get user journal entries collection
  CollectionReference getUserJournalEntries(String userId) {
    return _firestore.collection('users').doc(userId).collection('journal');
  }

  // Get user pomodoro sessions collection
  CollectionReference getUserPomodoroSessions(String userId) {
    return _firestore.collection('users').doc(userId).collection('pomodoros');
  }

  // Get user streaks collection
  CollectionReference getUserStreaks(String userId) {
    return _firestore.collection('users').doc(userId).collection('streaks');
  }
}
