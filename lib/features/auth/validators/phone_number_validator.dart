class PhoneNumberValidator {
  // Real-time validation for phone number
  static String? validatePhoneRealTime(String phone) {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) return "Please enter your phone number";

    if (!RegExp(r'^[0-9\s().-]+$').hasMatch(trimmed)) {
      return "Please enter a valid phone number";
    }

    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 7 || digitsOnly.length > 15) {
      return "Please enter a valid phone number";
    }

    if (RegExp(r'([().-])\1').hasMatch(trimmed)) {
      return "Please enter a valid phone number";
    }

    return null;
  }

  // Legacy validation method for backward compatibility
  static String? validatePhone(String phone) {
    return validatePhoneRealTime(phone);
  }

  // Check if phone is in valid format for submission
  static bool isValidPhone(String phone) {
    return validatePhoneRealTime(phone) == null;
  }
}
