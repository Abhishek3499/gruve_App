class SignupValidator {
  static String? validateFullName(String name) {
    if (name.trim().isEmpty) return "Full name is required";
    if (name.trim().length < 3) return "Name must be at least 3 characters";
    if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(name.trim())) {
      return "Name can only contain letters and spaces";
    }
    return null;
  }

  static String? validateEmail(String email) {
    if (email.trim().isEmpty) return "Email is required";
    if (!RegExp(r"^[\w\.-]+@[\w\.-]+\.\w{2,}$").hasMatch(email.trim())) {
      return "Enter a valid email address";
    }
    return null;
  }

  static String? validatePassword(String password) {
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

  static String? validateConfirmPassword(String password, String confirm) {
    if (confirm.isEmpty) return "Please confirm your password";
    if (password != confirm) return "Passwords do not match";
    return null;
  }

  // ✅ Single method to validate ALL fields at once
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
