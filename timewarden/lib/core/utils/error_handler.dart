import '../services/log_service.dart';

/// Centralized error handling utilities
class ErrorHandler {
  /// Handle and log Firebase authentication errors
  static String handleAuthError(dynamic error) {
    LogService.auth('Authentication error occurred', error: error);
    
    final errorMessage = error.toString().toLowerCase();
    
    if (errorMessage.contains('user-not-found')) {
      return 'No user found with this email address.';
    } else if (errorMessage.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    } else if (errorMessage.contains('email-already-in-use')) {
      return 'An account with this email already exists.';
    } else if (errorMessage.contains('weak-password')) {
      return 'Password is too weak. Please choose a stronger password.';
    } else if (errorMessage.contains('invalid-email')) {
      return 'Invalid email address format.';
    } else if (errorMessage.contains('user-disabled')) {
      return 'This account has been disabled.';
    } else if (errorMessage.contains('too-many-requests')) {
      return 'Too many failed attempts. Please try again later.';
    } else if (errorMessage.contains('network-request-failed')) {
      return 'Network error. Please check your connection.';
    } else {
      return 'Authentication failed. Please try again.';
    }
  }

  /// Handle and log Firestore database errors
  static String handleDatabaseError(dynamic error) {
    LogService.firebase('Database error occurred', error: error);
    
    final errorMessage = error.toString().toLowerCase();
    
    if (errorMessage.contains('permission-denied')) {
      return 'Permission denied. Please check your account access.';
    } else if (errorMessage.contains('unavailable')) {
      return 'Service temporarily unavailable. Please try again later.';
    } else if (errorMessage.contains('deadline-exceeded')) {
      return 'Request timeout. Please try again.';
    } else if (errorMessage.contains('not-found')) {
      return 'Requested data not found.';
    } else if (errorMessage.contains('already-exists')) {
      return 'Data already exists.';
    } else if (errorMessage.contains('resource-exhausted')) {
      return 'Service quota exceeded. Please try again later.';
    } else {
      return 'Database error occurred. Please try again.';
    }
  }

  /// Handle general application errors
  static String handleGeneralError(dynamic error, {String? context}) {
    LogService.error('General error occurred${context != null ? ' in $context' : ''}', error: error);
    
    if (error.toString().contains('SocketException')) {
      return 'No internet connection. Please check your network.';
    } else if (error.toString().contains('TimeoutException')) {
      return 'Request timeout. Please try again.';
    } else if (error.toString().contains('FormatException')) {
      return 'Invalid data format received.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Log and return a user-friendly error message
  static String processError(dynamic error, {String? context, String? fallbackMessage}) {
    // Try to categorize the error
    final errorString = error.toString();
    
    if (errorString.contains('firebase_auth')) {
      return handleAuthError(error);
    } else if (errorString.contains('cloud_firestore') || errorString.contains('firestore')) {
      return handleDatabaseError(error);
    } else {
      return handleGeneralError(error, context: context);
    }
  }
}
