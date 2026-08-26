class BlockToggleResponseModel {
  final bool success;
  final String message;
  final BlockToggleData? data;

  BlockToggleResponseModel({
    required this.success,
    required this.message,
    this.data,
  });

  factory BlockToggleResponseModel.fromJson(Map<String, dynamic> json) {
    return BlockToggleResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? BlockToggleData.fromJson(json['data']) : null,
    );
  }
}

class BlockToggleData {
  final bool isBlocked;

  BlockToggleData({required this.isBlocked});

  factory BlockToggleData.fromJson(Map<String, dynamic> json) {
    return BlockToggleData(
      isBlocked: json['is_blocked'] ?? false,
    );
  }
}
