class ReportUserResponseModel {
  final int code;
  final bool success;
  final String message;
  final ReportUserData? data;
  final String? error;

  ReportUserResponseModel({
    required this.code,
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory ReportUserResponseModel.fromJson(Map<String, dynamic> json) {
    return ReportUserResponseModel(
      code: json['code'] is int
          ? json['code'] as int
          : int.tryParse(json['code']?.toString() ?? '') ?? 0,
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'] is Map<String, dynamic>
          ? ReportUserData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      error: json['error']?.toString(),
    );
  }
}

class ReportUserData {
  final String reportId;
  final String userId;
  final String reasonKey;

  ReportUserData({
    required this.reportId,
    required this.userId,
    required this.reasonKey,
  });

  factory ReportUserData.fromJson(Map<String, dynamic> json) {
    return ReportUserData(
      reportId: json['report_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      reasonKey: json['reason_key']?.toString() ?? '',
    );
  }
}
