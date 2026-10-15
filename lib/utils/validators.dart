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

  // Password Validation
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
