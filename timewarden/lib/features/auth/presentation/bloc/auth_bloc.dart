import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../../../core/services/log_service.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthSignInRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthSignUpRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

class AuthGoogleSignInRequested extends AuthEvent {}

class AuthSignOutRequested extends AuthEvent {}

class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested({required this.email});

  @override
  List<Object> get props => [email];
}

class AuthStateChanged extends AuthEvent {
  final AppUser? user;

  const AuthStateChanged(this.user);

  @override
  List<Object> get props => [user ?? 'null'];
}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final AppUser user;

  const AuthAuthenticated(this.user);

  @override
  List<Object> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}

class AuthPasswordResetSent extends AuthState {
  final String email;

  const AuthPasswordResetSent(this.email);

  @override
  List<Object> get props => [email];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  late final StreamSubscription<AppUser?> _authStateSubscription;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignInRequested>(_onAuthSignInRequested);
    on<AuthSignUpRequested>(_onAuthSignUpRequested);
    on<AuthGoogleSignInRequested>(_onAuthGoogleSignInRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
    on<AuthPasswordResetRequested>(_onAuthPasswordResetRequested);
    on<AuthStateChanged>(_onAuthStateChanged);

    // Listen to auth state changes
    _authStateSubscription = _authRepository.authStateChanges.listen((user) {
      add(AuthStateChanged(user));
    });

    // Check initial auth state immediately
    add(AuthCheckRequested());
  }

  @override
  Future<void> close() {
    _authStateSubscription.cancel();
    return super.close();
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      LogService.auth('=== AuthCheckRequested: Starting auth check ===');

      // First try immediate sync check (fastest possible path)
      final syncUser = _authRepository.getCurrentUserSync();
      if (syncUser != null) {
        LogService.auth('✅ Immediate sync user found: ${syncUser.id}');
        emit(AuthAuthenticated(syncUser));
        return;
      }

      // If no sync user, do full async check
      LogService.auth('No sync user, doing full async check...');
      final user = await _authRepository.getCurrentUser();

      if (user != null) {
        LogService.auth(
            '✅ User found during auth check: ${user.id} (${user.email})');
        emit(AuthAuthenticated(user));
      } else {
        LogService.auth('❌ No user found during auth check');
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      LogService.auth('❌ Error during auth check', error: e);
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(_getErrorMessage(e)));
    }
  }

  Future<void> _onAuthSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      LogService.auth('Attempting to sign up with email: ${event.email}');
      final user = await _authRepository.signUpWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      LogService.auth('Sign up successful: ${user.id}');
      emit(AuthAuthenticated(user));
    } catch (e) {
      LogService.auth('Sign up error', error: e);
      emit(AuthError(_getErrorMessage(e)));
    }
  }

  Future<void> _onAuthGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      LogService.auth('Attempting to sign in with Google');
      final user = await _authRepository.signInWithGoogle();
      LogService.auth('Google sign in successful: ${user.id}');
      emit(AuthAuthenticated(user));
    } catch (e) {
      LogService.auth('Google sign in error', error: e);
      emit(AuthError(_getErrorMessage(e)));
    }
  }

  Future<void> _onAuthSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.signOut();
    emit(AuthUnauthenticated());
  }

  Future<void> _onAuthPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.sendPasswordResetEmail(email: event.email);
      emit(AuthPasswordResetSent(event.email));
    } catch (e) {
      emit(AuthError(_getErrorMessage(e)));
    }
  }

  Future<void> _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (event.user != null) {
      LogService.auth('Auth state changed: User signed in - ${event.user!.id}');
      emit(AuthAuthenticated(event.user!));
    } else {
      LogService.auth('Auth state changed: User signed out');
      emit(AuthUnauthenticated());
    }
  }

  String _getErrorMessage(dynamic error) {
    LogService.auth('Processing authentication error', error: error);
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'email-already-in-use':
          return 'An account already exists with this email address.';
        case 'weak-password':
          return 'The password provided is too weak.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'invalid-api-key':
          return 'Firebase API key is invalid. Please check your Firebase configuration.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'too-many-requests':
          return 'Too many requests. Please try again later.';
        default:
          return 'Firebase Auth Error (${error.code}): ${error.message ?? 'Unknown error'}';
      }
    }
    return 'Error: ${error.toString()}';
  }
}
