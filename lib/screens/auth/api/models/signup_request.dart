class SignupRequest {
  final String? fullName;
  final String? identifier;
  final String? password;
  final String? countryCode;

  final String? gender;

  SignupRequest({
    this.fullName,
    this.identifier,
    this.password,
    this.countryCode,

    this.gender,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};

    if (fullName != null) data["full_name"] = fullName;
    if (identifier != null) data["identifier"] = identifier;
    if (password != null) data["password"] = password;
    if (countryCode != null) data["country_code"] = countryCode;

    if (gender != null) data["gender"] = gender;
    return data;
  }
}
