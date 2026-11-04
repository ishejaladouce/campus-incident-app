import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  User? _firebaseUser;
  AppUser? _profile;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _error;

  AuthProvider(this._authService) {
    // Listen to login/logout changes from Firebase
    _authService.authStateChanges.listen(_onAuthChanged);
  }

  // Getters: screens read these values
  AppUser? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get error => _error;
  bool get isLoggedIn => _firebaseUser != null;
  bool get isEmailVerified => _firebaseUser?.emailVerified ?? false;
  bool get isStaff => _profile?.isStaff ?? false;

  Future<void> _onAuthChanged(User? user) async {
    _firebaseUser = user;
    try {
      _profile = user != null ? await _authService.getUserProfile(user.uid) : null;
    } catch (e) {
      debugPrint('Could not load profile: $e');
      _profile = null;
    } finally {
      // Always stop the loading screen, even if loading the profile failed
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> _refreshProfile() async {
    _firebaseUser = _authService.currentUser;
    if (_firebaseUser != null) {
      _profile = await _authService.getUserProfile(_firebaseUser!.uid);
    }
  }

  Future<bool> register(String name, String email, String password) {
    return _run(() async {
      await _authService.register(name: name, email: email, password: password);
      await _refreshProfile();
    });
  }

  Future<bool> login(String email, String password) {
    return _run(() async {
      await _authService.login(email: email, password: password);
      await _refreshProfile();
    });
  }

  Future<void> logout() => _authService.logout();

  Future<bool> resendVerificationEmail() {
    return _run(() => _authService.resendVerificationEmail());
  }

  Future<bool> checkEmailVerified() async {
    final verified = await _authService.checkEmailVerified();
    if (verified) {
      // Refresh the token so Firestore security rules see the verified status
      await _authService.currentUser?.getIdToken(true);
    }
    _firebaseUser = _authService.currentUser;
    notifyListeners();
    return verified;
  }

  // Runs an action with loading + error handling, so we don't repeat this code
  Future<bool> _run(Future<void> Function() action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyMessage(e.code);
      return false;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _friendlyMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}