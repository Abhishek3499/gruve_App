import 'package:dio/dio.dart';

/// Extracts a user-facing message from a failed share/upload error.
String? parseShareUploadError(Object e) {
  if (e is DioException) {
    final resData = e.response?.data;
    if (resData != null && resData is Map) {
      return resData['message']?.toString() ?? resData['error']?.toString();
    } else if (resData != null && resData is String) {
      return resData;
    } else if (e.response?.statusMessage != null) {
      return "Server error: ${e.response?.statusCode} ${e.response?.statusMessage}";
    } else {
      return e.message;
    }
  }
  return e.toString();
}
