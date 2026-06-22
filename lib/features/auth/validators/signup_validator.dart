class SignupValidator {
  // Real-time validation methods - for live validation as user types
  static String? validateFullNameRealTime(String name) {
    if (name.trim().isEmpty) return "Please enter your full name";
    if (name.trim().length < 3) return "Name must be at least 3 characters";
    if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(name.trim())) {
      return "Name can only contain letters and spaces";
    }
    return null;
  }

  static String? validateEmailRealTime(String email) {
    if (email.trim().isEmpty) return "Please enter your email address";
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email.trim())) {
      return "Enter a valid email address";
    }
    return null;
  }

  static String? validatePasswordRealTime(String password) {
    if (password.isEmpty) return "Please enter your password";
    if (password.length < 8) return "Use at least 8 characters";
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return "Add at least one uppercase letter";
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return "Add at least one lowercase letter";
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return "Add at least one number";
    }
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return "Add at least one special character";
    }
    return null;
  }

  static String? validateConfirmPasswordRealTime(
    String password,
    String confirm,
  ) {
    if (confirm.isEmpty) return "Please confirm your password";
    if (password != confirm) return "Passwords do not match";
    return null;
  }

  static String? validateUsernameRealTime(String username) {
    final trimmed = username.trim();
    if (trimmed.isEmpty) return "Please enter a username";
    if (trimmed.length < 3) return "Username must be at least 3 characters";
    if (trimmed.length > 30) return "Username must be 30 characters or less";
    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(trimmed)) {
      return "Username can contain only letters, numbers, dots (.), and underscores (_).";
    }
    return null;
  }

  // Combined identifier validation for email/phone
  static String? validateIdentifierRealTime(String identifier) {
    if (identifier.trim().isEmpty) {
      return "Please enter your email or phone number";
    }

    // Check if it's an email
    if (identifier.contains('@')) {
      return validateEmailRealTime(identifier);
    }

    // Check if it's a phone number (basic validation)
    if (identifier.length < 7) return "Please enter a valid phone number";
    if (!RegExp(r'^[0-9+\s-]+$').hasMatch(identifier)) {
      return "Please enter a valid phone number";
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

  static String? validateUsername(String username) {
    return validateUsernameRealTime(username);
  }

  static String? validateBioRealTime(String bio) {
    if (bio.trim().isEmpty) return "Bio is required";
    if (bio.trim().length > 150) return "Bio must be 150 characters or less";
    return null;
  }

  static String? validateOtpRealTime(String otp) {
    if (otp.isEmpty) return "Please enter the OTP";
    if (otp.length < 4 || !RegExp(r'^\d{4}$').hasMatch(otp)) {
      return "Enter a valid 4 digit OTP";
    }
    return null;
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
