import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Tells the app whenever a user logs in or out
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // Only allow ALU emails
  static bool isAluEmail(String email) {
    final e = email.trim().toLowerCase();
    return e.endsWith('@alustudent.com') || e.endsWith('@alueducation.com');
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (!isAluEmail(email)) {
      throw Exception('Please use your ALU email address.');
    }

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;

    // Save the user's profile in Firestore (everyone starts as a student)
    final appUser = AppUser(
      uid: user.uid,
      name: name.trim(),
      email: email.trim(),
      role: 'student',
    );
    await _db.collection('users').doc(user.uid).set({
      ...appUser.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Send the verification email
    await user.sendEmailVerification();
  }

  Future<void> login({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
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