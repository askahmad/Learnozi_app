import 'package:flutter/material.dart';

class PasswordStrength {
  final bool hasMinLength; // >= 8
  final bool hasUppercase; // [A-Z]
  final bool hasLowercase; // [a-z]
  final bool hasDigit; // [0-9]
  final bool hasSpecial; // [!@#$%^&*(),.?":{}|<>]

  const PasswordStrength({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigit,
    required this.hasSpecial,
  });

  bool get isStrong =>
      hasMinLength && hasUppercase && hasLowercase && hasDigit && hasSpecial;

  int get metCount {
    int count = 0;
    if (hasMinLength) count++;
    if (hasUppercase) count++;
    if (hasLowercase) count++;
    if (hasDigit) count++;
    if (hasSpecial) count++;
    return count;
  }

  double get fraction => metCount / 5.0;

  String get label {
    if (metCount == 0) return 'Very Weak';
    if (metCount <= 2) return 'Weak';
    if (metCount == 3) return 'Fair';
    if (metCount == 4) return 'Good';
    return 'Strong';
  }

  String get labelUrdu {
    if (metCount == 0) return 'بہت کمزور';
    if (metCount <= 2) return 'کمزور';
    if (metCount == 3) return 'مناسب';
    if (metCount == 4) return 'بہتر';
    return 'مضبوط اور محفوظ';
  }

  Color get color {
    if (metCount <= 1) return const Color(0xFFEF4444); // Red
    if (metCount == 2) return const Color(0xFFF97316); // Orange
    if (metCount == 3) return const Color(0xFFF59E0B); // Amber
    if (metCount == 4) return const Color(0xFF3B82F6); // Blue
    return const Color(0xFF10B981); // Emerald Green
  }

  static PasswordStrength calculate(String password) {
    return PasswordStrength(
      hasMinLength: password.length >= 8,
      hasUppercase: RegExp(r'[A-Z]').hasMatch(password),
      hasLowercase: RegExp(r'[a-z]').hasMatch(password),
      hasDigit: RegExp(r'[0-9]').hasMatch(password),
      hasSpecial: RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password),
    );
  }
}

class AppValidators {
  // Email Validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email enter karna zaroori hai';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Durust email format enter karein (e.g. user@example.com)';
    }
    return null;
  }

  // Strong Password Validation (For Account Creation)
  static String? validateStrongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password enter karna zaroori hai';
    }
    final strength = PasswordStrength.calculate(value);
    if (!strength.hasMinLength) {
      return 'Password kam az kam 8 characters ka hona chahiye';
    }
    if (!strength.hasUppercase) {
      return 'Kam az kam ek bara harf (A-Z) shamil karein';
    }
    if (!strength.hasLowercase) {
      return 'Kam az kam ek chota harf (a-z) shamil karein';
    }
    if (!strength.hasDigit) {
      return 'Kam az kam ek number (0-9) shamil karein';
    }
    if (!strength.hasSpecial) {
      return 'Kam az kam ek special character (!@#\$%^&*...) shamil karein';
    }
    return null;
  }

  // Standard Password Validation (For Login)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password enter karna zaroori hai';
    }
    if (value.length < 6) {
      return 'Password kam az kam 6 characters ka hona chahiye';
    }
    return null;
  }

  // Confirm Password Validation
  static String? validateConfirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Confirm password enter karein';
    }
    if (value != originalPassword) {
      return 'Passwords match nahi kar rahe';
    }
    return null;
  }

  // Name Validation
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Naam enter karna zaroori hai';
    }
    if (value.trim().length < 2) {
      return 'Naam kam az kam 2 characters ka hona chahiye';
    }
    return null;
  }
}
