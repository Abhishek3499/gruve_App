class PhoneNumberValidator {

  // Real-time validation for phone number
  static String? validatePhoneRealTime(String phone) {
    if (phone.trim().isEmpty) return "Phone number is required";
    
    // Remove common formatting characters for validation
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (cleanPhone.length < 7) return "Enter valid phone number";
    
    if (!RegExp(r'^[0-9+\s-]+$').hasMatch(phone)) {
      return "Phone number can only contain digits, +, -, and spaces";
    }
    
    // Basic international format validation
    if (cleanPhone.startsWith('+')) {
      if (cleanPhone.length < 8) return "Enter valid international number";
    } else {
      if (cleanPhone.length < 10) return "Enter valid phone number";
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