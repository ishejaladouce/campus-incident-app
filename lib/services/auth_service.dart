import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/app_exception.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Tells the app whenever a user logs in or out
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // Only allow ALU emails: something before the @, then exactly an ALU domain
  static final RegExp _aluEmailRegex =
      RegExp(r'^[a-z0-9._%+-]+@(alustudent|alueducation)\.com$');

  static bool isAluEmail(String email) {
    return _aluEmailRegex.hasMatch(email.trim().toLowerCase());
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (!isAluEmail(cleanEmail)) {
      throw const AppException('Please use your ALU email address.');
    }

    final cred = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );
    final user = cred.user!;

    // Save the profile (everyone starts as a student)
    try {
      final appUser = AppUser(
        uid: user.uid,
        name: name.trim(),
        email: cleanEmail,
        role: 'student',
      );
      await _db.collection('users').doc(user.uid).set({
        ...appUser.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Roll back: never leave a login without a profile
      try {
        await user.delete();
      } catch (_) {}
      throw const AppException('Could not create your profile. Please try again.');
    }

    // If sending fails, the user can tap "Resend email" on the next screen
    try {
      await user.sendEmailVerification();
    } catch (_) {}
  }

  Future<void> login({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  Future<void> logout() => _auth.signOut();

  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  // Refresh the user to check if they clicked the verification link
  Future<bool> checkEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<AppUser?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.id, doc.data()!);
  }
}