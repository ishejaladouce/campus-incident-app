import '../services/auth_service.dart';

class Validators {
  static String? name(String? value) {
    if (value == null || value.trim().length < 2) {
      return 'Please enter your full name';
    }
    return null;
  }

  static String? aluEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!AuthService.isAluEmail(value)) {
      return 'Use your ALU email (@alustudent.com or @alueducation.com)';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}