class SignupRequest {
  final String? fullName;
  final String? email;
  final String? password;
  final String? countryCode;
  final String? phoneNumber;

  SignupRequest({
    this.fullName,
    this.email,
    this.password,
    this.countryCode,
    this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};

    if (fullName != null) data["full_name"] = fullName;
    if (email != null) data["email"] = email;
    if (password != null) data["password"] = password;
    if (countryCode != null) data["country_code"] = countryCode;
    if (phoneNumber != null) data["phone_number"] = phoneNumber;

    return data;
  }
}
