class CreateStoryRequest {
  final String caption;
  final String file; // file path OR file url

  CreateStoryRequest({required this.caption, required this.file});
  Map<String, dynamic> toJson() {
    print("📤 Sending Create Story Request:");
    print("👉 Caption: $caption");
    print("👉 File: $file");

    final data = {"caption": caption, "file": file};

    print("👉 Final JSON: $data");

    return data;
  }
}
