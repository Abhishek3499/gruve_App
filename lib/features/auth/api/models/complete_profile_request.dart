class CompleteProfileRequest {
  final String username;
  final String? file;

  CompleteProfileRequest({required this.username, this.file});

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{"username": username};

    if (file?.isNotEmpty == true) {
      data["file"] = file;
    }

    return data;
  }
}
