import 'package:dio/dio.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/features/auth/data/services/token_storage.dart';

class FollowRequestModel {
  final String userId;
  final String username;
  final String fullName;
  final String? profilePicture;
  final DateTime requestedAt;

  const FollowRequestModel({
    required this.userId,
    required this.username,
    required this.fullName,
    this.profilePicture,
    required this.requestedAt,
  });

  factory FollowRequestModel.fromJson(Map<String, dynamic> json) {
    return FollowRequestModel(
      userId: json['user_id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      profilePicture: json['profile_picture']?.toString(),
      requestedAt:
          DateTime.tryParse(json['requested_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class FollowRequestService {
  FollowRequestService() : _dio = AppDio.getInstance();
  final Dio _dio;

  Future<Options> _authOptions() async {
    final token = await TokenStorage.getAccessToken();
    return Options(
      headers: {'Authorization': 'Bearer $token'},
      extra: {'skipCache': true},
    );
  }

  Future<List<FollowRequestModel>> fetchRequests({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      ApiConstants.followRequests,
      queryParameters: {'page': page, 'limit': limit},
      options: await _authOptions(),
    );
    final data = response.data['data'] as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? [];
    return results
        .map((e) => FollowRequestModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// [action] is "accept" or "reject"
  Future<void> respondToRequest(String userId, String action) async {
    await _dio.post(
      ApiConstants.followRequestsRespond,
      data: {'user_id': userId, 'action': action},
      options: await _authOptions(),
    );
  }
}
