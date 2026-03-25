class CompleteProfileRequest {
  final String username;

  CompleteProfileRequest({required this.username});

  Map<String, dynamic> toJson() {
    return {"username": username};
  }
}
