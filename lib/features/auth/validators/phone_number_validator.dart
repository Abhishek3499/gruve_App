class PhoneNumberValidator {
  // Real-time validation for phone number
  static String? validatePhoneRealTime(String phone) {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) return "Phone number is required";

    if (!RegExp(r'^[0-9\s().-]+$').hasMatch(trimmed)) {
      return "Phone number can only contain digits and basic separators";
    }

    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 7 || digitsOnly.length > 15) {
      return "Enter valid phone number";
    }

    if (RegExp(r'([().-])\1').hasMatch(trimmed)) {
      return "Enter valid phone number";
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
