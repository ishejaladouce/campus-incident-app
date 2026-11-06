import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app_exception.dart';

/// Turns any error into a short message a student can understand.
class ErrorMessages {
  static String from(Object error) {
    if (error is AppException) return error.message;
    if (error is TimeoutException) {
      return 'This is taking too long. Check your internet connection and try again.';
    }
    if (error is SocketException) {
      return 'No internet connection. Please check your network.';
    }
    // FirebaseAuthException must be checked before FirebaseException
    if (error is FirebaseAuthException) return _auth(error.code);
    if (error is FirebaseException) return _firebase(error.code);
    return 'Something went wrong. Please try again.';
  }

  static String _auth(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists. Try logging in.';
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters with letters and numbers.';
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact campus staff.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  static String _firebase(String code) {
    switch (code) {
      case 'permission-denied':
        return 'You do not have permission to do that.';
      case 'unavailable':
        return 'The service is unavailable. Check your internet connection.';
      case 'deadline-exceeded':
        return 'This is taking too long. Please try again.';
      case 'not-found':
        return 'This item no longer exists.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}