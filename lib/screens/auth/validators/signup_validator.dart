class SignupValidator {
  static String? validateFullName(String name) {
    final normalizedName = name.trim();

    if (normalizedName.isEmpty) return "Full name is required";
    if (normalizedName.length < 3) {
      return "Name must be at least 3 characters";
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(normalizedName)) {
      return "Name can only contain letters and spaces";
    }

    return null;
  }

  static String? validateEmail(String email) {
    final normalizedEmail = email.trim();

    if (normalizedEmail.isEmpty) return "Email is required";
    if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w]{2,4}$').hasMatch(normalizedEmail)) {
      return "Enter a valid email address";
    }

    return null;
  }

  static String? validatePassword(String password) {
    if (password.isEmpty) return "Password is required";

    if (password.length < 8) {
      return "Password must be at least 8 characters long";
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return "Include at least one uppercase letter";
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return "Include at least one lowercase letter";
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return "Include at least one number";
    }

    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return "Include at least one special character";
    }

    return null;
  }

  static String? validateConfirmPassword(String password, String confirm) {
    if (confirm.isEmpty) return "Confirm your password";

    if (password != confirm) {
      return "Passwords do not match";
    }

    return null;
  }

  static String normalizeEmailNotFoundMessage(String message) {
    final normalizedMessage = message.trim().toLowerCase();
    const emailNotFoundPhrases = [
      'user not found',
      'no account found',
      'account not found',
      'email not found',
      'no user',
      'does not exist',
    ];

    if (emailNotFoundPhrases.any(normalizedMessage.contains)) {
      return "No account found with this email";
    }

    return message.trim();
  }

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
