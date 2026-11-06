import '../services/auth_service.dart';

class Validators {
  // Letters (including accents like é), spaces, hyphens and apostrophes
  static final RegExp _nameRegex = RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿ' -]+$");
  // Basic email shape: something@something.something, no spaces
  static final RegExp _emailShape = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _hasLetter = RegExp(r'[A-Za-z]');
  static final RegExp _hasNumber = RegExp(r'[0-9]');

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your full name';
    if (v.length < 2) return 'Name is too short';
    if (v.length > 50) return 'Name must be 50 characters or less';
    if (!_nameRegex.hasMatch(v)) {
      return 'Use only letters, spaces, hyphens or apostrophes';
    }
    return null;
  }

  static String? aluEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!_emailShape.hasMatch(v)) return 'Enter a valid email address';
    if (!AuthService.isAluEmail(v)) {
      return 'Use your ALU email (@alustudent.com or @alueducation.com)';
    }
    return null;
  }

  // For registration: a strong password
  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Use at least 8 characters';
    if (!_hasLetter.hasMatch(v) || !_hasNumber.hasMatch(v)) {
      return 'Include at least one letter and one number';
    }
    return null;
  }

  // For login: only required (older accounts may use older password rules)
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  // Required text with a minimum and maximum length
  static String? textLength(
    String? value, {
    required String fieldName,
    int min = 1,
    required int max,
  }) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '$fieldName is required';
    if (v.length < min) return '$fieldName must be at least $min characters';
    if (v.length > max) return '$fieldName must be $max characters or less';
    return null;
  }
}