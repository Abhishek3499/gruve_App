class SignupValidator {

  // Real-time validation methods - for live validation as user types
  static String? validateFullNameRealTime(String name) {
    if (name.trim().isEmpty) return "Full name is required";
    if (name.trim().length < 3) return "Name must be at least 3 characters";
    if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(name.trim())) {
      return "Name can only contain letters and spaces";
    }
    return null;
  }

  static String? validateEmailRealTime(String email) {
    if (email.trim().isEmpty) return "Email is required";
    if (!RegExp(r"^[\w\.-]+@[\w\.-]+\.\w{2,}$").hasMatch(email.trim())) {
      return "Enter a valid email address";
    }
    return null;
  }

  static String? validatePasswordRealTime(String password) {
    if (password.isEmpty) return "Password is required";
    if (password.length < 8) return "Password must be at least 8 characters";
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return "Must contain at least one uppercase letter";
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return "Must contain at least one lowercase letter";
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return "Must contain at least one number";
    }
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return "Must contain at least one special character";
    }
    return null;
  }

  static String? validateConfirmPasswordRealTime(String password, String confirm) {
    if (confirm.isEmpty) return "Please confirm your password";
    if (password != confirm) return "Passwords do not match";
    return null;
  }

  // Combined identifier validation for email/phone
  static String? validateIdentifierRealTime(String identifier) {
    if (identifier.trim().isEmpty) return "Email or phone is required";
    
    // Check if it's an email
    if (identifier.contains('@')) {
      return validateEmailRealTime(identifier);
    }
    
    // Check if it's a phone number (basic validation)
    if (identifier.length < 7) return "Enter valid phone number";
    if (!RegExp(r'^[0-9+\s-]+$').hasMatch(identifier)) {
      return "Phone number can only contain digits, +, -, and spaces";
    }
    
    return null;
  }

  // Legacy validation methods - keep for backward compatibility
  static String? validateFullName(String name) {
    return validateFullNameRealTime(name);
  }

  static String? validateEmail(String email) {
    return validateEmailRealTime(email);
  }

  static String? validatePassword(String password) {
    return validatePasswordRealTime(password);
  }

  static String? validateConfirmPassword(String password, String confirm) {
    return validateConfirmPasswordRealTime(password, confirm);
  }

  // Single method to validate ALL fields at once
  static String? validateAll({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    return validateFullName(fullName) ??
        validateEmail(email) ??
        validatePassword(password) ??
        validateConfirmPassword(password, confirmPassword);
  }
}

